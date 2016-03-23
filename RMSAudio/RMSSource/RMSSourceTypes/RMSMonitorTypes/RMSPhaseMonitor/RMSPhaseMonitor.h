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

@property (nonatomic, assign) float correlation;
@property (nonatomic, assign) float correlationL;
@property (nonatomic, assign) float correlationR;

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

- (NSBezierPath *) resultPath;


@end
