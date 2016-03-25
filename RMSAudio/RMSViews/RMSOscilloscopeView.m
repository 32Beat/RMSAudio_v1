//
//  RMSOscilloscopeView.m
//  RMSAudio
//
//  Created by 32BT on 24/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//


#import "RMSOscilloscopeView.h"


@interface RMSOscilloscopeView ()
{
	uint64_t mIndex;
}
@property (nonatomic) NSBezierPath *wavePathL;
@property (nonatomic) NSBezierPath *wavePathR;
@end

#define HSB(h, s, b) \
[NSColor colorWithCalibratedHue:h/360.0 saturation:s brightness:b alpha:1.0]

////////////////////////////////////////////////////////////////////////////////
@implementation RMSOscilloscopeView
////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	uint64_t maxIndex = sampleMonitor.maxIndex;
	size_t N = sampleMonitor.sampleRate / 20.0;
	
	uint64_t index = N * (maxIndex / N);
	if (mIndex == index) return;
	
	mIndex = index;
	
	rmsbuffer_t *bufferL = [sampleMonitor bufferAtIndex:0];
	rmsbuffer_t *bufferR = [sampleMonitor bufferAtIndex:1];

	NSPoint P = { 1.0, 0.0 };
	CGFloat X = 1.0/(N-1);

	NSBezierPath *pathL = [NSBezierPath new];
	NSBezierPath *pathR = [NSBezierPath new];

	P.y = RMSBufferGetSampleAtIndex(bufferL, index);
	[pathL moveToPoint:P];
	P.y = RMSBufferGetSampleAtIndex(bufferR, index);
	[pathR moveToPoint:P];
	
	for (int n=N; n!=0; n--)
	{
		P.x -= X;
		index -= 1;

		P.y = RMSBufferGetSampleAtIndex(bufferL, index);
		[pathL lineToPoint:P];
		P.y = RMSBufferGetSampleAtIndex(bufferR, index);
		[pathR lineToPoint:P];
	}

	dispatch_async(dispatch_get_main_queue(),
	^{
		self.wavePathL = pathL;
		self.wavePathR = pathR;
		[self setNeedsDisplay:YES];
	});
}

////////////////////////////////////////////////////////////////////////////////

- (BOOL) isOpaque
{ return YES; }

- (void)drawRect:(NSRect)dirtyRect
{
	NSRect B = self.bounds;

	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);
	
	NSAffineTransform *T = [NSAffineTransform new];
	[T translateXBy:1.5 yBy:NSMidY(B)];
	CGFloat X = (B.size.width-3.0);
	CGFloat Y = (B.size.height-2.0) * pow(2.0, self.gain-1);
	[T scaleXBy:X yBy:Y];
	
	[HSB(180.0, 1.0, 0.5) set];
	[[T transformBezierPath:self.wavePathL] stroke];
	[[NSColor redColor] set];
	[[T transformBezierPath:self.wavePathR] stroke];

	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
