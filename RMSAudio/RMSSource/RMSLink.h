////////////////////////////////////////////////////////////////////////////////
/*
	RMSLink
	
	Created by 32BT on 15/11/15.
	Copyright © 2015 32BT. All rights reserved.
*/
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@interface RMSLink : NSObject

@property (nonatomic) RMSLink *nextLink;

- (void) addLink:(RMSLink *)link;
- (void) insertLink:(RMSLink *)link;
- (void) removeLink:(RMSLink *)link;
- (void) removeLink;

@end
