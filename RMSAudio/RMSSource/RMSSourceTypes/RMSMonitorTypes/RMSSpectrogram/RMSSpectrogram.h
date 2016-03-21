////////////////////////////////////////////////////////////////////////////////
/*
	RMSSpectrogram
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSampleMonitor.h"
#import "RMSClip.h"

/*
	RMSSampleMonitor is a simple ringbuffer monitor which can be used by 
	multiple observers to display information about the latest samples. 
	This significantly reduces the strain on the real-time audio thread.
	
	The length count of the RMSSampleMonitor should obviously be appropriate 
	for the largest demand.
*/

@interface RMSSpectrogram : NSObject

@property (atomic) RMSSampleMonitor *sampleMonitor;

+ (instancetype) instanceWithSize:(size_t)N sampleMonitor:(RMSSampleMonitor *)sampleMonitor;
- (instancetype) initWithSize:(size_t)N sampleMonitor:(RMSSampleMonitor *)sampleMonitor;

- (size_t) size;
- (BOOL) setSize:(size_t)N;

- (NSBitmapImageRep *) spectrumImageWithGain:(size_t)a;

+ (RMSClip *) computeSampleBufferUsingImage:(NSImage *)image;

@end
