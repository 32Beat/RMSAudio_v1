////////////////////////////////////////////////////////////////////////////////
/*
	RMSSampleMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSSource.h"

/*
	RMSSampleMonitor is a simple ringbuffer monitor which can be used by 
	multiple observers to display information about the latest samples. 
	This significantly reduces the strain on the real-time audio thread.
	
	The length count of the RMSSampleMonitor should obviously be appropriate 
	for the largest possible demand. 
*/

@interface RMSSampleMonitor : RMSSource

+ (instancetype) instanceWithCount:(size_t)sampleCount;
- (instancetype) initWithCount:(size_t)sampleCount;

- (uint64_t) maxIndex;
- (uint64_t) maxCount;

- (BOOL) getSamples:(float **)dstPtr count:(size_t)count;
- (BOOL) getSamples:(float **)dstPtr withRange:(NSRange)R;
- (void) getSamplesL:(float *)dstPtr withRange:(NSRange)R;
- (void) getSamplesR:(float *)dstPtr withRange:(NSRange)R;

@end
