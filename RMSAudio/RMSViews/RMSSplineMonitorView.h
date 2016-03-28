//
//  RMSSplineMonitorView.h
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSampleMonitorView.h"

@interface RMSSplineMonitorView : NSView
<RMSSampleMonitorObserverProtocol>

- (void) reset;
- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

@property (nonatomic) NSBezierPath *resultPath;
@property (nonatomic) NSBezierPath *deltaPath;
@property (nonatomic, assign) double optimum;

@property (nonatomic) IBOutlet NSTextField *label;

@end
