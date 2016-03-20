//
//  RMSSampleMonitorView.m
//  RMSAudio
//
//  Created by 32BT on 20/03/16.
//  Copyright © 2016 32BT. All rights reserved.
//

#import "RMSSampleMonitorView.h"

@interface RMSSampleMonitorView ()
{
	BOOL mPendingUpdate;
}
@end


////////////////////////////////////////////////////////////////////////////////
@implementation RMSSampleMonitorView
////////////////////////////////////////////////////////////////////////////////

- (void) triggerUpdate
{ return [self triggerUpdateWithFinishBlock:nil]; }

////////////////////////////////////////////////////////////////////////////////

- (void) triggerUpdateWithFinishBlock:(void (^)(void))blockPtr
{
	RMSSampleMonitor *sampleMonitor = self.sampleMonitor;
	if (sampleMonitor != nil)
	{
		if (!mPendingUpdate)
		{
			mPendingUpdate = YES;
			dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),
			^{
				[self updateWithSampleMonitor:sampleMonitor];
				dispatch_async(dispatch_get_main_queue(),
				^{
					if (blockPtr != nil)
					{ blockPtr(); }
					[self setNeedsDisplay:YES];
					mPendingUpdate = NO;
				});
			});
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateWithSampleMonitor:(RMSSampleMonitor *)sampleMonitor
{
	
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////
