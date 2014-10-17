package io.trigger.forge.android.modules.facebook;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeParam;
import io.trigger.forge.android.core.ForgeTask;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;

import android.content.pm.PackageManager;
import android.os.Bundle;

import com.facebook.FacebookRequestError;
import com.facebook.HttpMethod;
import com.facebook.Request;
import com.facebook.RequestAsyncTask;
import com.facebook.Response;
import com.facebook.Session;
import com.facebook.Settings;
import com.facebook.android.DialogError;
import com.facebook.android.Facebook.DialogListener;
import com.facebook.android.FacebookError;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

public class API {
	
	/* ---------------------------------------------------------------------- */

	public static void authorize(final ForgeTask task, @ForgeParam("permissions") final JsonArray permissionsJSON, @ForgeParam("dialog") final boolean dialog) {
		ForgeLog.i("API.authorize -> " + permissionsJSON + " -> " + dialog);
		Util.partnerProgram(task);		
		final String[] permissions = new String[permissionsJSON.size()];
		for (int i = 0; i < permissionsJSON.size(); i++) {
			permissions[i] = permissionsJSON.get(i).getAsString();
		}
		List<String> requestedPermissions = new ArrayList<String>(Arrays.asList(permissions));
		LoginContext context = new LoginContext(task, requestedPermissions, dialog);
		LoginDelegate.handleLogin(context);
	}
	
	public static void logout(final ForgeTask task) {
		Util.partnerProgram(task);
		Session session = Session.getActiveSession();
		if (session != null) {
			if (session.isOpened()) {
				session.closeAndClearTokenInformation();
			} else {
				ForgeLog.w("User was not logged in.");
			}
		} else {
			ForgeLog.w("There was no active session.");
		}
		task.success();
	}
	
	/* ---------------------------------------------------------------------- */
	

	public static void api(final ForgeTask task, @ForgeParam("params") final JsonObject params, @ForgeParam("path") final String path, @ForgeParam("method") final String method) {
		Util.partnerProgram(task);
		final Bundle paramBundle = new Bundle();
		for (Entry<String, JsonElement> entry : params.entrySet()) {
			String key = entry.getKey();
			paramBundle.putString(key, entry.getValue().getAsString());
		}
		
		final Session session = Session.getActiveSession();
		if (session == null) {
			task.error("No valid session found. Are you logged in?", "UNEXPECTED_FAILURE", null);
			return;
		}
		task.performUI(new Runnable() {
			@Override
			public void run() {
				Request.Callback callback = new Request.Callback() {
					public void onCompleted(Response response) {
						FacebookRequestError error = response.getError();
						if (error != null) {
							JsonObject result = Util.ParseFacebookRequestError(error);
							task.error(result);
						} else {
							JsonElement result = (new JsonParser().parse(response.getRawResponse()));
							task.success(result);
						}
					}
				};
				Request request = new Request(session, path, paramBundle, HttpMethod.valueOf(method.toUpperCase()), callback);
				(new RequestAsyncTask(request)).execute();
			}
		});
	}
	
