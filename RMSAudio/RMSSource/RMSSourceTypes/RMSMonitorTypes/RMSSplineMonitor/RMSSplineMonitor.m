////////////////////////////////////////////////////////////////////////////////
/*
	RMSSplineMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSplineMonitor.h"
#import <Accelerate/Accelerate.h>


// Number of testsamples
#define kRMSSplineMonitorCount 	2048

// Number of error bins
#define kRMSSplineErrorCount 	16


@interface RMSSplineMonitor ()
{
	double mE[kRMSSplineErrorCount];
	double mMaxE; // helps to scale mE to relative range
	double mMinX; // will hold x-coordinate of lowest error location
	UInt64 mN;    // stores modulating bin index

	float mT[kRMSSplineMonitorCount];
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSplineMonitor
////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	uint64_t maxSampleCount = sampleMonitor.maxIndex+1;
	if (maxSampleCount >= kRMSSplineMonitorCount)
	{
		NSRange R = { maxSampleCount - kRMSSplineMonitorCount, kRMSSplineMonitorCount };
		
		[sampleMonitor getSamplesL:mT withRange:R];
		[self testSamples:mT];
		[sampleMonitor getSamplesR:mT withRange:R];
		[self testSamples:mT];
		
		[self updateStats];
	}
}

////////////////////////////////////////////////////////////////////////////////

static double Bezier
(double x, double P1, double C1, double C2, double P2)
{
	P1 += x * (C1 - P1);
	C1 += x * (C2 - C1);
	C2 += x * (P2 - C2);
	
	P1 += x * (C1 - P1);
	C1 += x * (C2 - C1);

	P1 += x * (C1 - P1);

	return P1;
}

////////////////////////////////////////////////////////////////////////////////

static double Interpolate
(double a, double x, double Y0, double Y1, double Y2, double Y3)
{
	double d1 = a * (Y2 - Y0) / 2.0;
	double d2 = a * (Y3 - Y1) / 2.0;
	return Bezier(x, Y1, Y1+d1, Y2-d2, Y2);
}

////////////////////////////////////////////////////////////////////////////////
/*
static double FetchSample_(float *srcPtr)
{ return srcPtr[0]; }
/*/
static double FetchSample(float *srcPtr)
{ return srcPtr[0]+srcPtr[1]+srcPtr[1]+srcPtr[2]; }
//*/
////////////////////////////////////////////////////////////////////////////////

static double ComputeError(double a, float *srcPtr)
{
	double S1 = FetchSample(&srcPtr[0]);
	double S2 = FetchSample(&srcPtr[2]);
	double S3 = FetchSample(&srcPtr[4]);
	double S4 = FetchSample(&srcPtr[6]);
	
	double S = FetchSample(&srcPtr[3]);
	double R = Interpolate(a, 0.5, S1, S2, S3, S4);
	double E = S - R;

	return E*E;
}

////////////////////////////////////////////////////////////////////////////////

