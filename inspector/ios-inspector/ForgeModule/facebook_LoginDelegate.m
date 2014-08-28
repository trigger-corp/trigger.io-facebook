//
//  facebook_Login.m
//  ForgeModule
//
//  Created by Antoine van Gelder on 2014/04/01.
//  Copyright (c) 2014 Trigger Corp. All rights reserved.
//

#import "facebook_Util.h"
#import "facebook_LoginDelegate.h"


@implementation LoginContext
- (LoginContext*) initWithTask:(ForgeTask*)newTask permissions:(NSArray*)newPermissions audience:(NSString*)newAudience loginUI:(BOOL)newLoginUI {
    if (self = [super init]) {
        _task = newTask;
        _permissions = newPermissions;
        _audience = newAudience;
        _loginUI = newLoginUI;
        _isRequestingPublishPermissions = false;
    }
    return self;
}
@end



@implementation facebook_LoginDelegate

+ (void)handleLogin:(LoginContext*)context {
    // [ForgeLog d:[NSString stringWithFormat:@"facebook_Login.handleLogin: %d", FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded]];
    BOOL loggedinWithoutUI = false;
    
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        loggedinWithoutUI = [self openActiveSession:NO context:context];
        if (!loggedinWithoutUI && context.loginUI) {
            loggedinWithoutUI = [self openActiveSession:YES context:context];
        } else if (!loggedinWithoutUI && !context.loginUI) {
            [context.task error:@"User not logged in or insufficient read permissions" type:@"EXPECTED_FAILURE" subtype:nil];
            return;
        }
    } else {
        if (context.loginUI) {
            loggedinWithoutUI = [self openActiveSession:YES context:context];
        } else {
            loggedinWithoutUI = [self openActiveSession:NO context:context];
            if (!loggedinWithoutUI) {
                [context.task error:@"User not logged in or insufficient read permissions" type:@"EXPECTED_FAILURE" subtype:nil];
                return;
            }
        }
    }
}


+ (BOOL) openActiveSession:(BOOL)allowLoginUI context:(LoginContext*)context {
    NSArray *readPermissions = [facebook_Util readPermissionsInPermissions:context.permissions];
    BOOL loggedinWithoutUI = [FBSession openActiveSessionWithReadPermissions:readPermissions allowLoginUI:allowLoginUI completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        [self sessionStateChanged:session state:state error:error context:context];
    }];
    return loggedinWithoutUI;
}


+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error context:(LoginContext*)context {
    //[ForgeLog d:[NSString stringWithFormat:@"facebook_Login.sessionStateChanged: %@ %@ -> %@ -> %@ -> %@", [self ParseState:session.state], error ? error : @"SUCCESS", context.permissions, session.permissions, FBSession.activeSession.permissions]];
    
    if (error) {
        return [facebook_Util handleError:error task:context.task];
    }
    
    switch (state) {
        case FBSessionStateOpen:
        case FBSessionStateOpenTokenExtended:
            if (context.isRequestingPublishPermissions) {
                // busy requesting publish permissions, ignore
                
            } else if (![self checkReadPermissions:context]) {
                // failed asking for read permissions, send error and abort
                NSArray *readPermissions = [facebook_Util readPermissionsInPermissions:context.permissions];
                NSArray *missingPermissions = [facebook_Util missingPermissionsInGrantedPermissions:session.permissions requestedPermissions:readPermissions];
                NSString *message = [NSString stringWithFormat:@"Request for read permissions: '%@' failed for: '%@'",
                                     [readPermissions componentsJoinedByString:@", "], [missingPermissions componentsJoinedByString:@", "]];
                [ForgeLog d:message];
                [context.task error:message];
                
            } else if (![self checkPublishPermissions:context]) {
                // need publish perms
                context.isRequestingPublishPermissions = true;
                dispatch_async(dispatch_get_current_queue(), ^(void) {
                    [self requestNewPublishPermissions:session context:context];
                });
                
            } else {
                // only needed read perms, success
                [context.task success:[self AccessToken:FBSession.activeSession]];
            }
            break;
            
        case FBSessionStateClosed:
            [context.task error:@"Session closed" type:@"EXPECTED_FAILURE" subtype:nil];
            break;
        case FBSessionStateClosedLoginFailed:
            [session closeAndClearTokenInformation];
            [context.task error:@"Login failed" type:@"EXPECTED_FAILURE" subtype:nil];
            break;
        default:
            [context.task error:[NSString stringWithFormat:@"Unknown error: %@", [self ParseState:session.state]] type:@"UNEXPECTED_FAILURE" subtype:nil];
            break;
    }
    
    
}


