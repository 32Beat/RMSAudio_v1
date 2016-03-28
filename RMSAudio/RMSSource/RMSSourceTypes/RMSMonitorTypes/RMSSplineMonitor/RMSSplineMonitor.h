////////////////////////////////////////////////////////////////////////////////
/*
	RMSSplineMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSSampleMonitor.h"




@interface RMSSplineMonitor : NSObject
<RMSSampleMonitorObserverProtocol>

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

- (size_t) errorCount;
- (double) errorAtIndex:(int)n;
- (double) optimum;

@end
