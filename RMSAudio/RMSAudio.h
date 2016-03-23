//
//  RMSAudio.h
//  RMSAudio
//
//  Created by 32BT on 10/RMS03/RMS16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//! Project version number for RMSAudio.
FOUNDATION_EXPORT double RMSAudioVersionNumber;

//! Project version string for RMSAudio.
FOUNDATION_EXPORT const unsigned char RMSAudioVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <RMSAudio/RMSPublicHeader.h>


#import <RMSAudio/RMSLink.h>
#import <RMSAudio/RMSCallback.h>
#import <RMSAudio/RMSSource.h>

#import <RMSAudio/RMSAudioUnit.h>
#import <RMSAudio/RMSAudioUnitFilePlayer.h>
#import <RMSAudio/RMSAudioUnitVarispeed.h>
#import <RMSAudio/RMSAudioUnitPlatformIO.h>
#import <RMSAudio/RMSInput.h>
#import <RMSAudio/RMSOutput.h>

#import <RMSAudio/RMSVolume.h>
#import <RMSAudio/RMSAutoPan.h>
#import <RMSAudio/RMSLowPassFilter.h>
#import <RMSAudio/RMSMoogFilter.h>
#import <RMSAudio/RMSDelay.h>
#import <RMSAudio/RMSPhaser.h>
#import <RMSAudio/RMSFlanger.h>

#import <RMSAudio/RMSMonitor.h>
#import <RMSAudio/RMSSampleMonitor.h>
#import <RMSAudio/RMSSplineMonitor.h>
#import <RMSAudio/RMSPhaseMonitor.h>
#import <RMSAudio/RMSSpectrogram.h>

#import <RMSAudio/RMSSplineMonitorView.h>
#import <RMSAudio/RMSLissajousView.h>
#import <RMSAudio/RMSSpectrumView.h>

#import <RMSAudio/RMSMixer.h>
#import <RMSAudio/RMSMixerSource.h>

#import <RMSAudio/RMSTestSignal.h>
#import <RMSAudio/RMSClip.h>

#import <RMSAudio/RMSTimer.h>
#import <RMSAudio/RMSIndexView.h>
#import <RMSAudio/RMSStereoView.h>
#import <RMSAudio/RMSBalanceView.h>


CF_ENUM(AudioFormatFlags)
{
	kAudioFormatFlagIsNativeEndian = kAudioFormatFlagsNativeEndian
};

static const AudioStreamBasicDescription RMSPreferredAudioFormat =
{
	.mSampleRate 		= 0.0,
	.mFormatID 			= kAudioFormatLinearPCM,
	.mFormatFlags 		=
		kAudioFormatFlagIsFloat | \
		kAudioFormatFlagIsNativeEndian | \
		kAudioFormatFlagIsPacked | \
		kAudioFormatFlagIsNonInterleaved,
	.mBytesPerPacket 	= sizeof(float),
	.mFramesPerPacket 	= 1,
	.mBytesPerFrame 	= sizeof(float),
	.mChannelsPerFrame 	= 2,
	.mBitsPerChannel 	= sizeof(float) * 8,
	.mReserved 			= 0
};


