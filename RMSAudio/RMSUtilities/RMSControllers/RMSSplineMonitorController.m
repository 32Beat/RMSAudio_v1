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
	
	// 3. transfer latest results to GUI
	NSBezierPath *path = [mMonitor createErrorPath];
	double optimum = mMonitor.optimum;
	NSString *labelText = [NSString stringWithFormat:@"%.3f", optimum];
	
	dispatch_async(dispatch_get_main_queue(),
	^{
		self.view.errorPath = path;
		self.view.optimum = optimum;
		[self.view setNeedsDisplay:YES];
		
		self.label.stringValue = labelText;
	});
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



