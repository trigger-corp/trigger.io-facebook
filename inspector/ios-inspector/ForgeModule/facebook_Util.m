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
		
		NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
		
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

+ (BOOL)permissionsRequirePublish:(NSArray*)permissions {
	return [[facebook_Util publishPermissionsInPermissions:permissions] count] > 0;
}



+(NSArray*)readPermissionsInPermissions:(NSArray*)permissions {
	// Currently documented at https://developers.facebook.com/docs/howtos/ios-6/
	NSArray *publishPermissions = @[@"ads_management", @"create_event", @"rsvp_event", @"manage_friendlists", @"manage_notifications", @"manage_pages", @"publish_actions"];
	NSIndexSet *publishIndexes = [permissions indexesOfObjectsPassingTest:^BOOL(NSString *permission, NSUInteger idx, BOOL *stop) {
		return ![publishPermissions containsObject:permission];
	}];
	
	return [permissions objectsAtIndexes:publishIndexes];
}

+(NSArray*)publishPermissionsInPermissions:(NSArray*)permissions {
	// Currently documented at https://developers.facebook.com/docs/howtos/ios-6/
	NSArray *publishPermissions = @[@"ads_management", @"create_event", @"rsvp_event", @"manage_friendlists", @"manage_notifications", @"manage_pages", @"publish_actions"];
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
			stop = YES;
		}
	}];
	return result;
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

@end
