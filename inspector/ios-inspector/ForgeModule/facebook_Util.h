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
+ (BOOL)permissionsRequirePublish:(NSArray*)permissions;
+(NSArray*)readPermissionsInPermissions:(NSArray*)permissions;
+(NSArray*)publishPermissionsInPermissions:(NSArray*)permissions;
+(BOOL)permissionsAllowedByPermissions:(NSArray*)permissions requestedPermissions:(NSArray*)requestedPermissions;
+ (FBSessionDefaultAudience)lookupAudience:(NSString*)audience;

@end
