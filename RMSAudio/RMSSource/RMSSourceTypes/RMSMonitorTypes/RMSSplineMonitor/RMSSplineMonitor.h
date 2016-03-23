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

- (void) resetEngine;
- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

- (const double *) errorPtr;
- (double) minResult;

//- (NSBitmapImageRep *) imageRepWithGain:(UInt32)a;

@end
