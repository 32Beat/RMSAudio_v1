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

	CGFloat y, x = 1.0;
	CGFloat X = 1.0/(N-1);
	CGFloat Y = pow(2.0, self.gain);

	NSBezierPath *pathL = [NSBezierPath new];
	NSBezierPath *pathR = [NSBezierPath new];

	y = Y * RMSBufferGetSampleAtIndex(bufferL, index);
	[pathL moveToPoint:(NSPoint){ x, y }];
	y = Y * RMSBufferGetSampleAtIndex(bufferR, index);
	[pathR moveToPoint:(NSPoint){ x, y }];
	
	for (int n=N; n!=0; n--)
	{
		x -= X;
		index -= 1;
		
		y = Y * RMSBufferGetSampleAtIndex(bufferL, index);
		[pathL lineToPoint:(NSPoint){ x, y }];
		y = Y * RMSBufferGetSampleAtIndex(bufferR, index);
		[pathR lineToPoint:(NSPoint){ x, y }];
	}

	dispatch_async(dispatch_get_main_queue(),
	^{
		self.wavePathL = pathL;
		self.wavePathR = pathR;
		[self setNeedsDisplay:YES];
	});
}

////////////////////////////////////////////////////////////////////////////////

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);

	NSRect B = self.bounds;
	
	NSAffineTransform *T = [NSAffineTransform new];
	[T translateXBy:1.0 yBy:NSMidY(B)];
	[T scaleXBy:B.size.width-2.0 yBy:B.size.height/2.0];
	
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
