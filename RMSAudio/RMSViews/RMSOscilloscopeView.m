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
	
	NSRect B = self.bounds;
	CGFloat ym = NSMidY(B);
	CGFloat yh = NSMaxY(B)-ym;
	
	NSBezierPath *pathL = [NSBezierPath new];
	NSBezierPath *pathR = [NSBezierPath new];
	
	[pathL moveToPoint:(NSPoint){ B.size.width+0.5, ym }];
	[pathR moveToPoint:(NSPoint){ B.size.width+0.5, ym }];
	CGFloat y, x = NSMaxX(B);
	CGFloat xstep = B.size.width / N;
	for (int n=N; n!=0; n--)
	{
		x -= xstep;
		y = ym + yh * RMSBufferGetSampleAtIndex(bufferL, index--);
		[pathL lineToPoint:(NSPoint){ x, y }];
		y = ym + yh * RMSBufferGetSampleAtIndex(bufferR, index--);
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

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);
	
	[HSB(120.0, 1.0, 0.5) set];
	[self.wavePathL stroke];
	[[NSColor redColor] set];
	[self.wavePathR stroke];

	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
	
    // Drawing code here.
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