- (void) testSamples:(float *)srcPtr
{
	for (int n=0; n!=kRMSSplineMonitorCount-8; n++)
	{
		double a = mN * (1.0 / (kRMSSplineErrorCount-1));
		
		double E = ComputeError(a, &srcPtr[n]);
		
		mE[mN] += 0.00001 * (E - mE[mN]);
		
		mN += 31;
		mN &= (kRMSSplineErrorCount-1);
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateStats
{
	size_t N = self.errorCount;
	vDSP_maxvD(mE, 1, &mMaxE, N);
	
	if (mMaxE != 0.0)
	{
		double a = [self averageSlope];
		double b = [self averageIntercept:a];
		
		mMinX = a != 0.0 ? -b / a : 0.0;
	}
}

////////////////////////////////////////////////////////////////////////////////

- (double) averageSlope
{
	double sum = 0.0;
	double sumN = 0.0;

	size_t N = self.errorCount;
	
	for (int n=1; n!=N-1; n++)
	{
		for (int m=n+1; m!=N; m++)
		{
			sum += ([self slopeAtIndex:m]-[self slopeAtIndex:n])/(m-n);
			sumN += 1;
		}
	}
	
	return (N-1) * sum / sumN;
}

////////////////////////////////////////////////////////////////////////////////

- (double) averageIntercept:(double)a
{
	double sum = 0.0;
	
	size_t N = self.errorCount;

	for (int n=1; n!=N; n++)
	{
		double x = (1.0*n-0.5)/(N-1);
		double y = [self slopeAtIndex:n];
		sum += y - a*x;
	}
	
	return sum / (N-1);
}

////////////////////////////////////////////////////////////////////////////////
/*
- (void) LSQ
{
	double Sx = 0.0;
	double Sy = 0.0;
	double Sxx = 0.0;
	double Sxy = 0.0;
	double Syy = 0.0;
	
	for (int n=1; n!=N; n++)
	{
		CGFloat x = (1.0 * n - 0.5) / (N-1);
		CGFloat y = (errorPtr[n]-errorPtr[n-1])/self.maxE;

		Sx += x;
		Sy += y;
		Sxx += x*x;
		Sxy += x*y;
		Syy += y*y;
	}

	double sumN = (N-1);
	double B = (sumN*Sxy-Sx*Sy)/(sumN*Sxx-Sx*Sx);
	double A = (Sy-B*Sx)/sumN;
}
*/
////////////////////////////////////////////////////////////////////////////////

- (double) optimum
{ return mMinX; }

- (double) slopeAtIndex:(int)n
{ return (mE[n]-mE[n-1]) / mMaxE; }

- (NSPoint) errorPointAtIndex:(int)n
{ return (NSPoint){ (CGFloat)n / (self.errorCount-1), [self errorAtIndex:n] }; }

- (NSPoint) slopePointAtIndex:(int)n
{ return (NSPoint){ (CGFloat)(n-0.5) / (self.errorCount-1), [self slopeAtIndex:n] }; }

////////////////////////////////////////////////////////////////////////////////

- (const double *) errorPtr
{ return mE; }

- (size_t) errorCount
{ return kRMSSplineErrorCount; }

- (double) errorAtIndex:(int)n
{ return mMaxE > 0.0 ? mE[n] / mMaxE : 0.0; }

////////////////////////////////////////////////////////////////////////////////

- (NSBezierPath *) createErrorPath
{
	if (mMaxE == 0.0)
	{ return nil; }

	int N = self.errorCount;

	NSBezierPath *path = [NSBezierPath new];

	NSPoint P = { 0.0, mE[0]/mMaxE };
	[path moveToPoint:P];
	for (int n=1; n!=N; n++)
	{
		P.x += (1.0/(N-1));
		P.y = mE[n]/mMaxE;
		[path lineToPoint:P];
	}
	
	return path;
}

////////////////////////////////////////////////////////////////////////////////

- (NSBezierPath *) createSlopePath
{
	if (mMaxE == 0.0)
	{ return nil; }

	int N = self.errorCount;

	NSBezierPath *path = [NSBezierPath new];
	
	NSPoint P = { 0.5/(N-1), 0.5 + (mE[1]-mE[0])/mMaxE };
	[path moveToPoint:P];
	for (int n=2; n!=N; n++)
	{
		P.x += (1.0/(N-1));
		P.y = 0.5 + (mE[n]-mE[n-1])/mMaxE;
		[path lineToPoint:P];
	}
	
	return path;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

static inline UInt32 RGBAColorMake(UInt32 R, UInt32 G, UInt32 B)
{ return (255<<24)+(B<<16)+(G<<8)+(R<<0); }

static inline void DCT_ValueToColor(double A, double V, UInt32 *dstPtr)
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


static inline void _DCT_to_Image(float A, double *srcPtr, UInt32 *dstPtr, long n)
{
	while (n != 0)
	{
		n -= 1;
		DCT_ValueToColor(A, srcPtr[n], &dstPtr[n]);
	}
}

////////////////////////////////////////////////////////////////////////////////
/*
- (NSBitmapImageRep *) imageRepWithGain:(UInt32)a
{
	double *srcPtr = &mE[0][0];
	
	double *tmpPtr = calloc(kRMSSplineMonitorCount*kRMSSplineMonitorCount, sizeof(double));
	memcpy(tmpPtr, srcPtr, kRMSSplineMonitorCount*kRMSSplineMonitorCount*sizeof(double));

	srcPtr = tmpPtr;
	double min = srcPtr[0];
	double max = srcPtr[0];
	for (UInt32 n=1; n!=kRMSSplineMonitorCount*kRMSSplineMonitorCount; n++)
	{
		if (min > srcPtr[n]) min = srcPtr[n];
		if (max < srcPtr[n]) max = srcPtr[n];
	}
	
	if (max > min)
	{
		for (UInt32 n=0; n!=kRMSSplineMonitorCount*kRMSSplineMonitorCount; n++)
		{
			srcPtr[n] = (srcPtr[n] - min) / (max - min);
		}
	}
	
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
		initWithBitmapDataPlanes:nil
		pixelsWide:kRMSSplineMonitorCount
		pixelsHigh:kRMSSplineMonitorCount
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSCalibratedRGBColorSpace
		bitmapFormat:0
		bytesPerRow:kRMSSplineMonitorCount * 4 * sizeof(Byte)
		bitsPerPixel:8 * 4 * sizeof(Byte)];

	UInt32 *dstPtr = (UInt32 *)bitmap.bitmapData;
	
	float A = pow(10.0, a);
	
	for (UInt32 n=0; n!=kRMSSplineMonitorCount; n++)
	{
		_DCT_to_Image(A, srcPtr, dstPtr, kRMSSplineMonitorCount);
		srcPtr += kRMSSplineMonitorCount;
		dstPtr += kRMSSplineMonitorCount;
	}
	
	free(tmpPtr);
	
	return bitmap;
}
*/
////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



