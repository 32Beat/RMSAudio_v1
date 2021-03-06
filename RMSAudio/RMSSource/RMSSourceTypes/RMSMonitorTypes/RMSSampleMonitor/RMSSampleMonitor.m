////////////////////////////////////////////////////////////////////////////////
/*
	RMSSampleMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSampleMonitor.h"
#import "rmsbuffer_t.h"
#import <Accelerate/Accelerate.h>


@interface RMSSampleMonitor ()
{
	size_t mCount;
	rmsbuffer_t mBufferL;
	rmsbuffer_t mBufferR;
	
	NSMutableArray *mObservers;
}

@property (nonatomic, assign) BOOL pendingUpdate;

@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSampleMonitor
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSSampleMonitor *rmsObject = \
	(__bridge __unsafe_unretained RMSSampleMonitor *)inRefCon;
	
	float *srcPtrL = bufferList->mBuffers[0].mData;
	RMSBufferWriteSamples(&rmsObject->mBufferL, srcPtrL, frameCount);

	float *srcPtrR = bufferList->mBuffers[1].mData;
	RMSBufferWriteSamples(&rmsObject->mBufferR, srcPtrR, frameCount);
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithCount:(size_t)size
{ return [[self alloc] initWithCount:size]; }

- (instancetype) init
{ return [self initWithCount:1024]; }

- (instancetype) initWithCount:(size_t)sampleCount
{
	self = [super init];
	if (self != nil)
	{
		sampleCount = 1<<(int)ceil(log2(sampleCount));
		
		mCount = sampleCount;
		mBufferL = RMSBufferBegin(sampleCount);
		mBufferR = RMSBufferBegin(sampleCount);
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	RMSBufferEnd(&mBufferL);
	RMSBufferEnd(&mBufferR);
}

////////////////////////////////////////////////////////////////////////////////

- (size_t) length
{
	return mCount;
}

////////////////////////////////////////////////////////////////////////////////

- (uint64_t) maxIndex
{
	uint64_t indexL = mBufferL.index;
	uint64_t indexR = mBufferR.index;
	return indexL < indexR ? indexL : indexR;
}

////////////////////////////////////////////////////////////////////////////////

- (NSRange) availableRange
{
	uint64_t maxIndex = self.maxIndex;
	uint64_t maxCount = self.length >> 1;
	
	return (NSRange){ maxIndex-maxCount, maxCount };
}

////////////////////////////////////////////////////////////////////////////////

- (NSRange) availableRangeWithIndex:(uint64_t)index
{
	uint64_t maxIndex = self.maxIndex;
	
	if (index == 0 || index > maxIndex)
	{ index = maxIndex; }
	
	uint64_t count = maxIndex + 1 - index;
	uint64_t maxCount = self.length >> 1;

	if (count > maxCount)
	{
		index += count;
		index -= maxCount;
		count = maxCount;
	}
	
	return (NSRange){ index, count };
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) getSamples:(float **)dstPtr count:(size_t)count
{
	uint64_t index = self.maxIndex;

	if (count > mCount)
	{ count = mCount; }
	
	NSRange R = { index - count, count };
	return [self getSamples:dstPtr withRange:R];
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) getSamples:(float **)dstPtr withRange:(NSRange)R
{
	uint64_t maxIndex = self.maxIndex;
	uint64_t minIndex = maxIndex > mCount ? maxIndex - mCount : 0;
	
	if ((minIndex <= R.location)&&((R.location+R.length) <= maxIndex))
	{
		uint64_t index = R.location;
		uint64_t count = R.length;

		RMSBufferReadSamplesFromIndex(&mBufferL, index, dstPtr[0], count);
		RMSBufferReadSamplesFromIndex(&mBufferR, index, dstPtr[1], count);

		return YES;
	}
	
	return NO;
}

////////////////////////////////////////////////////////////////////////////////

- (void) getSamplesL:(float *)dstPtr withRange:(NSRange)R
{
	uint64_t index = R.location;
	uint64_t count = R.length;
	RMSBufferReadSamplesFromIndex(&mBufferL, index, dstPtr, count);
}

////////////////////////////////////////////////////////////////////////////////

- (void) getSamplesR:(float *)dstPtr withRange:(NSRange)R
{
	uint64_t index = R.location;
	uint64_t count = R.length;
	RMSBufferReadSamplesFromIndex(&mBufferR, index, dstPtr, count);
}

////////////////////////////////////////////////////////////////////////////////

- (rmsbuffer_t *) bufferAtIndex:(int)n
{
	return n ? &mBufferR : &mBufferL;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (BOOL) validateObserver:(id<RMSSampleMonitorObserverProtocol>)observer
{
	return observer != nil &&
	[observer respondsToSelector:@selector(updateWithSampleMonitor:)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) addObserver:(id<RMSSampleMonitorObserverProtocol>)observer
{
	if (mObservers == nil)
	{ mObservers = [NSMutableArray new]; }
	
	if ([self validateObserver:observer] &&
	[mObservers indexOfObjectIdenticalTo:observer] == NSNotFound)
	{ [mObservers addObject:observer]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeObserver:(id)observer
{
	[mObservers removeObjectIdenticalTo:observer];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateObservers
{
/*
	for(id observer in mObservers)
	{
		[observer updateWithSampleMonitor:self];
		if ([self.delegate respondsToSelector:
			@selector(sampleMonitor:didUpdateObserver:)])
		{ [self.delegate sampleMonitor:self didUpdateObserver:observer]; }
	}
/*/
	[mObservers enumerateObjectsWithOptions:NSEnumerationConcurrent
	usingBlock:^(id observer, NSUInteger index, BOOL *stop)
	{
		[observer updateWithSampleMonitor:self];
		if ([self.delegate respondsToSelector:
			@selector(sampleMonitor:didUpdateObserver:)])
		{
			dispatch_async(dispatch_get_main_queue(),
			^{ [self.delegate sampleMonitor:self didUpdateObserver:observer]; });
		}
	}];
//*/
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