+ (void)requestNewPublishPermissions:(FBSession*) session context:(LoginContext*)context {
    
    NSArray *publishPermissions = [facebook_Util publishPermissionsInPermissions:context.permissions];
    FBSessionDefaultAudience publishAudience = [facebook_Util lookupAudience:context.audience];
    
    [ForgeLog d:[NSString stringWithFormat:@"Requesting new publish permissions: %@", publishPermissions]];
    
    [session requestNewPublishPermissions:publishPermissions defaultAudience:publishAudience completionHandler:^(FBSession *session, NSError *error) {
        
        //[ForgeLog d:[NSString stringWithFormat:@"facebook_Login.requestNewPublishPermissions: %@ %@ -> %@ -> %@ -> %@", [self ParseState:session.state], error ? error : @"SUCCESS", context.permissions, session.permissions, FBSession.activeSession.permissions]];
        
        // TODO failing here on iOS 8 with: com.facebook.sdk:ErrorReauthorizeFailedReasonUserCancelled
        
        if (![self checkPublishPermissions:context]) {
            //context.invalidPublishPermissions = true;
            NSArray *publishPermissions = [facebook_Util publishPermissionsInPermissions:context.permissions];
            NSArray *missingPermissions = [facebook_Util missingPermissionsInGrantedPermissions:session.permissions requestedPermissions:publishPermissions];
            NSString *message = [NSString stringWithFormat:@"Request for publish permissions: '%@' failed for: '%@'",
                                 [publishPermissions componentsJoinedByString:@", "], [missingPermissions componentsJoinedByString:@", "]];
            [ForgeLog d:message];
            [context.task error:message];
        } else {
            [context.task success:[self AccessToken:FBSession.activeSession]];
        }
    }];
}


+ (BOOL)checkReadPermissions:(LoginContext*)context {
    NSArray *readPermissions = [facebook_Util readPermissionsInPermissions:context.permissions];
    //NSLog(@"checkReadPermissions -> %@ -> %@", readPermissions, FBSession.activeSession.permissions);
    return [facebook_Util permissionsAllowedByPermissions:FBSession.activeSession.permissions requestedPermissions:readPermissions];
}


+ (BOOL)checkPublishPermissions:(LoginContext*)context {
    NSArray *publishPermissions = [facebook_Util publishPermissionsInPermissions:context.permissions];
    //NSLog(@"checkPublishPermissions -> %@ -> %@", publishPermissions, FBSession.activeSession.permissions);
    return [facebook_Util permissionsAllowedByPermissions:FBSession.activeSession.permissions requestedPermissions:publishPermissions];
}


+ (NSDictionary*)AccessToken:(FBSession*)session {
    return @{
        @"access_token": [NSString stringWithFormat:@"%@", session.accessTokenData.accessToken],
        @"access_expires": [NSNumber numberWithDouble:round([session.accessTokenData.expirationDate timeIntervalSince1970] * 1000.0)]
    };
}


+ (NSString*)ParseState:(FBSessionState)state {
    switch (state) {
        case FBSessionStateOpen:
            return @"FBSessionStateOpen";
        case FBSessionStateClosed:
            return @"FBSessionStateClosed";
        case FBSessionStateClosedLoginFailed:
            return @"FBSessionStateClosedLoginFailed";
        case FBSessionStateCreated:
            return @"FBSessionStateCreated";
        case FBSessionStateCreatedOpening:
            return @"FBSessionStateCreatedOpening";
        case FBSessionStateCreatedTokenLoaded:
            return @"FBSessionStateCreatedTokenLoaded";
        case FBSessionStateOpenTokenExtended:
            return @"FBSessionStateOpenTokenExtended";
        default:
            return @"FBSessionStateUnknown";
    }
}


@end
