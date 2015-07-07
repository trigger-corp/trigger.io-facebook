//
//  facebook_Util.h
//  ForgeTemplate
//
//  Created by James Brady on 13/10/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"

@interface facebook_Util : NSObject

+ (void) partnerProgram;
+(NSArray*)readPermissionsInPermissions:(NSArray*)permissions;
+(NSArray*)publishPermissionsInPermissions:(NSArray*)permissions;
+(BOOL)permissionsAllowedByPermissions:(NSArray*)permissions requestedPermissions:(NSArray*)requestedPermissions;
+(NSArray*)missingPermissionsInGrantedPermissions:(NSArray*)grantedPermissions requestedPermissions:(NSArray*)requestedPermissions;
+ (FBSessionDefaultAudience)lookupAudience:(NSString*)audience;
+ (void)handleError:(NSError *)error task:(ForgeTask*)task;
+ (void)handleError:(NSError *)error task:(ForgeTask*)task closeSession:(BOOL)closeSession;
+ (NSDictionary*)parseURLParams:(NSString *)query;
+ (NSString *)checkErrorMessage:(NSError *)error;
@end
