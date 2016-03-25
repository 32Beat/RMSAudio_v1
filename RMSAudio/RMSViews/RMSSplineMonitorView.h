//
//  RMSSplineMonitorView.h
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSampleMonitorView.h"
#import "RMSSplineMonitor.h"

@interface RMSSplineMonitorView : NSView
<RMSSampleMonitorObserverProtocol>
- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

@property (nonatomic) NSBezierPath *errorPath;
@property (nonatomic, assign) double minError;

@end
