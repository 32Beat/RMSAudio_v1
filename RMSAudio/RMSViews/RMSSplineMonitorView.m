//
//  RMSSplineMonitorView.m
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSplineMonitorView.h"
#import "RMSSampleMonitor.h"
#import <Accelerate/Accelerate.h>


@interface RMSSplineMonitorView ()
{
	BOOL mReset;
	RMSSplineMonitor *mSplineMonitor;
}

@property (atomic) NSBezierPath *linePath;

@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSSplineMonitorView
////////////////////////////////////////////////////////////////////////////////

- (void) reset
{ mReset = YES; }

////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	if (mSplineMonitor == nil || mReset)
	{ mSplineMonitor = [RMSSplineMonitor new]; mReset = NO; }
	
	[mSplineMonitor updateWithSampleMonitor:sampleMonitor];

	self.optimum = mSplineMonitor.optimum;

	NSBezierPath *path = [mSplineMonitor createErrorPath];

	dispatch_async(dispatch_get_main_queue(),
	^{
		self.errorPath = path;
		[self setNeedsDisplay:YES];
	});
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
	
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawGraph:(NSRect)B
{
	if (self.errorPath != nil)
	{
		[[NSColor grayColor] set];

		NSAffineTransform *T = [NSAffineTransform new];
		[T translateXBy:B.origin.x yBy:B.origin.y];
		[T scaleXBy:B.size.width yBy:B.size.height];

		[[T transformBezierPath:self.errorPath] stroke];

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
/*
	float X1 = NSMinX(B)+0.333*B.size.width;
	float Y1 = NSMinY(B)+self.avg1*B.size.height;
	float X2 = NSMinX(B)+0.667*B.size.width;
	float Y2 = NSMinY(B)+self.avg2*B.size.height;
*/
/*
	float y1 = self.avg1;
	float y2 = self.avg2;

	float X1 = NSMinX(B)+0.0*B.size.width;
	float Y1 = NSMidY(B)+y1*B.size.height;
	float X2 = NSMinX(B)+1.0*B.size.width;
	float Y2 = NSMidY(B)+y2*B.size.height;
	
	[NSBezierPath strokeLineFromPoint:(NSPoint){ X1, Y1 }
							  toPoint:(NSPoint){ X2, Y2 }];
*/


}


@end
