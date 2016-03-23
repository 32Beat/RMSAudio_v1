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

#define kRMSSplineMonitorCount 	2048
#define kRMSSplineErrorCount 	32

@interface RMSSplineMonitorView ()
{
}

@property (nonatomic) NSBezierPath *errorPath;
@property (nonatomic, assign) double minError;

@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSSplineMonitorView
////////////////////////////////////////////////////////////////////////////////

- (void) updateData:(RMSSplineMonitor *)splineMonitor
{
	size_t N = kRMSSplineErrorCount;

	const double *errorPtr = splineMonitor.errorPtr;
	
	double minE = 0.0;
	double maxE = 0.0;
	vDSP_minvD(errorPtr, 1, &minE, N);
	vDSP_maxvD(errorPtr, 1, &maxE, N);
	
	if (maxE == 0.0)
	{ return; }
	
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:(NSPoint){ 0.0, errorPtr[0]/maxE }];
	for (int n=1; n!=N; n++)
	{
		CGFloat x = 1.0 * n / (N-1);
		[path lineToPoint:(NSPoint){ x, errorPtr[n]/maxE }];
	}
	
	self.errorPath = path;

	self.minError = splineMonitor.minResult;

	[self setNeedsDisplay:YES];
}

////////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
	
	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);
	
	[self drawGraph:NSInsetRect(self.bounds, 1, 1)];
	
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}



- (void) drawGraph:(NSRect)B
{
	if (self.errorPath != nil)
	{
		[[NSColor grayColor] set];

		NSAffineTransform *T = [NSAffineTransform new];
		[T translateXBy:B.origin.x yBy:B.origin.y];
		[T scaleXBy:B.size.width yBy:B.size.height];

		[[T transformBezierPath:self.errorPath] stroke];
	}

	[[NSColor redColor] set];
	float X1 = NSMinX(B)+floor(B.size.width * self.minError)+.5;
	float X2 = X1;
	float Y1 = NSMinY(B);
	float Y2 = NSMaxY(B);
	[NSBezierPath strokeLineFromPoint:(NSPoint){ X1, Y1 }
							  toPoint:(NSPoint){ X2, Y2 }];
}


@end
