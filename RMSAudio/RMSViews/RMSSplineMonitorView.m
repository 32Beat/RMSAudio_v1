//
//  RMSSplineMonitorView.m
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSplineMonitorView.h"
#import "RMSSampleMonitor.h"
#import "RMSSplineMonitor.h"
#import <Accelerate/Accelerate.h>


@interface RMSSplineMonitorView ()
{
	BOOL mReset;
	RMSSplineMonitor *mSplineMonitor;
	NSBezierPath *mErrorPath;
}

@property (nonatomic) NSBezierPath *linePath;
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSSplineMonitorView
////////////////////////////////////////////////////////////////////////////////
/*
	This is called on main in response to user interaction.
	We will just set a flag for the background process to update accordingly.

	This probably is the suggested approach for all parameter changes.

	1. set the parameters
	2. let the background process compare the modelstate vs the parameters and
	update the model if necessary
	3. copy model results to the mainthread for displaying

	This seems slightly easier to implement in a separate controller object
*/

- (void) reset
{ mReset = YES; }

////////////////////////////////////////////////////////////////////////////////
/*	
	updateWithSampleMonitor
	-----------------------
	This is called from a concurrent background thread (not the audiothread).
	The audiothread may be updating the ringbuffers in the sampleMonitor 
	but the latest simultaneous index for left & right is available thru
	
	sampleMonitor->maxIndex
	
	Given a long enough ringbuffer, there should be ample headroom to traverse
	the most recent samples up to maxIndex.
	
	In this case we merely operate on the latest 2048 samples which more or less
	corresponds with the update frequency @ 44.1kHz
*/

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	// recreate modelobject if necessary
	if (mSplineMonitor == nil || mReset)
	{
		mSplineMonitor = [RMSSplineMonitor new];
		mReset = NO;
	}
	
	// update model with latest ringbuffer samples
	[mSplineMonitor updateWithSampleMonitor:sampleMonitor];

	// recreate or update resultPath accordingly
	NSBezierPath *path = [self updateErrorPath];
	
	// optimum x location for minimum error
	double optimum = mSplineMonitor.optimum;
	
	// show optimum as label text
	NSString *text = [NSString stringWithFormat:@"%.3f", optimum];

	// transfer to UI on main
	dispatch_async(dispatch_get_main_queue(),
	^{
		self.resultPath = path;
		self.optimum = optimum;
		[self setNeedsDisplay:YES];

		self.label.stringValue = text;
	});
}

////////////////////////////////////////////////////////////////////////////////
/*
	The splineMonitor stores errors over errorCount bins. 
	Here we create a bezierpath once with errorCount points,
	and update the points on each iteration. 
	
	The path ptr is then copied to a block for processing on main.
	This means that the mErrorPath ptr can be reset in the background 
	if necessary. Updating the points while the path is being drawn, 
	is harmless with regards to threadingissues.
*/
- (NSBezierPath *) updateErrorPath
{
	size_t N = mSplineMonitor.errorCount;
	
	if (mErrorPath == nil || mErrorPath.elementCount != N)
	{ mErrorPath = [self bezierPathWithPointCount:N]; }
	
	for (int n=0; n!=N; n++)
	{
		NSPoint P = { (CGFloat)n/(N-1),
		[mSplineMonitor errorAtIndex:n] };
		[mErrorPath setAssociatedPoints:&P atIndex:n];
	}
	
	return mErrorPath;
}

////////////////////////////////////////////////////////////////////////////////

- (NSBezierPath *) bezierPathWithPointCount:(int)N
{
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:CGPointZero];
	for (int n=1; n!=N; n++)
	{
		NSPoint P = { (CGFloat)n/(N-1), 0.0 };
		[path lineToPoint:P];
	}
	
	return path;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (BOOL) isOpaque
{ return YES; }

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);
	
	[self drawGraph:NSInsetRect(self.bounds, 1, 1)];
//	[self drawBarGraph:NSInsetRect(self.bounds, 1, 1)];
	
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawBarGraph:(NSRect)B
{
	double *resultPtr = nil;
	
	if (resultPtr != nil)
	{
		size_t N = 32;
		
		CGFloat H = B.size.height;
		CGFloat W = B.size.width / N;
		
		B.origin.x += 0.05 * W;
		B.size.width = 0.90 * W;
		
		[[NSColor darkGrayColor] set];
		for (int n=0; n!=N; n++)
		{
			B.size.height = ceil(H * resultPtr[n]);
			NSRectFill(B);
			B.origin.x += W;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawGraph:(NSRect)B
{
	if (self.resultPath != nil)
	{
		[[NSColor grayColor] set];

		NSAffineTransform *T = [NSAffineTransform new];
		[T translateXBy:B.origin.x yBy:B.origin.y];
		[T scaleXBy:B.size.width yBy:B.size.height];

		[[T transformBezierPath:self.resultPath] stroke];

		[[NSColor redColor] set];
		[[T transformBezierPath:self.linePath] stroke];
		
	}

	[[NSColor redColor] set];
//*
{
	float X1 = NSMinX(B)+floor(B.size.width * self.optimum)+.5;
	float X2 = X1;
	float Y1 = NSMinY(B);
	float Y2 = NSMaxY(B);
	[NSBezierPath strokeLineFromPoint:(NSPoint){ X1, Y1 }
							  toPoint:(NSPoint){ X2, Y2 }];
}
//*/

}


@end
