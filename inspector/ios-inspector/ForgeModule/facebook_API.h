//
//  facebook_API.h
//  Forge
//
//  Created by Connor Dunn on 11/07/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface facebook_API : NSObject

+ (void)authorize:(ForgeTask*)task permissions:(NSArray*)permissionsArray audience:(NSString*)audience dialog:(NSNumber*)showDialog;
+ (void)logout:(ForgeTask*)task;
+ (void)api:(ForgeTask*)task path:(NSString*)path method:(NSString*)method params:(NSDictionary*)params;
+ (void)ui:(ForgeTask*)task;
+ (void)installed:(ForgeTask*)task;

@end
