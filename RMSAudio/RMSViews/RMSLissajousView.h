//
//  RMSLissajousView.h
//  RMSAudioApp
//
//  Created by 32BT on 07/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSampleMonitorView.h"
#import "RMSPhaseMonitor.h"


#define kRMSLissajousCount 	(1<<12)


@interface RMSLissajousView : RMSSampleMonitorView
<RMSSampleMonitorObserverProtocol>
- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

@property (nonatomic, assign) float correlation;
@property (nonatomic, assign) float correlationL;
@property (nonatomic, assign) float correlationR;

@property (nonatomic) IBOutlet NSTextField *label;


- (void) setFilter:(float)value;
- (void) setDuration:(float)value;

- (void) updateData:(RMSPhaseMonitor *)phaseMonitor;

@end
