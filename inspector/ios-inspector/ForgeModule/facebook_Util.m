//
//  facebook_Util.m
//  ForgeTemplate
//
//  Created by James Brady on 13/10/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import "facebook_Util.h"

static BOOL partnerProgramNotified = NO;

@implementation facebook_Util

+ (void) partnerProgram {
	if (!partnerProgramNotified) {
		partnerProgramNotified = YES;
		
		NSString* appid = [[[ForgeApp sharedApp] configForPlugin:@"facebook"] objectForKey:@"appid"];
		NSString* platformVersion = [[[ForgeApp sharedApp] appConfig] objectForKey:@"platform_version"];
		
		if (!platformVersion) {
			return;
		}

		NSString *post = [NSString stringWithFormat:@"plugin=featured_resources&payload=%@", [@{
			@"resource": @"triggerio_triggerio",
			@"appid": appid,
			@"version": platformVersion
		} JSONString]];
		NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		
		NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postData length]];
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:@"https://www.facebook.com/impression.php"]];
		[request setHTTPMethod:@"POST"];
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];

		[NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
			if (!error) {
				[ForgeLog w:@"Error reporting partner data to Facebook"];
			}
		}];
	}

}


/**
 * From: https://developers.facebook.com/docs/facebook-login/permissions/v2.0#reference
 */
+ (NSArray *)publishPermissions {
    static NSArray *_publishPermissions;
    static dispatch_once_t _publishPermissionsOnce;
    dispatch_once(&_publishPermissionsOnce, ^{
        _publishPermissions = @[@"ads_management", @"create_event", @"rsvp_event", @"manage_friendlists", @"manage_notifications", @"manage_pages", @"publish_actions"];
    });
    return _publishPermissions;
}


+(NSArray*)readPermissionsInPermissions:(NSArray*)permissions {
    NSArray *publishPermissions = [[self class] publishPermissions];
	NSIndexSet *publishIndexes = [permissions indexesOfObjectsPassingTest:^BOOL(NSString *permission, NSUInteger idx, BOOL *stop) {
		return ![publishPermissions containsObject:permission];
	}];
	return [permissions objectsAtIndexes:publishIndexes];
}


+(NSArray*)publishPermissionsInPermissions:(NSArray*)permissions {
    NSArray *publishPermissions = [[self class] publishPermissions];
	NSIndexSet *publishIndexes = [permissions indexesOfObjectsPassingTest:^BOOL(NSString *permission, NSUInteger idx, BOOL *stop) {
		return [publishPermissions containsObject:permission];
	}];
	return [permissions objectsAtIndexes:publishIndexes];
}


+(BOOL)permissionsAllowedByPermissions:(NSArray*)permissions requestedPermissions:(NSArray*)requestedPermissions {
	__block BOOL result = YES;
	[requestedPermissions enumerateObjectsUsingBlock:^(NSString *permission, NSUInteger idx, BOOL *stop) {
		if ([permissions indexOfObject:permission] == NSNotFound) {
			result = NO;
			*stop = YES;
            [ForgeLog d:[NSString stringWithFormat:@"Require Facebook permission: %@", permission]];
		}
	}];
	return result;
}


+(NSArray*)missingPermissionsInGrantedPermissions:(NSArray*)grantedPermissions requestedPermissions:(NSArray*)requestedPermissions {
    NSIndexSet *missingIndices = [requestedPermissions indexesOfObjectsPassingTest:^BOOL(NSString *permission, NSUInteger idx, BOOL *stop) {
        return ![grantedPermissions containsObject:permission];
    }];
    return [requestedPermissions objectsAtIndexes:missingIndices];
}


+ (FBSessionDefaultAudience)lookupAudience:(NSString*)audience {
	if ([@"everyone" isEqualToString:audience]) {
		return FBSessionDefaultAudienceEveryone;
	} else if ([@"friends" isEqualToString:audience]) {
		return FBSessionDefaultAudienceFriends;
	} else if ([@"only_me" isEqualToString:audience]) {
		return FBSessionDefaultAudienceOnlyMe;
	} else if ([@"none" isEqualToString:audience]) {
		return FBSessionDefaultAudienceNone;
	} else {
		return FBSessionDefaultAudienceFriends;
	}
}


+ (void)handleError:(NSError *)error task:(ForgeTask*)task {
    [facebook_Util handleError:error task:task closeSession:true];
}


+ (void)handleError:(NSError *)error task:(ForgeTask*)task closeSession:(BOOL)closeSession {
    //[ForgeLog d:[NSString stringWithFormat:@"facebook_Util.handleError: %@", error]];
    
    if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
        [task error:@"User cancelled login" type:@"EXPECTED_FAILURE" subtype:nil];
    } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
        [task error:@"Your current session is no longer valid. Please log in again."];
    } else {
        NSDictionary *parsedError = [facebook_Util ParseFacebookError:error];
        if (parsedError) {
            [task error:parsedError];
        } else {
            [task error:[NSString stringWithFormat:@"Unknown error: %@", error] type:@"UNEXPECTED_FAILURE" subtype:nil];
        }
    }
    
    if (closeSession) {
        [FBSession.activeSession closeAndClearTokenInformation];
    }
}


+ (NSDictionary*) ParseFacebookError:(NSError*)error {
    if (error == nil || [error userInfo] == nil) {
        return nil;
    }
    
    id err = [error userInfo] [@"com.facebook.sdk:ParsedJSONResponseKey"];
    //[ForgeLog d:[NSString stringWithFormat:@"ParseFacebookError response class: %@ -> %@", NSStringFromClass([err class]), err]];
    
    if ([err isKindOfClass:[NSDictionary class]]) {
        // sanity
    } else if (![err respondsToSelector:NSSelectorFromString(@"objectForKey:")] && [err isKindOfClass:[NSArray class]]) {
        err = [err objectAtIndex:0];
    } else {
        [ForgeLog d:@"ParseFacebookError: Couldn't parse com.facebook.sdk:ParsedJSONResponseKey"];
        return [error userInfo];
    }
    if (err [@"body"] [@"error"] != nil) {
        err = err [@"body"] [@"error"];
    } else if (err [@"error"] != nil) {
        err = err [@"error"];
    } else {
        err = [error userInfo];
    }
    return err;
};


@end
