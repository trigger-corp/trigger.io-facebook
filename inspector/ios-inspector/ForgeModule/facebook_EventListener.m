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

+ (void) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [FBSettings setDefaultAppID:[[[ForgeApp sharedApp] configForPlugin:@"facebook"] objectForKey:(@"appid")]];
}


+ (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBAppCall handleDidBecomeActive];
}


+ (NSNumber*)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	if ([FBAppCall handleOpenURL:url sourceApplication:sourceApplication]) {
		return @YES;
	} else {
		return nil;
	}
}

@end
