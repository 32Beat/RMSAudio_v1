//
//  RMSSplineMonitorView.m
//  RMSAudioApp
//
//  Created by 32BT on 05/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSplineMonitorView.h"
#import "RMSSampleMonitor.h"

#define kRMSSplineMonitorCount 	2048
#define kRMSSplineErrorCount 	32

@interface RMSSplineMonitorView ()
{
	float mT[kRMSSplineMonitorCount];

	int mN;
	double mE[kRMSSplineErrorCount];
	double mMinE;
	double mMaxE;
	double mMinValue;
	
	NSImageRep *mImageRep;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation RMSSplineMonitorView
////////////////////////////////////////////////////////////////////////////////

- (void) setSplineMonitor:(RMSSplineMonitor *)splineMonitor
{
	if (_splineMonitor != splineMonitor)
	{
		_splineMonitor = splineMonitor;
		[self triggerUpdate];
	}
}

////////////////////////////////////////////////////////////////////////////////

- (float) minValue
{ return mMinValue; }

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
static double FetchSample(float *srcPtr)
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
		
		mE[mN] += 0.0001 * (E - mE[mN]);
		
		mN += 31;
		mN &= (kRMSSplineErrorCount-1);
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateStats
{
	double min = mE[0];
	double max = mE[0];
	
	for (int n=1; n!=kRMSSplineErrorCount; n++)
	{
		if (min > mE[n]) min = mE[n];
		if (max < mE[n]) max = mE[n];
	}
	
	mMinE = min;
	mMaxE = max;

	double A1 = mE[0];
	double A2 = mE[kRMSSplineErrorCount-1];
	double A = 0.5;
	if (A1 > A2)
	{
		A = 1.0/(1.0+sqrt((A2-min)/(A1-min)));
	}
	else
	if (A1 < A2)
	{
		A = 1.0/(1.0+sqrt((A1-min)/(A2-min)));
		A = 1.0 - A;
	}
	
	mMinValue = A;
}

////////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
	
	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);
	
	if (mMaxE > 0.0)
	[self drawGraph:NSInsetRect(self.bounds, 1, 1)];
	
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}



- (void) drawGraph:(NSRect)B
{
	[[NSColor grayColor] set];
	NSBezierPath *path = [NSBezierPath new];
	
	float x = NSMinX(B);
	float xstep = B.size.width / (kRMSSplineErrorCount-1);
	[path moveToPoint:(NSPoint){ x, B.size.height * mE[0]/mMaxE }];
	for (long n=1; n!=kRMSSplineErrorCount; n++)
	{
		x += xstep;
		[path lineToPoint:(NSPoint){ x, B.size.height*mE[n]/mMaxE }];
	}
	[path stroke];

	[[NSColor redColor] set];
	[path removeAllPoints];
	float X1 = NSMinX(B)+floor(B.size.width * mMinValue)+.5;
	float X2 = X1;
	float Y1 = NSMinY(B);
	float Y2 = NSMaxY(B);
	[path moveToPoint:(NSPoint){ X1, Y1 }];
	[path lineToPoint:(NSPoint){ X2, Y2 }];
	[path stroke];
	
}


@end
