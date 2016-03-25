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
	This is being called from a concurrent backgroundthread
	Modelobject management is contained within this call.
*/
- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	// 1. ensure parameters are valid
	if (mLength == 0)
	{ mLength = 2048; }
	
	// 2. initialize or recreate model object if necessary
	if (mSpectrogram.length != mLength)
	{ mSpectrogram = [RMSSpectrogram instanceWithLength:mLength]; }
	
	// 3. create representation
	NSBitmapImageRep *imagePtr =
	[mSpectrogram spectrumImageWithSampleMonitor:sampleMonitor gain:mGain];
	
	// 4. transfer to view on main
	dispatch_async(dispatch_get_main_queue(),
	^{ [self appendImageRep:imagePtr]; });
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
	
	[self setNeedsDisplay:YES];
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

- (BOOL) isOpaque
{ return YES; }

// Q&D moving spectrum
- (void)drawRect:(NSRect)dirtyRect
{
	UInt32 n = 0;
	NSRect B = self.bounds;
	
	while ((n < mImageArray.count)&&(B.size.height > 0.0))
	{
		NSImageRep *imageRep = [mImageArray objectAtIndex:n];
		
		B.size.height -= imageRep.size.height;

		NSRect dstR = B;
		dstR.origin.y += dstR.size.height;
		dstR.size.height = imageRep.size.height;
		[imageRep drawInRect:dstR];

		n += 1;
	}
	
	if (B.size.height > 0.0)
	{
		[[NSColor blackColor] set];
		NSRectFill(B);
	}
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
