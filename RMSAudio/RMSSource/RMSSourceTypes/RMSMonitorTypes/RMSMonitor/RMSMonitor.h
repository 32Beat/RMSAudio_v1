////////////////////////////////////////////////////////////////////////////////
/*
	RMSMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"
#import "RMSSampleMonitor.h"
#import "rmslevels.h"

@interface RMSMonitor : NSObject <RMSSampleMonitorObserverProtocol>

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

- (const rmsengine_t *) enginePtrL;
- (const rmsengine_t *) enginePtrR;

- (rmsresult_t) resultLevelsL;
- (rmsresult_t) resultLevelsR;
- (double) resultBalance;

@end
