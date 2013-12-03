//
//  facebook_DialogDelegate.h
//  Forge
//
//  Created by Connor Dunn on 13/07/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

@interface facebook_DialogDelegate : NSObject <FBDialogDelegate> {
	facebook_DialogDelegate *me;
	Facebook *fb;
	ForgeTask *task;
}

- (facebook_DialogDelegate*) initWithTask:(ForgeTask*)newTask andFacebook:(Facebook*)newFb;

@end
