//
//  facebook_DialogDelegate.m
//  Forge
//
//  Created by Connor Dunn on 13/07/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "facebook_DialogDelegate.h"

@implementation facebook_DialogDelegate

- (facebook_DialogDelegate*) initWithTask:(ForgeTask*)newTask andFacebook:(Facebook *)newFb {
	if (self = [super init]) {
		// "retain"
		me = self;
		task = newTask;
		fb = newFb;
	}	
	return self;
}

- (void)dialogCompleteWithUrl:(NSURL *)url {
	[task success:[url queryAsDictionary]];
	// "release"
	me = nil;
	fb = nil;
}

- (void) dialog:(FBDialog *)dialog didFailWithError:(NSError *)error {
	[task error:error];
	// "release"
	me = nil;
	fb = nil;
}

- (void) dialogDidNotComplete:(FBDialog *)dialog {
	[task error:@"User cancelled" type:@"EXPECTED_FAILURE" subtype:nil];
	// "release"
	me = nil;
	fb = nil;
}

@end
