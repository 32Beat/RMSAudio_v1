////////////////////////////////////////////////////////////////////////////////
/*
	RMSFlanger
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import "RMSSource.h"

@interface RMSFlanger : RMSSource
@property (nonatomic, assign) float delay;
@property (nonatomic, assign) float delayModulation;
@property (nonatomic, assign) float depth;

@end
