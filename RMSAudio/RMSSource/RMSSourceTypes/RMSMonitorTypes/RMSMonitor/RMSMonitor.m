////////////////////////////////////////////////////////////////////////////////
/*
	RMSMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSMonitor.h"


@interface RMSMonitor ()
{
	uint64_t mIndex;
	
	Float64 mEngineRate;
	rmsengine_t mEngineL;
	rmsengine_t mEngineR;
}

@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSMonitor
////////////////////////////////////////////////////////////////////////////////

static OSStatus renderCallback(
	void 							*inRefCon,
	AudioUnitRenderActionFlags 		*actionFlags,
	const AudioTimeStamp 			*timeStamp,
	UInt32							busNumber,
	UInt32							frameCount,
	AudioBufferList 				*bufferList)
{
	__unsafe_unretained RMSMonitor *rmsObject = \
	(__bridge __unsafe_unretained RMSMonitor *)inRefCon;
	
	// (re)initialize engines if necessary
	Float64 sampleRate = rmsObject->mSampleRate;
	if (rmsObject->mEngineRate != sampleRate)
	{
		rmsObject->mEngineRate = sampleRate;
		rmsObject->mEngineL = RMSEngineInit(sampleRate);
		rmsObject->mEngineR = RMSEngineInit(sampleRate);
	}

	// Process first output buffer through left engine
	if (bufferList->mNumberBuffers > 0)
	{
		Float32 *srcPtr = bufferList->mBuffers[0].mData;
		RMSEngineAddSamples32(&rmsObject->mEngineL, srcPtr, frameCount);
	}
	
	// Process second output buffer through right engine
	if (bufferList->mNumberBuffers > 1)
	{
		Float32 *srcPtr = bufferList->mBuffers[1].mData;
		RMSEngineAddSamples32(&rmsObject->mEngineR, srcPtr, frameCount);
	}
	
	return noErr;
}

////////////////////////////////////////////////////////////////////////////////

+ (const RMSCallbackProcPtr) callbackPtr
{ return renderCallback; }

////////////////////////////////////////////////////////////////////////////////

+ (instancetype) instanceWithSampleRate:(Float64)sampleRate
{ return [[self alloc] initWithSampleRate:sampleRate]; }

- (instancetype) initWithSampleRate:(Float64)sampleRate
{
	self = [super init];
	if (self != nil)
	{
		[self setSampleRate:sampleRate];
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) processSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	// (re)initialize engines if necessary
	Float64 sampleRate = self.sampleRate;
	if (mEngineRate != sampleRate)
	{
		mEngineRate = sampleRate;
		mEngineL = RMSEngineInit(sampleRate);
		mEngineR = RMSEngineInit(sampleRate);
	}


	uint64_t index = mIndex;
	uint64_t maxIndex = sampleMonitor.maxIndex;
	
	if (index > maxIndex)
	{ index = maxIndex; }
	
	uint64_t count = maxIndex+1 - index;
	uint64_t maxCount = sampleMonitor.length >> 1;
	
	if (count > maxCount)
	{
		count = maxCount;
		index = maxIndex - count;
	}

	rmsbuffer_t *bufferL = [sampleMonitor bufferAtIndex:0];
	rmsbuffer_t *bufferR = [sampleMonitor bufferAtIndex:1];

	for (int n=0; n!=count; n++)
	{
		float L = RMSBufferGetSampleAtIndex(bufferL, index);
		RMSEngineAddSample(&mEngineL, L);
		float R = RMSBufferGetSampleAtIndex(bufferR, index);
		RMSEngineAddSample(&mEngineR, R);
		index++;
	}
	
	mIndex = index;
}

////////////////////////////////////////////////////////////////////////////////

- (const rmsengine_t *) enginePtrL
{ return &mEngineL; }

- (const rmsengine_t *) enginePtrR
{ return &mEngineR; }

- (rmsresult_t) resultLevelsL
{ return RMSEngineFetchResult(&mEngineL); }

- (rmsresult_t) resultLevelsR;
{ return RMSEngineFetchResult(&mEngineR); }

- (double) resultBalance
{ return mEngineR.mBal - mEngineL.mBal; }

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
