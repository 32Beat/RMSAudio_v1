//
//  RMSSpectrumView.h
//  RMSAudio
//
//  Created by 32BT on 20/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RMSSampleMonitorView.h"
#import "RMSSpectrogram.h"

@interface RMSSpectrumView : RMSSampleMonitorView

- (void) setGain:(UInt32)gain;
- (void) setLength:(UInt32)length;

@end
