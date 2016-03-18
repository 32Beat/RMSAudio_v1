////////////////////////////////////////////////////////////////////////////////
/*
	RMSSpectrogram
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSpectrogram.h"
#import <Accelerate/Accelerate.h>




@interface RMSSpectrogram ()
{
	uint64_t mDCTCount;
	uint64_t mDCTShift;
	uint64_t mRowIndex;
	
	// tabulated window function
	float *mW;

	// invariants for dct conversion
	vDSP_DFT_Setup mDCTSetup;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSpectrogram
////////////////////////////////////////////////////////////////////////////////

- (instancetype) init
{ return [self initWithLength:256]; }

////////////////////////////////////////////////////////////////////////////////

- (instancetype) initWithLength:(size_t)N
{
	self = [super init];
	if (self != nil)
	{
		if ([self setLength:N])
		{
			return self;
		}
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	[self releaseInternals];
}

////////////////////////////////////////////////////////////////////////////////

- (void) releaseInternals
{
	if (mW != nil)
	{
		free(mW);
		mW = nil;
	}
	
	if (mDCTSetup != nil)
	{
		vDSP_DFT_DestroySetup(mDCTSetup);
		mDCTSetup = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) setLength:(size_t)N
{
	if (mDCTCount != N)
	{
		mDCTShift = ceil(log2(N));
		mDCTCount = 1 << mDCTShift;
		mRowIndex = 0;
		
		[self releaseInternals];

		// initialize DCT setup
		mDCTSetup = vDSP_DCT_CreateSetup(nil, mDCTCount, vDSP_DCT_IV);
		if (mDCTSetup == nil) return NO;
		
		// initialize window ptr
		mW = calloc(mDCTCount, sizeof(float));
		if (mW == nil) return NO;
		
		// populate window table
		[self prepareDCTWindow];
	}
	
	return YES;
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareDCTWindow
{
	// initialize window function
	for (int n=0; n!=mDCTCount; n++)
	{
		float x = (1.0*n + 0.5)/mDCTCount;
		float y = sin(x*M_PI);
		mW[n] = y*y;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

static inline UInt32 RGBAColorMake(UInt32 R, UInt32 G, UInt32 B)
{ return (255<<24)+(B<<16)+(G<<8)+(R<<0); }

static inline void DCT_ValueToColor(float A, float V, UInt32 *dstPtr)
{
#define CMX 255.0

	static const float colorSpectrum[][4] = {
	{ 0.0, 0.0, 0.0, CMX }, // black
	{ 0.0, 0.0, CMX, CMX }, // blue
	{ 0.0, CMX, CMX, CMX }, // cyan
	{ 0.0, CMX, 0.0, CMX }, // green
	{ CMX, CMX, 0.0, CMX }, // yellow
	{ CMX, 0.0, 0.0, CMX }, // red
	{ CMX, 0.0, CMX, CMX }, // magenta
	{ CMX, CMX, CMX, CMX }}; // white
	
	// compute spectrum power
	V = V*V;
	
	// amplify result
	V *= A;
	
	// limit to 1.0
	V /= (1.0 + V);
	
	// scale for index up to red
	V *= 5.0;
	
	// limit function guarantees n < 5
	long n = V;
	float R = colorSpectrum[n][0];
	float G = colorSpectrum[n][1];
	float B = colorSpectrum[n][2];

	float r = V - floor(V);
	if (r != 0)
	{
		R += r * (colorSpectrum[n+1][0] - R);
		G += r * (colorSpectrum[n+1][1] - G);
		B += r * (colorSpectrum[n+1][2] - B);
	}
	
	dstPtr[0] = RGBAColorMake(R+0.5, G+0.5, B+0.5);
}


static inline void _DCT_to_Image(float A, float *srcPtr, UInt32 *dstPtr, long n)
{
	while (n != 0)
	{
		n -= 1;
		DCT_ValueToColor(A, srcPtr[n], &dstPtr[n]);
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

- (NSBitmapImageRep *) spectrumImageWithGain:(UInt32)a
{
	uint64_t maxSampleCount = _sampleMonitor.maxIndex + 1;

	// need at least one row of sample data
	if (maxSampleCount < mDCTCount)
	{ return nil; }

	// count overlapping rows
	uint64_t maxRowCount = (maxSampleCount >> (mDCTShift-1)) - 1;

	// compute next image range
	uint64_t rowIndex = mRowIndex;
	uint64_t rowCount = maxRowCount - rowIndex;
	
	// rowIndex == 0 indicates new spectrogram controller
	// rowIndex >= maxRowCount indicates new sampleMonitor
	if ((rowIndex == 0)||(rowIndex >= maxRowCount))
	{
		rowIndex = maxRowCount-1;
		rowCount = 1;
	}

	// limit number of imagerows to something reasonable
	if (rowCount > 128)
	{
		rowIndex = maxRowCount-128;
		rowCount = 128;
		NSLog(@"RMSSpectrogram rowcount > 128: %llu", rowCount);
	}
	
	// store next rowindex
	mRowIndex = maxRowCount;
	
	// return image
	return [self imageRepWithRange:(NSRange){ rowIndex, rowCount } gain:a];
}

////////////////////////////////////////////////////////////////////////////////

- (NSBitmapImageRep *) imageRepFromIndex:(size_t)rowIndex gain:(UInt32)a
{ return [self imageRepWithRange:(NSRange){ rowIndex, 0 } gain:a]; }

////////////////////////////////////////////////////////////////////////////////

- (NSBitmapImageRep *) imageRepWithRange:(NSRange)rangeY gain:(UInt32)a
{
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:nil
		pixelsWide:mDCTCount * 2
		pixelsHigh:rangeY.length
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bitmapFormat:0
		bytesPerRow:mDCTCount * 2 * 4 * sizeof(Byte)
		bitsPerPixel:8 * 4 * sizeof(Byte)];

	float *dstPtr = (float *)bitmap.bitmapData;

	float A = pow(10.0, a);

	uint64_t sampleCount = (rangeY.location + rangeY.length + 1)<<(mDCTShift-1);
	NSRange R = { sampleCount-mDCTCount, mDCTCount };

	for (UInt32 n=0; n!=rangeY.length; n++)
	{
		[_sampleMonitor getSamplesL:dstPtr withRange:R];
		vDSP_vmul(dstPtr, 1, mW, 1, dstPtr, 1, mDCTCount);
		vDSP_DCT_Execute(mDCTSetup, dstPtr, dstPtr);
		vDSP_vrvrs(dstPtr, 1, mDCTCount);
		_DCT_to_Image(A, dstPtr, (UInt32 *)dstPtr, mDCTCount);

		dstPtr += mDCTCount;
		
		[_sampleMonitor getSamplesR:dstPtr withRange:R];
		vDSP_vmul(dstPtr, 1, mW, 1, dstPtr, 1, mDCTCount);
		vDSP_DCT_Execute(mDCTSetup, dstPtr, dstPtr);
		_DCT_to_Image(A, dstPtr, (UInt32 *)dstPtr, mDCTCount);

		dstPtr += mDCTCount;
		
		R.location -= R.length>>1;
	}
	
	return bitmap;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

CGContextRef CGBitmapContextCreateRGBA8WithSize(size_t W, size_t H)
{
	CGContextRef context = nil;
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
	if (colorSpace != nil)
	{
		context = CGBitmapContextCreate(nil, W, H,
		8, 0, colorSpace, kCGImageAlphaLast);
		
		CGColorSpaceRelease(colorSpace);
	}
	
	return context;
}

NSBitmapImageRep *NSBitmapImageRepWithSize(size_t W, size_t H)
{
	return [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:nil
		pixelsWide:W
		pixelsHigh:H
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bitmapFormat:0
		bytesPerRow:W * 4 * sizeof(Byte)
		bitsPerPixel:8 * 4 * sizeof(Byte)];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

static void _Copy32f(float *srcPtr, float *dstPtr, UInt32 n)
{
	memcpy(dstPtr, srcPtr, n*sizeof(float));
}

+ (RMSClip *) computeSampleBufferUsingImage:(NSImage *)image
{
	UInt32 W = round(image.size.width);
	UInt32 H = round(image.size.height);

	H = 512 * H / W;
	W = 512;
//	H += H;
	
	NSBitmapImageRep *bitmap = NSBitmapImageRepWithSize(W, H);
	if (bitmap != nil)
	{
		NSGraphicsContext *context =
		[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
		
		[NSGraphicsContext setCurrentContext:context];
		
		[image drawInRect:(NSRect){0.0, 0.0, W, H }];
		
		return [self computeSampleBufferUsingBitmapImageRep:bitmap];
	}
	
	return nil;
}

////////////////////////////////////////////////////////////////////////////////

void MDCT_Fold(float *srcPtr, float *dstPtr, size_t dstSize)
{
	size_t N = dstSize/2;
	float *a = &srcPtr[0*N];
	float *b = &srcPtr[1*N];
	float *c = &srcPtr[2*N];
	float *d = &srcPtr[3*N];
	
	for (size_t n=0; n!=N; n++)
	{
		dstPtr[n] = -c[N-1-n] - d[n];
	}
	
	dstPtr += N;
	
	for (size_t n=0; n!=N; n++)
	{
		dstPtr[n] = a[n] - b[N-1-n];
	}
}



+ (RMSClip *) computeSampleBufferUsingBitmapImageRep:(NSBitmapImageRep *)bitmap
{
	RMSClip *clip = nil;
	
	
	NSInteger W = bitmap.pixelsWide;
	NSInteger H = bitmap.pixelsHigh;

	
	// initialize DCT setup
	vDSP_DFT_Setup dctSetup = vDSP_DCT_CreateSetup(nil, W, vDSP_DCT_IV);
	if (dctSetup != nil)
	{

		float *F = calloc(W, sizeof(float));
		if (F != nil)
		{
			float *tmpPtr = calloc(W, sizeof(float));
			if (tmpPtr != nil)
			{
				for (long n=0; n!=W; n++)
				{
					float x = (1.0*n + 0.5)/W;
					float y = sin(x*M_PI);
					F[n] = 1-y*y;
				}

				
				
				clip = [[RMSClip alloc] initWithLength:(H+1) * (W/2)];
				if (clip != nil)
				{
					Byte *srcPtr = [bitmap bitmapData];
					float *dstPtr = clip.mutablePtrL;
					dstPtr += (H+1) * (W/2) - W;

					for (UInt32 y=0; y!=H; y++)
					{
						for (UInt32 x=0; x!=W; x++)
						{
							long R = srcPtr[0];
							long G = srcPtr[1];
							long B = srcPtr[2];
							srcPtr += 4;

							tmpPtr[x] = (3*R + 4*G + B) / (8*255.0);
						}

						vDSP_DCT_Execute(dctSetup, tmpPtr, tmpPtr);
						vDSP_vmul(F, 1, tmpPtr, 1, tmpPtr, 1, W);
						vDSP_vadd(tmpPtr, 1, dstPtr, 1, dstPtr, 1, W);
						
						srcPtr += bitmap.bytesPerRow - 4*W;
						dstPtr -= W/2;
						
						
					}
				
					_Copy32f(clip.mutablePtrL, clip.mutablePtrR, clip.sampleCount);
		
					[clip normalize];
				}
				
				free(tmpPtr);
			}
			
			free(F);
		}
		
		vDSP_DFT_DestroySetup(dctSetup);
	}
	
	return clip;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



