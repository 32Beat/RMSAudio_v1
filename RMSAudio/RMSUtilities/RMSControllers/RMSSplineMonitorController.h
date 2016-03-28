////////////////////////////////////////////////////////////////////////////////
/*
	RMSSplineMonitorController
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSampleMonitor.h"
#import "RMSSplineMonitor.h"
#import "RMSSplineMonitorView.h"

@interface RMSSplineMonitorController : NSObject
<RMSSampleMonitorObserverProtocol>

- (void) reset;
- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

@property (nonatomic) IBOutlet RMSSplineMonitorView *view;
@property (nonatomic) IBOutlet NSTextField *label;

@end
