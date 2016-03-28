////////////////////////////////////////////////////////////////////////////////
/*
	RMSPhaseMonitor
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSPhaseMonitor.h"
#import <Accelerate/Accelerate.h>


#define kRMSPhaseMonitorCount 2048

@interface RMSPhaseMonitor ()
{
	size_t mCount;
	float mL[kRMSPhaseMonitorCount];
	float mR[kRMSPhaseMonitorCount];
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSPhaseMonitor
////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	if (mCount == 0)
	{ mCount = 512; }
	
	float *ptr[2] = { mL, mR };
	[sampleMonitor getSamples:ptr count:mCount];
	
	[self updateCorrelation];
}

////////////////////////////////////////////////////////////////////////////////

- (size_t) sampleCount
{ return mCount; }

////////////////////////////////////////////////////////////////////////////////

- (CGPoint) pointAtIndex:(int)n
{
	double L = mL[n];
	double R = mR[n];

	double d = sqrt(0.5 * (L*L+R*R));
	d = d > 0.0 ? 0.5 * pow(d, 0.5)/d : 0.5;
	L *= d;
	R *= d;
	
	return (CGPoint){ R-L, R+L };
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

- (NSBezierPath *) resultPath
{
	NSBezierPath *path = [NSBezierPath new];
	for (int n=0; n!=mCount; n++)
	{
		[path moveToPoint:CGPointZero];
		[path lineToPoint:[self pointAtIndex:n]];
	}
	
	return path;
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////



