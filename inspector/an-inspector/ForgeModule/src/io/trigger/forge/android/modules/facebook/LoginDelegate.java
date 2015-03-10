package io.trigger.forge.android.modules.facebook;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeLog;

import java.util.List;

import com.facebook.FacebookAuthorizationException;
import com.facebook.FacebookDialogException;
import com.facebook.FacebookException;
import com.facebook.FacebookGraphObjectException;
import com.facebook.FacebookOperationCanceledException;
import com.facebook.FacebookRequestError;
import com.facebook.FacebookServiceException;
import com.facebook.Session;
import com.facebook.SessionLoginBehavior;
import com.facebook.SessionState;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonPrimitive;


public class LoginDelegate {

	public static void handleLogin(LoginContext context) {
		String applicationId = ForgeApp.configForPlugin("facebook").get("appid").getAsString();
		boolean loggedInWithoutUI = false;

		Session session = new Session.Builder(ForgeApp.getActivity().getApplicationContext()).setApplicationId(applicationId).build();
		Session.setActiveSession(session);		
		/*ForgeLog.d("handleLogin built session: " + session + " -> " + (session != null ? session.getState() : "NULL"));
		ForgeLog.d("HandleLogin Session info: " +
				" -> closed." + session.isClosed() +
				" -> opened." + session.isOpened() +
				" -> " + session.getState());*/

		if (context.dialog == false) { // hasAuthorized
			if (session == null || session.getState() != SessionState.CREATED_TOKEN_LOADED) {
				context.task.error("User not authorized", "EXPECTED_FAILURE", null);
				return;
			}
		} else { // authorize
			/*if (session.getState() == SessionState.CREATED_TOKEN_LOADED) {
				// is there a way to check that this is, in fact, valid?
				ForgeLog.d("I THINK THIS IS A VALID SESSION");
				ForgeLog.d("Read Permissions: " + checkReadPermissions(session, context));
				ForgeLog.d("Publish Permissions: " + checkPublishPermissions(session, context));
			}*/
		}

		// Is facebook correctly caching logins now?
		/*final SharedPreferences prefs = Util.getStorage(task);
		String access_token = prefs.getString("access_token", null);
		long expires = prefs.getLong("access_expires", 0);
		if (access_token != null) {
			facebook.setAccessToken(access_token);
		}
		if (expires != 0) {
			facebook.setAccessExpires(expires);
		}*/

		if (session != null && session.getState() == SessionState.CREATED_TOKEN_LOADED) {
			//ForgeLog.d("handleLogin #1 have an existing session with a loaded token");
			loggedInWithoutUI = openActiveSession(session, false, context);
			if (loggedInWithoutUI) {
				//ForgeLog.d("handleLogin #1 success without dialog");
				return;
			} else if (context.dialog) {
				//ForgeLog.d("handleLogin #1 trying with dialog");
				loggedInWithoutUI = openActiveSession(session, true, context);
			} else {
				context.task.error("User not logged in to new session or insuficient permissions", "EXPECTED_FAILURE", null);
				return;
			}
		} else {
			//ForgeLog.d("handleLogin #2 need to create session from scratch");
			if (context.dialog) {
				//ForgeLog.d("handleLogin #2 with dialog");
				openActiveSession(session, true, context);
			} else {
				//ForgeLog.d("handleLogin #2 without dialog");
				loggedInWithoutUI = openActiveSession(session, false, context);
				if (!loggedInWithoutUI) {
					//ForgeLog.e("this was a hasAuthorized call that failed");
					context.task.error("User not logged in to existing session or insufficient permissions", "EXPECTED_FAILURE", null);
					return;
				} else {
					//ForgeLog.e("this was a hasAuthorized call that succeeded");
				}
			}
		}
	}

	private static boolean openActiveSession(Session session, boolean dialog, final LoginContext context) {
		/*ForgeLog.d("openActiveSession: " + dialog +
				" -> " + session.isClosed() +
				" -> " + session.isOpened() +
				" -> " + session.getState());*/
		List<String> readPermissions = Util.readPermissionsInPermissions(context.permissions);
		Session.OpenRequest openRequest = new Session.OpenRequest(ForgeApp.getActivity());
		openRequest.setCallback(new SessionStatusCallback(context));
		openRequest.setPermissions(readPermissions);
		if (!context.dialog) {
			openRequest.setLoginBehavior(SessionLoginBehavior.SSO_ONLY);
		}
		session.openForRead(openRequest);
		boolean ret = session.isOpened() && (session.getState() == SessionState.OPENED);
		/*ForgeLog.d("openActiveSession ret: " + dialog +
				" -> " + session.isClosed() +
				" -> " + session.isOpened() +
				" -> " + session.getState() +
				" -> " + ret);*/
		return ret;
	}

