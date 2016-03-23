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
/*
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
*/
////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	// (re)initialize engines if necessary
	Float64 sampleRate = sampleMonitor.sampleRate;
	if (mEngineRate != sampleRate)
	{
		mEngineRate = sampleRate;
		mEngineL = RMSEngineInit(sampleRate);
		mEngineR = RMSEngineInit(sampleRate);
	}

	rmsbuffer_t *bufferL = [sampleMonitor bufferAtIndex:0];
	rmsbuffer_t *bufferR = [sampleMonitor bufferAtIndex:1];

	NSRange R = [sampleMonitor availableRangeWithIndex:mIndex];
	NSUInteger index = R.location;
	NSUInteger count = R.length;
	
	for (NSUInteger n=count; n!=0; n--)
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
