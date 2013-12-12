package io.trigger.forge.android.modules.facebook;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeLog;
import io.trigger.forge.android.core.ForgeParam;
import io.trigger.forge.android.core.ForgeTask;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map.Entry;

import org.apache.http.NameValuePair;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;

import android.content.SharedPreferences;
import android.os.Bundle;

import com.facebook.android.AsyncFacebookRunner;
import com.facebook.android.DialogError;
import com.facebook.android.Facebook;
import com.facebook.android.Facebook.DialogListener;
import com.facebook.android.FacebookError;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

public class API {
	protected static Facebook facebook = null;
	private static AsyncFacebookRunner runner = null;
	private static boolean partnerProgramNotified = false;

	private static void partnerProgram(ForgeTask task) {
		if (!partnerProgramNotified) {
			task.performAsync(new Runnable() {
				
				@Override
				public void run() {
					// Create a new HttpClient and Post Header
				    HttpClient httpclient = new DefaultHttpClient();
				    HttpPost httppost = new HttpPost("https://www.facebook.com/impression.php");

				    try {
				        // Add your data
				        List<NameValuePair> nameValuePairs = new ArrayList<NameValuePair>(2);
				        nameValuePairs.add(new BasicNameValuePair("plugin", "featured_resources"));
				        JsonObject payload = new JsonObject();
				        payload.addProperty("resource", "triggerio_triggerio");
				        payload.addProperty("appid", ForgeApp.configForPlugin("facebook").get("appid").getAsString());
				        if (!ForgeApp.appConfig.has("platform_version")) {
				        	return;
				        }
			        	payload.addProperty("version", ForgeApp.appConfig.get("platform_version").getAsString());
				        nameValuePairs.add(new BasicNameValuePair("payload", payload.toString()));
				        httppost.setEntity(new UrlEncodedFormEntity(nameValuePairs));

				        // Execute HTTP Post Request
				        httpclient.execute(httppost);
				    } catch (Exception e) {
				        ForgeLog.w("Error reporting partner data to Facebook");
				    }
				}
			});
			
			partnerProgramNotified = true;
		}
	}
	
	private static Facebook getFacebook(ForgeTask task) {
		if (facebook == null) {
			facebook = new Facebook(ForgeApp.configForPlugin("facebook").get("appid").getAsString());
		}
		return facebook;
	}

	private static AsyncFacebookRunner getFacebookRunner(ForgeTask task) {
		if (runner == null) {
			runner = new AsyncFacebookRunner(getFacebook(task));
		}
		return runner;
	}
	
	private static SharedPreferences getStorage(ForgeTask task) {
 		return ForgeApp.getActivity().getSharedPreferences("facebook", 0);
 	}

	public static void authorize(final ForgeTask task, @ForgeParam("permissions") final JsonArray permissionsJSON, @ForgeParam("dialog") final boolean dialog) {
		partnerProgram(task);

		final String fpermissionsJSON = permissionsJSON.toString();
		final String[] permissions = new String[permissionsJSON.size()];
		for (int i = 0; i < permissionsJSON.size(); i++) {
			permissions[i] = permissionsJSON.get(i).getAsString();
		}
		final Facebook facebook = getFacebook(task);
		
		final SharedPreferences prefs = getStorage(task);
		String access_token = prefs.getString("access_token", null);
		long expires = prefs.getLong("access_expires", 0);
		if (access_token != null) {
			facebook.setAccessToken(access_token);
		}
		if (expires != 0) {
			facebook.setAccessExpires(expires);
		}
		
		if (facebook.isSessionValid() && Util.grantedPermissionsAreSuperset(facebook.getSession().getPermissions(), permissionsJSON)) {
			JsonObject details = new JsonObject();
			details.addProperty("access_token", facebook.getAccessToken());
			details.addProperty("access_expires", facebook.getAccessExpires());
			task.success(details);
		} else if (dialog) {
			task.performUI(new Runnable() {
				public void run() {
					facebook.authorize(ForgeApp.getActivity(), permissions, new DialogListener() {
						public void onComplete(Bundle values) {
							SharedPreferences.Editor editor = prefs.edit();
							editor.putString("access_token", facebook.getAccessToken());
							editor.putLong("access_expires", facebook.getAccessExpires());
							editor.commit();
							JsonObject details = new JsonObject();
							details.addProperty("access_token", facebook.getAccessToken());
							details.addProperty("access_expires", facebook.getAccessExpires());
							task.success(details);
						}

						public void onFacebookError(FacebookError error) {
							task.error(error.getLocalizedMessage(), "EXPECTED_FAILURE", null);
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
		} else {
			task.error("User not logged in", "EXPECTED_FAILURE", null);
		}
	}

	public static void logout(final ForgeTask task) {
		partnerProgram(task);

		getFacebook(task).setAccessToken(null);
		getFacebook(task).setAccessExpires(0);
		getFacebookRunner(task).logout(ForgeApp.getActivity(), new AsyncFacebookRunner.RequestListener() {
			public void onComplete(String response, Object state) {
				task.success();
			}

			public void onIOException(IOException e, Object state) {
				task.error(e);
			}

			public void onFileNotFoundException(FileNotFoundException e, Object state) {
				task.error(e);
			}

			public void onMalformedURLException(MalformedURLException e, Object state) {
				task.error(e);
			}

			public void onFacebookError(FacebookError error, Object state) {
				task.error(error.getLocalizedMessage(), "EXPECTED_FAILURE", null);
			}
		});
	}

	public static void api(final ForgeTask task, @ForgeParam("params") final JsonObject params, @ForgeParam("path") final String path, @ForgeParam("method") final String method) {
		partnerProgram(task);

		Bundle paramBundle = new Bundle();
		
		for (Entry<String, JsonElement> entry : params.entrySet()) {
			String key = entry.getKey();
			paramBundle.putString(key, entry.getValue().getAsString());
		}
		
		getFacebookRunner(task).request(path, paramBundle, method, new AsyncFacebookRunner.RequestListener() {
			public void onComplete(String response, Object state) {
				task.success(new JsonParser().parse(response));
			}

			public void onIOException(IOException e, Object state) {
				task.error(e);
			}

			public void onFileNotFoundException(FileNotFoundException e, Object state) {
				task.error(e);
			}

			public void onMalformedURLException(MalformedURLException e, Object state) {
				task.error(e);
			}

			public void onFacebookError(FacebookError error, Object state) {
				task.error(error.getLocalizedMessage(), "EXPECTED_FAILURE", null);
			}
		}, null);
	}

	public static void ui(final ForgeTask task) {
		partnerProgram(task);

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
				} else {
					getFacebook(task).dialog(ForgeApp.getActivity(), method, paramBundle, new DialogListener() {
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
							task.error(error.getLocalizedMessage(), "EXPECTED_FAILURE", null);
						}

						public void onError(DialogError e) {
							task.error(e);
						}

						public void onCancel() {
							task.error("User cancelled", "EXPECTED_FAILURE", null);
						}
					});
				}
			}
		});
	}
}
