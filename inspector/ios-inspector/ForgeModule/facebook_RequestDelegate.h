//
//  facebook_RequestDelegate.h
//  Forge
//
//  Created by Connor Dunn on 13/07/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"

@interface facebook_RequestDelegate : NSObject<FBRequestDelegate> {
	facebook_RequestDelegate *me;
	ForgeTask *task;
	Facebook *fb;
}

- (facebook_RequestDelegate*) initWithTask:(ForgeTask*)newTask andFacebook:(Facebook*)newFb;

@end
