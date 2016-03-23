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

+ (instancetype) instanceWithLength:(size_t)N;
- (instancetype) initWithLength:(size_t)N;
- (size_t)length;

- (NSBitmapImageRep *) spectrumImageWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor gain:(int)gain;

+ (RMSClip *) computeSampleBufferUsingImage:(NSImage *)image;

@end
