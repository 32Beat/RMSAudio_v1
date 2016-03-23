////////////////////////////////////////////////////////////////////////////////
/*
	RMSPhaseMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSSampleMonitor.h"




@interface RMSPhaseMonitor : NSObject
<RMSSampleMonitorObserverProtocol>

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;


@end
