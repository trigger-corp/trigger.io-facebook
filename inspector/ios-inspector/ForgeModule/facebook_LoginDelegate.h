//
//  facebook_Login.h
//  ForgeModule
//
//  Created by Antoine van Gelder on 2014/04/01.
//  Copyright (c) 2014 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"


@interface LoginContext : NSObject
@property ForgeTask *task;
@property NSArray *permissions;
@property NSString *audience;
@property BOOL loginUI;
- (LoginContext*) initWithTask:(ForgeTask*)newTask permissions:(NSArray*)newPermissions audience:(NSString*)newAudience loginUI:(BOOL)newLoginUI;
@end


@interface facebook_LoginDelegate : NSObject
+ (void) handleLogin:(LoginContext*)context;
+ (void) requestNewPublishPermissions:(FBSession *)session context:(LoginContext*)context;
+ (void) sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error context:(LoginContext*)context;
+ (BOOL) checkPublishPermissions:(LoginContext*)context;
+ (NSDictionary*) AccessToken:(FBSession*)session;
+ (NSString*) ParseState:(FBSessionState)state;
@end
