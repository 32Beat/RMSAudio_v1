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

- (void) reset
{ mReset = YES; }

////////////////////////////////////////////////////////////////////////////////

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
	size_t N = mSplineMonitor.errorCount;
	if (mErrorPath == nil || mErrorPath.elementCount != N)
	{ mErrorPath = [self bezierPathWithPointCount:N]; }
	
	for (int n=0; n!=N; n++)
	{
		NSPoint P = { (CGFloat)n/(N-1),
		[mSplineMonitor errorAtIndex:n] };
		[mErrorPath setAssociatedPoints:&P atIndex:n];
	}

	// transfer from background to main
	NSBezierPath *path = mErrorPath;
	// optimum x location for minimum error
	double optimum = mSplineMonitor.optimum;
	NSString *text = [NSString stringWithFormat:@"%.3f", optimum];

	// update UI on main
	dispatch_async(dispatch_get_main_queue(),
	^{
		self.resultPath = path;
		self.optimum = optimum;
		[self setNeedsDisplay:YES];

		self.label.stringValue = text;
	});
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
