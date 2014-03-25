//
//  facebook_RequestDelegate.m
//  Forge
//
//  Created by Connor Dunn on 13/07/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "facebook_RequestDelegate.h"

@implementation facebook_RequestDelegate

- (facebook_RequestDelegate*) initWithTask:(ForgeTask*)newTask andFacebook:(Facebook *)newFb {
	if (self = [super init]) {
		// "retain"
		me = self;
		task = newTask;
		fb = newFb;
	}	
	return self;
}

- (void) request:(FBRequest *)request didFailWithError:(NSError *)error {
    if ([FBErrorUtility shouldNotifyUserForError:error] == YES) {
        [task error:[FBErrorUtility userMessageForError:error]];
    } else {
        NSDictionary *info = [[[error userInfo] objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"]
                                                objectForKey:@"error"];
        [task error:info];
    }
	// "release"
	me = nil;
	fb = nil;
}

- (void) request:(FBRequest *)request didLoad:(id)result {
	[task success:result];
	// "release"
	me = nil;
	fb = nil;
}

@end
