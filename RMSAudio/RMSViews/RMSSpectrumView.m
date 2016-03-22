//
//  RMSSpectrumView.m
//  RMSAudio
//
//  Created by 32BT on 20/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSpectrumView.h"
#import <Accelerate/Accelerate.h>

@interface RMSSpectrumView ()
{
	size_t mGain;
	size_t mLength;

	RMSSpectrogram *mSpectrogram;
	
	NSMutableArray *mImageArray;
}

@property (nonatomic) NSBitmapImageRep *imagePtr;

@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSpectrumView
////////////////////////////////////////////////////////////////////////////////

- (void) setGain:(UInt32)gain
{ mGain = gain; }

////////////////////////////////////////////////////////////////////////////////

- (void) setLength:(UInt32)N
{ mLength = 1<<(int)(ceil(log2(N))); }

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////
/*
	Following three calls are guaranteed to run consecutively & non-concurrently 
	willUpdateWith... will be run on main
	updateWith... will be run in background
	didUpdateWith... will be run on main.
	
*/
- (void) willUpdateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	if (mLength == 0)
	{ mLength = 2048; }
	
	if (mSpectrogram.size != mLength)
	{
		mSpectrogram = [RMSSpectrogram instanceWithSize:mLength
		sampleMonitor:sampleMonitor];
		mLength = mSpectrogram.size;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	self.imagePtr = [mSpectrogram spectrumImageWithGain:mGain];
}

////////////////////////////////////////////////////////////////////////////////

- (void) didUpdateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	[self appendImageRep:self.imagePtr];
	self.imagePtr = nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (void) appendImageRep:(NSImageRep *)imageRep
{
	if (mImageArray == nil)
	{ mImageArray = [NSMutableArray new]; }
	
	if (imageRep != nil)
	{
		[mImageArray insertObject:imageRep atIndex:0];
		[self updateArrayForSize:self.bounds.size];
	}
	
	//[self setNeedsDisplay:YES];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateArrayForSize:(NSSize)size
{
	NSInteger n = 0;
	CGFloat H = 0.0;
	
	while ((n < mImageArray.count) && (H < size.height))
	{
		NSImageRep *imageRep = [mImageArray objectAtIndex:n];
		H += imageRep.size.height;
		n += 1;
	}

	while (mImageArray.count > n)
	{ [mImageArray removeLastObject]; }
}

////////////////////////////////////////////////////////////////////////////////

// Q&D moving spectrum
- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	[[NSColor blackColor] set];
	NSRectFill(self.bounds);
	
	NSRect dstR = self.bounds;
	CGFloat maxY = NSMaxY(dstR);
	CGFloat minY = NSMinY(dstR);
	dstR.origin.y = maxY;
	
	UInt32 n = 0;

	while ((n < mImageArray.count)&&(dstR.origin.y > minY))
	{
		NSImageRep *imageRep = [mImageArray objectAtIndex:n];
		
		dstR.size.height = imageRep.size.height;
		dstR.origin.y -= dstR.size.height;
		
		[imageRep drawInRect:dstR];

		n += 1;
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
