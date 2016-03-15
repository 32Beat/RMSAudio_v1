//
//  RMSSplineMonitorView.h
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSplineMonitor.h"

@interface RMSSplineMonitorView : NSView

@property (nonatomic) RMSSplineMonitor *splineMonitor;

- (double) triggerUpdate;
//- (void) setImageRep:(NSImageRep *)imageRep;

@end