	/*public static void ui_new(final ForgeTask task) {
		String method = null;
		final Bundle paramBundle = new Bundle();
		for (Entry<String, JsonElement> entry : task.params.entrySet()) {
			String key = entry.getKey();
			if (key.equals("method")) {
				method = entry.getValue().getAsString();
			} else {
				paramBundle.putString(key, entry.getValue().getAsString());
			}
		}
		if (method == null) {
			task.error("'method' is required for ui", "BAD_INPUT", null);
			return;
		}
		
		final OnCompleteListener dialogCallback = new OnCompleteListener() {
			@Override
			public void onComplete(Bundle values, FacebookException error) {
				if (error != null) {
					JsonObject result = new JsonObject();
					result.addProperty("message", error.getLocalizedMessage());
					task.error(result);
				} else {
					JsonObject params = new JsonObject();
					Iterator<?> keys = values.keySet().iterator();
					while (keys.hasNext()) {
						String key = (String) keys.next();
						params.addProperty(key, (String) values.get(key));
					}
					task.success(params);
				}				
			}
		};

		if (method.equalsIgnoreCase("feed")) {
			task.performUI(new Runnable() {				
				@Override
				public void run() {
					(new WebDialog.FeedDialogBuilder(ForgeApp.getActivity(), Session.getActiveSession(), paramBundle))
						.setOnCompleteListener(dialogCallback).build().show();
				}
			});
		} else if (method.equalsIgnoreCase("apprequests")) {
			task.performUI(new Runnable() {				
				@Override
				public void run() {
					(new WebDialog.RequestsDialogBuilder(ForgeApp.getActivity(), Session.getActiveSession(), paramBundle))
						.setOnCompleteListener(dialogCallback).build().show();
				}
			});
		} else if (method.equalsIgnoreCase("share") || method.equalsIgnoreCase("share_open_graph")) {
			if (FacebookDialog.canPresentShareDialog(ForgeApp.getActivity(), FacebookDialog.ShareDialogFeature.SHARE_DIALOG)) {
				ForgeLog.i("Using Share Dialog");
				task.performUI(new Runnable() {
					public void run() {
						FacebookDialog shareDialog = new FacebookDialog.ShareDialogBuilder(ForgeApp.getActivity())
							.setName(paramBundle.getString("name"))
							.setCaption(paramBundle.getString("caption"))
							.setDescription(paramBundle.getString("description"))
							.setLink(paramBundle.getString("link"))
							.setPicture(paramBundle.getString("picture"))
							.build();
						shareDialog.present();
						EventListener.uiHelper.trackPendingDialogCall(shareDialog.present());
					}
				});
				EventListener.trackingPendingCall = true;
			} else {
				task.performUI(new Runnable() {
					public void run() {
						WebDialog feedDialog = (new WebDialog.FeedDialogBuilder(ForgeApp.getActivity(), Session.getActiveSession(), paramBundle)).setOnCompleteListener(dialogCallback).build();
						feedDialog.show();
					}
				});
			}
		} else {
			task.error("Unsupported dialog method", "BAD_INPUT", null);
			return;
		}
	}*/

	public static void ui(final ForgeTask task) {
		Util.partnerProgram(task);

		task.performUI(new Runnable() {
			public void run() {
				String method = null;
				Bundle paramBundle = new Bundle();
				for (Entry<String, JsonElement> entry : task.params.entrySet()) {
					String key = entry.getKey();
					if (key.equals("method")) {
						method = entry.getValue().getAsString();
					} else {
						paramBundle.putString(key, entry.getValue().getAsString());
					}
				}
				if (method == null) {
					task.error("'method' is required for ui", "BAD_INPUT", null);
					return;
				}
				Util.getFacebook(task).dialog(ForgeApp.getActivity(), method, paramBundle, new DialogListener() {
					public void onComplete(Bundle values) {
						JsonObject params = new JsonObject();
						Iterator<?> keys = values.keySet().iterator();
						while (keys.hasNext()) {
							String key = (String) keys.next();
							params.addProperty(key, (String) values.get(key));
						}
						task.success(params);
					}

					public void onFacebookError(FacebookError error) {
						JsonObject result = new JsonObject();
						result.addProperty("message", error.getLocalizedMessage());
						result.addProperty("type", error.getErrorType());
						result.addProperty("code", error.getErrorCode());
						task.error(result);
					}

					public void onError(DialogError e) {
						task.error(e);
					}

					public void onCancel() {
						task.error("User cancelled", "EXPECTED_FAILURE", null);
					}
				});
			}
		});
	}
	
	private static boolean facebook_app_installed() {
		try {
		    ForgeApp.getActivity().getPackageManager().getApplicationInfo("com.facebook.katana", 0);
		} catch (PackageManager.NameNotFoundException e ){
		    return false;
		} catch (Exception e) {
			return false;
		}
		return true;
	}
	
	public static void installed(final ForgeTask task) {
		if (facebook_app_installed()) {
			task.success(true);
		} else {
			task.success(false);
		}		
	}

	public static void enablePlatformCompatibility(final ForgeTask task) {
		Settings.setPlatformCompatibilityEnabled(true);
		task.success(true);
	}
}
