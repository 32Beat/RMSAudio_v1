//
//  RMSSampleMonitorView.h
//  RMSAudio
//
//  Created by 32BT on 20/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSampleMonitor.h"

@interface RMSSampleMonitorView : NSView

@property (atomic, weak) RMSSampleMonitor *sampleMonitor;

- (void) triggerUpdate;
- (void) triggerUpdateWithFinishBlock:(void (^)(void))blockPtr;

@end
