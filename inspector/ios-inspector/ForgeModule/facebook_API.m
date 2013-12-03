//
//  facebook_API.m
//  Forge
//
//  Created by Connor Dunn on 11/07/2012.
//  Copyright (c) 2012 Trigger Corp. All rights reserved.
//

#import <Accounts/Accounts.h>
#import "facebook_API.h"
#import "Facebook.h"
#import "facebook_DialogDelegate.h"
#import "facebook_RequestDelegate.h"
#import "facebook_Util.h"

@implementation facebook_API

+ (void)authorize:(ForgeTask*)task permissions:(NSArray*)permissionsArray audience:(NSString*)audience dialog:(NSNumber*)showDialog {
	[facebook_Util partnerProgram];

    __block BOOL returned = NO;
	BOOL loginUI = showDialog.boolValue;
	
	void (^publishHandler)(FBSession*, NSError*) = ^(FBSession *session, NSError *error) {
//		[ForgeLog d:[NSString stringWithFormat:@"publishHander: %u %@", session.state, error]];

		if (error) {
			[task error:[NSString stringWithFormat:@"%@ - %@", error.localizedDescription, error.userInfo]
				   type:@"UNEXPECTED_FAILURE"
				subtype:nil];
			return;
		} else {
			[task success:
			 @{@"access_token": session.accessToken,
			 @"access_expires": [NSNumber numberWithDouble:round([session.expirationDate timeIntervalSince1970]*1000.0)]
			 }];
			return;
		}
	};
	
	void (^readHandler)(FBSession*, FBSessionState, NSError*) = ^(FBSession *session, FBSessionState status, NSError *error) {
//		[ForgeLog d:[NSString stringWithFormat:@"readHandler: %u %@", session.state, error]];
		if (returned) return;
		returned = YES;
		
		switch (status) {
			case FBSessionStateOpen:
				if ([facebook_Util permissionsRequirePublish:permissionsArray]) {
					// need to re-auth to get publish permissions too
					[session reauthorizeWithPublishPermissions:[facebook_Util publishPermissionsInPermissions:permissionsArray]
											   defaultAudience:[facebook_Util lookupAudience:audience]
											 completionHandler:publishHandler];
				} else {
					[task success:
					 @{@"access_token": session.accessToken,
					 @"access_expires": [NSNumber numberWithDouble:round([session.expirationDate timeIntervalSince1970]*1000.0)]
					 }];
				}
				return;
			case FBSessionStateClosed:
			case FBSessionStateClosedLoginFailed:
				[session closeAndClearTokenInformation];
				[task error:@"Login failed" type:@"EXPECTED_FAILURE" subtype:nil];
				break;
			default:
				[task error:[NSString stringWithFormat:@"Unknown error: %@", error] type:@"UNEXPECTED_FAILURE" subtype:nil];
				break;
		}
		
	};
	
	if ([FBSession openActiveSessionWithReadPermissions:[facebook_Util readPermissionsInPermissions:permissionsArray]
										   allowLoginUI:NO
									  completionHandler:nil]) {
//		[ForgeLog d:[NSString stringWithFormat:@"found a valid FB session with permissions %@", FBSession.activeSession.permissions]];
		// active session is valid, and all read permissions already authorized
		// any requested publish actions might not be authorized yet, however
		if ([facebook_Util permissionsAllowedByPermissions:FBSession.activeSession.permissions requestedPermissions:permissionsArray]) {
			// valid session AND all requested permissions already allowed
//			[ForgeLog d:[NSString stringWithFormat:@"re-using existing valid Facebook session for %@", permissionsArray]];
			[task success:@{@"access_token": FBSession.activeSession.accessToken,
			 @"access_expires": [NSNumber numberWithDouble:round([FBSession.activeSession.expirationDate timeIntervalSince1970]*1000.0)]
			 }];
		} else {
			// already authorized session doesn't have sufficient permissions
			if (loginUI) {
//				[ForgeLog d:@"requested permissions have changed: re-authorizing"];
				[FBSession.activeSession reauthorizeWithPublishPermissions:[facebook_Util publishPermissionsInPermissions:permissionsArray]
														   defaultAudience:[facebook_Util lookupAudience:audience]
														 completionHandler:publishHandler];
			} else {
				[task error:@"User logged in but insufficient permissions" type:@"EXPECTED_FAILURE" subtype:nil];
			}
		}
	} else {
//		[ForgeLog d:@"no valid FB session found"];
		if (loginUI) {
			[FBSession openActiveSessionWithReadPermissions:[facebook_Util readPermissionsInPermissions:permissionsArray]
											   allowLoginUI:YES
										  completionHandler:readHandler];
		} else {
			[task error:@"User not logged in or insufficient read permissions" type:@"EXPECTED_FAILURE" subtype:nil];
		}
	}
}

+ (void)logout:(ForgeTask*)task {
	[facebook_Util partnerProgram];

	[FBSession.activeSession closeAndClearTokenInformation];
	
	BOOL isACAccountTypeIdentifierFacebookAvailable = (&ACAccountTypeIdentifierFacebook != NULL);
	
	if (isACAccountTypeIdentifierFacebookAvailable) {
		ACAccountStore *accountStore;
		ACAccountType *accountTypeFB;
		if ((accountStore = [[ACAccountStore alloc] init]) &&
			(accountTypeFB = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook] ) ){
			
			NSArray *fbAccounts = [accountStore accountsWithAccountType:accountTypeFB];
			id account;
			if (fbAccounts && [fbAccounts count] > 0 &&
				(account = [fbAccounts objectAtIndex:0])){
				
				[accountStore renewCredentialsForAccount:account completion:^(ACAccountCredentialRenewResult renewResult, NSError *error) {
					[task success:nil];
				}];
				return;
			}
		}
	}

	[task success:nil];
}

+ (void)api:(ForgeTask*)task path:(NSString*)path method:(NSString*)method params:(NSDictionary*)params {
	[facebook_Util partnerProgram];
	
	Facebook* facebook = [[Facebook alloc]
					 initWithAppId:FBSession.activeSession.appID
					 andDelegate:nil];
	
	facebook.accessToken = FBSession.activeSession.accessToken;
	facebook.expirationDate = FBSession.activeSession.expirationDate;
	
	facebook_RequestDelegate *delegate = [[facebook_RequestDelegate alloc] initWithTask:task andFacebook:facebook];
	
	[facebook requestWithGraphPath:path andParams:[NSMutableDictionary dictionaryWithDictionary:params] andHttpMethod:method andDelegate:delegate];
}

+ (void)ui:(ForgeTask*)task {
	[facebook_Util partnerProgram];
	
	NSString *method = nil;
	NSMutableDictionary *paramsDict = [[NSMutableDictionary alloc] init];
	for (NSString *key in task.params) {
		if ([key isEqualToString:@"method"]) {
			method = [task.params objectForKey:@"method"];
		} else {
			[paramsDict setValue:[task.params objectForKey:key] forKey:key];
		}
	}
	
	if (method == nil) {
		[task error:@"facebook.ui required a method" type:@"BAD_INPUT" subtype:nil];
		return;
	}
	
	Facebook* facebook = [[Facebook alloc]
						  initWithAppId:FBSession.activeSession.appID
						  andDelegate:nil];
	
	facebook.accessToken = FBSession.activeSession.accessToken;
	facebook.expirationDate = FBSession.activeSession.expirationDate;
	
	facebook_DialogDelegate *delegate = [[facebook_DialogDelegate alloc] initWithTask:task andFacebook:facebook];
	
	[facebook dialog:method andParams:paramsDict andDelegate:delegate];
	
}

@end
