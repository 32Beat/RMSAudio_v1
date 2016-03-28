////////////////////////////////////////////////////////////////////////////////
/*
	RMSSplineMonitorController
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSplineMonitorController.h"
#import <Accelerate/Accelerate.h>


@interface RMSSplineMonitorController ()
{
	BOOL mReset;
	
	RMSSplineMonitor *mMonitor;
	NSBezierPath *mResultPath;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSplineMonitorController
////////////////////////////////////////////////////////////////////////////////

- (void) reset
{ mReset = YES; }

////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	// 1. adjust monitor for latest parameters
	if (mMonitor == nil || mReset)
	{
		mMonitor = [RMSSplineMonitor new];
		mReset = NO;
	}
	
	// 2. update monitor
	[mMonitor updateWithSampleMonitor:sampleMonitor];
	
	// recreate or update resultPath accordingly
	size_t N = mMonitor.errorCount;

	if ((mResultPath == nil) || (mResultPath.elementCount != N))
	{ mResultPath = [self bezierPathWithPointCount:N]; }

	for (int n=0; n!=N; n++)
	{
		NSPoint P = { (CGFloat)n/(N-1),
		[mMonitor errorAtIndex:n] };
		[mResultPath setAssociatedPoints:&P atIndex:n];
	}

	// transfer result to UI
	NSBezierPath *path = mResultPath;
	double optimum = mMonitor.optimum;
	NSString *text = [NSString stringWithFormat:@"%.3f", optimum];
	
	dispatch_async(dispatch_get_main_queue(),
	^{
		self.label.stringValue = text;
		self.view.resultPath = path;
		self.view.optimum = optimum;
		[self.view setNeedsDisplay:YES];		
	});
}

////////////////////////////////////////////////////////////////////////////////

- (NSBezierPath *) bezierPathWithPointCount:(int)N
{
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:CGPointZero];
	for (int n=0; n!=N; n++)
	{
		NSPoint P = { (CGFloat)n/(N-1), 0.0 };
		[path lineToPoint:P];
	}

	return path;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



