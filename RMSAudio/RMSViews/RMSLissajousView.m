//
//  RMSLissajousView.m
//  RMSAudioApp
//
//  Created by 32BT on 07/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSLissajousView.h"
#import <Accelerate/Accelerate.h>

#define kRMSLissajousAngleCount 16
float gCOSn[kRMSLissajousAngleCount];
float gSINn[kRMSLissajousAngleCount];

@interface RMSLissajousView ()
{
	uint64_t mIndex;
	uint64_t mCount;
	float mL[kRMSLissajousCount];
	float mR[kRMSLissajousCount];
	
	float mFilterValue;
	float mLf;
	float mRf;
	
	
	double mQ[4];
	
	float mA[kRMSLissajousAngleCount];
	
	
	
}

@property (nonatomic, assign) float correlation;
@property (nonatomic, assign) float correlationL;
@property (nonatomic, assign) float correlationR;

/*
	Following need to be atomic since a redraw may be triggered 
	by the system while the background process runs
	
	Alternatively, we might create an internal transfer ivar, 
	since "didUpdateWithSampleMonitor:" and "redraw:" will 
	never be called concurrently.
*/
@property (atomic) NSBezierPath *phasePath;
@property (atomic) NSBezierPath *anglePath;

@end


#define HSB(h, s, b) \
[NSColor colorWithCalibratedHue:h/360.0 saturation:s brightness:b alpha:1.0]

////////////////////////////////////////////////////////////////////////////////
@implementation RMSLissajousView
////////////////////////////////////////////////////////////////////////////////

+ (void) initialize
{
	for(int n=0; n!=kRMSLissajousAngleCount; n++)
	{
		double a = M_PI * (-1.0 + 2.0 * n / kRMSLissajousAngleCount);
		gCOSn[n] = cos(a);
		gSINn[n] = sin(a);
	}
}

////////////////////////////////////////////////////////////////////////////////

- (float)correlationValue
{ return self.correlation; }

////////////////////////////////////////////////////////////////////////////////

- (void) setFilter:(float)value
{
	mFilterValue = value*value;
}

- (void) setDuration:(float)value
{
	if (value > 1.0) value = 1.0;
	[self setCount:value * kRMSLissajousCount];
}

////////////////////////////////////////////////////////////////////////////////

- (void) setCount:(size_t)count
{
	if (count == 0)
	{ count = 4; }
	
	if (mCount != count)
	{
		mCount = count;
		[self triggerUpdate];
	}
}

////////////////////////////////////////////////////////////////////////////////

double computeAvg(float *srcPtr, size_t n)
{
	float R = 0.0;
	vDSP_rmsqv(srcPtr, 1, &R, n);
	return R;
	
	double m = 1.0 / n;
	double A = 0.0;
	while (n != 0)
	{
		double S = srcPtr[(n-=1)];
		A += S*S;
	}
	return sqrt(m*A);
}

////////////////////////////////////////////////////////////////////////////////

