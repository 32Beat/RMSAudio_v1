//
//  RMSSplineMonitorView.m
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSplineMonitorView.h"

@interface RMSSplineMonitorView ()
{
	double mE[kRMSSplineMonitorCount];
	double mMinValue;
	
	NSImageRep *mImageRep;
}
@end

@implementation RMSSplineMonitorView

- (void) setSplineMonitor:(RMSSplineMonitor *)splineMonitor
{
	if (_splineMonitor != splineMonitor)
	{
		_splineMonitor = splineMonitor;
		[self triggerUpdate];
	}
}

- (double) triggerUpdate
{
	if (self.splineMonitor != nil)
	{
		[self.splineMonitor getErrorData:mE minValue:&mMinValue];
		[self setNeedsDisplay:YES];
		return mMinValue;
	}
	
	return 0.5;
}

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
	[[NSColor grayColor] set];

	NSBezierPath *path = [NSBezierPath new];
	
	float x = NSMinX(B);
	float xstep = B.size.width / (kRMSSplineMonitorCount-1);
	[path moveToPoint:(NSPoint){ x, mE[0]*B.size.height }];
	for (long n=1; n!=kRMSSplineMonitorCount; n++)
	{
		x += xstep;
		[path lineToPoint:(NSPoint){ x, mE[n]*B.size.height }];
	}
	[path stroke];

	[[NSColor redColor] set];
	[path removeAllPoints];
	float X1 = NSMinX(B)+floor(B.size.width * mMinValue)+.5;
	float X2 = X1;
	float Y1 = NSMinY(B);
	float Y2 = NSMaxY(B);
	[path moveToPoint:(NSPoint){ X1, Y1 }];
	[path lineToPoint:(NSPoint){ X2, Y2 }];
	[path stroke];
	
}


@end
