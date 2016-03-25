//
//  RMSOscilloscopeView.h
//  RMSAudio
//
//  Created by 32BT on 24/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSampleMonitor.h"

@interface RMSOscilloscopeView : NSView
<RMSSampleMonitorObserverProtocol>

@property (nonatomic, assign) uint64_t gain;

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor;

@end