- (void) prepareSamples
{
	double avgL = computeAvg(mL, mCount);
	double avgR = computeAvg(mR, mCount);
	
	double A = sqrt(0.5 * (avgL*avgL+avgR*avgR));
	
	if (avgL == 0.0)
	{ avgL = 1.0; }
	if (avgR == 0.0)
	{ avgR = 1.0; }
	
	float scaleL = A / avgL;
	float scaleR = A / avgR;
	
	vDSP_vsmul(mL, 1, &scaleL, mL, 1, mCount);
	vDSP_vsmul(mR, 1, &scaleR, mR, 1, mCount);
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	float *ptr[2] = { mL, mR };
	
	if (mCount == 0)
	{ mCount = 256; }
	
	// TODO: getsamples with range and step,
	// for better distribution over elapsed time
	
	[sampleMonitor getSamples:ptr count:mCount];
	[self updatePhasePath];
	//[self updateAnglePath];
	[self updateCorrelation];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updatePhasePath
{
	NSBezierPath *path = [NSBezierPath new];
	
//	if (mGraphType == kRMSLissajousGraphTypeStar)
//*
	for (int n=0; n!=mCount; n++)
	{
		[path moveToPoint:NSZeroPoint];
		[path lineToPoint:[self pointAtIndex:n]];
	}
/*/
	[path moveToPoint:[self pointAtIndex:0]];
	for (int n=1; n!=mCount; n++)
	{ [path lineToPoint:[self pointAtIndex:n]]; }
//*/
	self.phasePath = path;
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateAnglePath
{
	float A[kRMSLissajousAngleCount];
	for (int n=0; n!=kRMSLissajousAngleCount; n++)
	{ A[n] = 0; }

	for (int n=0; n!=mCount; n++)
	{
		double L = mL[n];
		double R = mR[n];
		
		double a = atan2(L, R) * (1.0 / M_PI);
		if (a < 0.0) a += 1.0;
		if (a > 0.5) a -= 1.0;
		a += 0.5;
		
		int i = round(kRMSLissajousAngleCount*a);
		if (i >= kRMSLissajousAngleCount)
		{ i = 0; }
		A[i] += 1;
	}
	
	float N = 10;
	vDSP_vavlin(A, 1, &N, mA, 1, kRMSLissajousAngleCount);
	
	
	NSPoint P[kRMSLissajousAngleCount];
	for (int n=0; n!=kRMSLissajousAngleCount; n++)
	{
		double d = mA[n] / mCount;
		
		d = pow(d, .2);
		P[n].x = d * gCOSn[n];
		P[n].y = d * gSINn[n];
	}
	
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:P[kRMSLissajousAngleCount-1]];
	for (int n=0; n!=kRMSLissajousAngleCount; n++)
	[path lineToPoint:P[n]];
	self.anglePath = path;
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateCorrelation
{
	float sum = 0.0;
	float sumL = 0.0;
	float sumR = 0.0;
	
	vDSP_dotpr(mL, 1, mR, 1, &sum, mCount);
	vDSP_svesq(mL, 1, &sumL, mCount);
	vDSP_svesq(mR, 1, &sumR, mCount);
	
	if (sumR > 0.0)
	{ self.correlationL += 0.05 * ((sum / sumR) - self.correlationL); }

	if (sumL > 0.0)
	{ self.correlationR += 0.05 * ((sum / sumL) - self.correlationR); }
	
	if (sumL > 0.0 && sumR > 0.0)
	sum /= sqrt(sumL*sumR);
	
	self.correlation += 0.05 * (sum - self.correlation);
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateQ:(NSPoint)P
{
	if (P.x >= 0.0)
	{
		if (P.y >= 0.0)
		mQ[0] += 1;
		
		if (P.y <= 0.0)
		mQ[3] += 1;
	}

	if (P.x <= 0.0)
	{
		if (P.y >= 0.0)
		mQ[1] += 1;
		
		if (P.y <= 0.0)
		mQ[2] += 1;
	}
}


- (NSPoint) pointAtIndex:(int)n
{
	double L = mL[n];
	double R = mR[n];
	
/*	
	mLf += mFilterValue * (L - mLf);
	mRf += mFilterValue * (R - mRf);
	
	L = mLf;
	R = mRf;
*/	
	double d = sqrt(0.5 * (L*L+R*R));
	d = d > 0.0 ? 0.5 * pow(d, 0.5)/d : 0.5;
	L *= d;
	R *= d;
	
	return (NSPoint){ R-L, R+L };
}



- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	[self adjustOrigin];

	
	[[NSColor darkGrayColor] set];
	NSRectFill(self.bounds);

	
	[[NSColor blackColor] set];
	NSBezierPath *path = [NSBezierPath new];
	[path moveToPoint:(NSPoint){ 0.0, NSMinY(self.bounds) }];
	[path lineToPoint:(NSPoint){ 0.0, NSMaxY(self.bounds) }];
	[path moveToPoint:(NSPoint){ NSMinX(self.bounds), 0.0 }];
	[path lineToPoint:(NSPoint){ NSMaxX(self.bounds), 0.0 }];
	[self drawPath:path];
	

	[HSB(60.0, 0.25, 1.0) set];
	[self drawPath:self.phasePath];

	[HSB(240.0, 0.5, 1.0) set];
//	[self drawPath:self.anglePath];
	
	// draw correlation
	float C = self.correlation;

	[[NSColor redColor] set];
	[path removeAllPoints];
	[path moveToPoint:(NSPoint){ -1.0, C }];
	[path lineToPoint:(NSPoint){ +1.0, C }];
	[self drawPath:path];

	float CL = self.correlationL;
	float CR = self.correlationR;
	float a = atan2(CL, CR)+0.25*M_PI;
	[path removeAllPoints];
	[path moveToPoint:(NSPoint){ 0.0, 0.0 }];
	[path lineToPoint:(NSPoint){ cos(a), sin(a) }];
	[self drawPath:path];




/*
	mQ[0] = 0;
	mQ[1] = 0;
	mQ[2] = 0;
	mQ[3] = 0;
	for (int n=0; n!=mCount; n++)
	{
		NSPoint P = { mR[n], mL[n] };
		[self updateQ:P];
	}
	
	
	double S = mQ[0]+mQ[1]+mQ[2]+mQ[3];
	if (S > 0.0)
	{
		[[NSColor redColor] set];
		[path removeAllPoints];
		[path moveToPoint:(NSPoint){ 0.0, +mQ[0]/S }];
		[path lineToPoint:(NSPoint){ -mQ[1]/S, 0.0 }];
		[path lineToPoint:(NSPoint){ 0.0, -mQ[2]/S }];
		[path lineToPoint:(NSPoint){ +mQ[3]/S, 0.0 }];
		[path closePath];
		[self drawPath:path];
	}
*/
/*
	float A[kRMSLissajousAngleCount];
	for (int n=0; n!=kRMSLissajousAngleCount; n++)
	{ A[n] = 0; }

	for (int n=0; n!=mCount; n++)
	{
		double L = mL[n];
		double R = mR[n];
		
		double a = atan2(L, R) / M_PI;
		if (a < 0.0) a += 1.0;
		if (a > 0.5) a = -(1-a);
		a += 0.5;
		
		int i = kRMSLissajousAngleCount*a+0.5;
		if (i >= kRMSLissajousAngleCount)
		{ i = 0; }
		A[i] += 1;
	}
	
	float N = 10;
	vDSP_vavlin(A, 1, &N, mA, 1, kRMSLissajousAngleCount);
	
	
	NSPoint P[kRMSLissajousAngleCount];
	for (int n=0; n!=kRMSLissajousAngleCount; n++)
	{
		double d = mA[n] / mCount;
		
		d = pow(d, .2);
		P[n].x = d * mCOSn[n];
		P[n].y = d * mSINn[n];
	}
	
	[HSB(240.0, 0.25, 1.0) set];
	path = [NSBezierPath new];
	[path moveToPoint:P[kRMSLissajousAngleCount-1]];
	for (int n=0; n!=kRMSLissajousAngleCount; n++)
	[path lineToPoint:P[n]];
	[self drawPath:path];
/*
	[[NSColor redColor] set];
	[path removeAllPoints];
	{
		double a = atan2(mAvgR, mAvgL);
		
		[path moveToPoint:(NSPoint){ 0, NSMinY(self.bounds) }];
		[path lineToPoint:(NSPoint){ 0, NSMaxY(self.bounds) }];
		[path moveToPoint:(NSPoint){ NSMinX(self.bounds), 0 }];
		[path lineToPoint:(NSPoint){ NSMaxX(self.bounds), 0 }];
		
		NSAffineTransform *T = [NSAffineTransform transform];
		[T rotateByRadians:0.25*M_PI-a];
		path = [T transformBezierPath:path];
		
		[self drawPath:path];
	}
//*/
	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

////////////////////////////////////////////////////////////////////////////////

- (void) adjustOrigin
{
	NSRect B = self.bounds;
	CGFloat x = 0.50 * B.size.width;
	CGFloat y = 0.50 * B.size.height;
	B.origin.x = -(floor(x)+0.5);
	B.origin.y = -(floor(y)+0.5);
	self.bounds = B;
}

////////////////////////////////////////////////////////////////////////////////

NSBezierPath *NSBezierPathWithCircle(NSPoint P, float R)
{
	return [NSBezierPath bezierPathWithOvalInRect:(NSRect){
	P.x - R,
	P.y - R,
	R + R,
	R + R }];
	
}

- (void) drawDot:(NSPoint)P
{
	NSRect B = self.bounds;
	CGFloat S = 0.5 * MIN(B.size.width, B.size.height);
	P.x *= S;
	P.y *= S;
	
	[NSBezierPathWithCircle(P, 1.0) fill];
}

////////////////////////////////////////////////////////////////////////////////

- (void) drawPath:(NSBezierPath *)path
{
	NSRect B = self.bounds;
	CGFloat S = 0.707 * 0.5 * MIN(B.size.width, B.size.height);
	
	NSAffineTransform *T = [NSAffineTransform transform];
	[T scaleBy:S];

	if (path != nil)
	{ [[T transformBezierPath:path] stroke]; }
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////