	private static void sessionStateChanged(Session session, SessionState state, Exception exception, LoginContext context) {
		/*ForgeLog.d("sessionStateChanged: " + state +
				" -> " + (exception == null ? "SUCCESS" : exception) +
				" -> " + context.permissions +
				" -> " + session.getPermissions() +
				" -> " + Session.getActiveSession().getPermissions());*/

		/*if (state.isOpened()) {
			ForgeLog.i("NEW - Logged in");
		} else if (state.isClosed()) {
			ForgeLog.i("NEW - Logged out");
		}*/

		if (state == SessionState.CLOSED_LOGIN_FAILED) {
			context.task.error("User login failed", "EXPECTED_FAILURE", null);
			return;

		} else if (exception != null) {
			handleStatusCallbackException(exception, context);

		} else if (state == SessionState.OPENED) {
			if (!checkPublishPermissions(session, context)) {
				ForgeLog.d("Requesting additional publish permissions");
				requestNewPublishPermissions(session, context);
			} else {
				//ForgeLog.d("Got all the permissions, I think we're good to go");
				context.task.success(AuthResponse(session, context));
			}

		} else if (state == SessionState.OPENED_TOKEN_UPDATED) { // gets invoked after requestNewPublishPermissions
			/*if (!checkPublishPermissions(session, context)) {
				ForgeLog.d("I don't think we got everything but its probably okay");
			}
			ForgeLog.d("Asked for publish permissions and now I think we're good to go");*/
			context.task.success(AuthResponse(session, context));

		} else {
			ForgeLog.i("STATE NOT HANDLED");
		}
	}

	private static void requestNewPublishPermissions(Session session, LoginContext context) {
		List<String> publishPermissions = Util.publishPermissionsInPermissions(context.permissions);
		Session.NewPermissionsRequest newPermissionsRequest = new Session.NewPermissionsRequest(ForgeApp.getActivity(), publishPermissions);
		session.requestNewPublishPermissions(newPermissionsRequest);
	}

	private static boolean checkReadPermissions(Session session, LoginContext context) {
		List<String> publishPermissions = Util.readPermissionsInPermissions(context.permissions);
		return Util.grantedPermissionsAreSuperset(session.getPermissions(), publishPermissions);
	}
	
	private static boolean checkPublishPermissions(Session session, LoginContext context) {
		List<String> publishPermissions = Util.publishPermissionsInPermissions(context.permissions);
		return Util.grantedPermissionsAreSuperset(session.getPermissions(), publishPermissions);
	}

	private static JsonObject AuthResponse(Session session, LoginContext context) {
		// Is facebook correctly caching logins now?
		/*final SharedPreferences prefs = Util.getStorage(context.task);
		SharedPreferences.Editor editor = prefs.edit();
		editor.putString("access_token", session.getAccessToken());
		editor.putLong("access_expires", session.getExpirationDate().getTime());
		editor.commit();*/

		JsonObject response = new JsonObject();
		response.addProperty("access_token", session.getAccessToken());
		response.addProperty("access_expires", session.getExpirationDate().getTime());
		JsonArray granted = new JsonArray();
		for (String permission : session.getPermissions()) {
			granted.add(new JsonPrimitive(permission));
		}
		response.add("granted", granted);
		JsonArray denied = new JsonArray();
		for (String permission : session.getDeclinedPermissions()) {
			granted.add(new JsonPrimitive(permission));
		}
		response.add("denied", denied);
		return response;
	}

	private static class SessionStatusCallback implements Session.StatusCallback {
		private final LoginContext context;
		public SessionStatusCallback(LoginContext context) {
			this.context = context;
		}
		@Override
		public void call(Session session, SessionState state, Exception exception) {
			sessionStateChanged(session, state, exception, context);
		}
	}

	private static void handleStatusCallbackException(Exception exception, LoginContext context) {
		//ForgeLog.e("handleStatusCallbackException: " + exception);
		JsonObject result = new JsonObject();
		if (exception instanceof FacebookAuthorizationException) {
			result.addProperty("message", ((FacebookAuthorizationException)exception).getMessage());
			result.addProperty("type", "FacebookAuthorizationException");
		} else if (exception instanceof FacebookDialogException) {
			result.addProperty("message", ((FacebookDialogException)exception).getMessage());
			result.addProperty("code", ((FacebookDialogException)exception).getErrorCode());
			result.addProperty("type", "FacebookDialogException");
		} else if (exception instanceof FacebookException) {
			result.addProperty("message", ((FacebookException)exception).getMessage());
			result.addProperty("type", "FacebookException");
		} else if (exception instanceof FacebookGraphObjectException) {
			result.addProperty("message", ((FacebookGraphObjectException)exception).getMessage());
			result.addProperty("type", "FacebookGraphObjectException");
		} else if (exception instanceof FacebookOperationCanceledException) {
			result.addProperty("message", ((FacebookOperationCanceledException)exception).getMessage());
			result.addProperty("type", "FacebookOperationCanceledException");
		} else if (exception instanceof FacebookServiceException) {
			FacebookRequestError error = ((FacebookServiceException) exception).getRequestError();
			result = Util.ParseFacebookRequestError(error);
		} else {
			result.addProperty("message", exception.getMessage());
			result.addProperty("type", "Unknown");
		}
		context.task.error(result);
	}
}
