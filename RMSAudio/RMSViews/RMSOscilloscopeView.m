//
//  RMSOscilloscopeView.m
//  RMSAudio
//
//  Created by 32BT on 24/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//


#import "RMSOscilloscopeView.h"


@interface RMSOscilloscopeView ()
@property (nonatomic) NSBezierPath *wavePath;
@end


@implementation RMSOscilloscopeView

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	NSRect B = self.bounds;
	
	size_t N = B.size.width;
	
	uint64_t index = sampleMonitor.maxIndex;
	rmsbuffer_t *bufferL = [sampleMonitor bufferAtIndex:0];
	rmsbuffer_t *bufferR = [sampleMonitor bufferAtIndex:1];
	
	CGFloat ym = NSMidY(B);
	CGFloat yh = NSMaxY(B)-ym;
	
	NSBezierPath *path = [NSBezierPath new];
	
	[path moveToPoint:(NSPoint){ N+0.5, ym }];
	for (int n=N; n!=0; n--)
	{
		CGFloat x = n - 0.5;
		CGFloat y = ym + yh * RMSBufferGetSampleAtIndex(bufferL, index--);
		[path lineToPoint:(NSPoint){ x, y }];
 	}
	
	dispatch_async(dispatch_get_main_queue(),
	^{
		self.wavePath = path;
		[self setNeedsDisplay:YES];
	});
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
	
	[[NSColor whiteColor] set];
	NSRectFill(self.bounds);
	
	[[NSColor blackColor] set];
	[self.wavePath stroke];

	[[NSColor blackColor] set];
	NSFrameRect(self.bounds);
	
    // Drawing code here.
}

@end
