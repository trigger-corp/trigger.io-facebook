//
//  facebook_EventListener.m
//  Forge
//
//  Created by Connor Dunn on 12/07/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "facebook_EventListener.h"
#import "Facebook.h"

@implementation facebook_EventListener

+ (void) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {	    [FBSession setDefaultAppID:[[[ForgeApp sharedApp] configForPlugin:@"facebook"] objectForKey:(@"appid")]];
}

+ (NSNumber*)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	if ([FBSession.activeSession handleOpenURL:url]) {
		return @YES;
	} else {
		return nil;
	}
}

+ (NSNumber*)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	if ([FBSession.activeSession handleOpenURL:url]) {
		return @YES;
	} else {
		return nil;
	}
}


@end
