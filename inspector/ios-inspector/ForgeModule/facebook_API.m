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
#import "facebook_LoginDelegate.h"
#import "facebook_DialogDelegate.h"
#import "facebook_RequestDelegate.h"
#import "facebook_Util.h"

@implementation facebook_API


+ (void)authorize:(ForgeTask*)task permissions:(NSArray*)permissionsArray audience:(NSString*)audience dialog:(NSNumber*)showDialog {
	[facebook_Util partnerProgram];
	
    BOOL loginUI = showDialog.boolValue;
    LoginContext *context = [[LoginContext alloc] initWithTask:task permissions:permissionsArray audience:audience loginUI:loginUI];
    
    [facebook_LoginDelegate handleLogin:context];
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
    
    [FBRequestConnection startWithGraphPath:path parameters:params HTTPMethod:method completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            [task success:result];
        } else {
            [facebook_Util handleError:error task:task closeSession:false];
        }
    }];
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
	facebook.accessToken = FBSession.activeSession.accessTokenData.accessToken;
	facebook.expirationDate = FBSession.activeSession.accessTokenData.expirationDate;
	facebook_DialogDelegate *delegate = [[facebook_DialogDelegate alloc] initWithTask:task andFacebook:facebook];
	[facebook dialog:method andParams:paramsDict andDelegate:delegate];
}


+ (void)share:(ForgeTask*)task url:(NSString*)url {

	FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
	params.link = [NSURL URLWithString:url];

	if ([FBDialogs canPresentShareDialogWithParams:params]) {
		[FBDialogs presentShareDialogWithLink:params.link
									  handler:^(FBAppCall *call, NSDictionary *results, NSError *error) {
										  if(error) {
											  [task error:[facebook_Util checkErrorMessage:error]];
										  } else {
											  NSMutableDictionary *taskResult = [[NSMutableDictionary alloc] init];
											  [taskResult setValue:@"NativeShareDialog" forKey:@"type"];

											  // the completionGesture will only be returned if the user authed with the FB app once before
											  if (results[@"completionGesture"] &&
												  [results[@"completionGesture"] isEqualToString:@"cancel"]) {
												  // User cancelled.
												  [taskResult setValue:[NSNumber numberWithBool:YES] forKey:@"cancelled"];
											  }

											  [task success:taskResult];
										  }
									  }];
	} else if ([FBDialogs canPresentOSIntegratedShareDialogWithSession:nil]) {
		[FBDialogs
		 presentOSIntegratedShareDialogModallyFrom:[[ForgeApp sharedApp] viewController]
		 initialText:nil
		 image:nil
		 url:params.link
		 handler:^(FBOSIntegratedShareDialogResult result, NSError *error) {
			 if (error) {
				 [task error:[facebook_Util checkErrorMessage:error]];
			 } else {
				 NSMutableDictionary *taskResult = [[NSMutableDictionary alloc] init];
				 [taskResult setValue:@"OSIntegratedShareDialog" forKey:@"type"];

				 if (result == FBOSIntegratedShareDialogResultCancelled) {
					 // User cancelled.
					 [taskResult setValue:[NSNumber numberWithBool:YES] forKey:@"cancelled"];
				 }

				 [task success:taskResult];
			 }
		 }];
	} else {
		NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
		[params setObject:url forKey:@"link"];

		[FBWebDialogs presentFeedDialogModallyWithSession:nil
											   parameters:params
												  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
													  if (error) {
														  [task error:[facebook_Util checkErrorMessage:error]];
													  } else {
														  NSMutableDictionary *taskResult = [[NSMutableDictionary alloc] init];
														  [taskResult setValue:@"WebShareDialog" forKey:@"type"];

														  if (result == FBWebDialogResultDialogNotCompleted) {
															  // User cancelled.
															  [taskResult setValue:[NSNumber numberWithBool:YES] forKey:@"cancelled"];
														  } else {
															  NSDictionary *urlParams = [facebook_Util parseURLParams:[resultURL query]];

															  if (![urlParams valueForKey:@"post_id"]) {
																  // User cancelled.
																  [taskResult setValue:[NSNumber numberWithBool:YES] forKey:@"cancelled"];
															  }
														  }

														  [task success:taskResult];
													  }
												  }];
	}
}


+ (void)installed:(ForgeTask*)task {
    // see approach below if we're getting false positives
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://profile"]]) {
		[task success:[NSNumber numberWithBool:true]];
	} else {
		[task success:[NSNumber numberWithBool:false]];
	}
	/*
	FBLinkShareParams *params = [[FBLinkShareParams alloc] init];
	params.link = [NSURL URLWithString:@"https://trigger.io"];
	if ([FBDialogs canPresentShareDialogWithParams:params]) {
		[task success:[NSNumber numberWithBool:YES]];
	} else {
		[task success:[NSNumber numberWithBool:NO]];
	}
	*/
}


+ (void)enablePlatformCompatibility:(ForgeTask*)task {
	// WARNING: This will probably stop working after December 25
	[FBSettings enablePlatformCompatibility:true];
	[task success:[NSNumber numberWithBool:YES]];
}


@end
