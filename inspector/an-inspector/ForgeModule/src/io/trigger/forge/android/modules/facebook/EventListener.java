package io.trigger.forge.android.modules.facebook;

import io.trigger.forge.android.core.ForgeApp;
import io.trigger.forge.android.core.ForgeEventListener;
import io.trigger.forge.android.core.ForgeLog;
import android.content.Intent;
import android.os.Bundle;

import com.facebook.AppEventsLogger;
import com.facebook.Session;
import com.facebook.UiLifecycleHelper;
import com.facebook.widget.FacebookDialog;

public class EventListener extends ForgeEventListener {
	
	public static UiLifecycleHelper uiHelper;
	
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		uiHelper = new UiLifecycleHelper(ForgeApp.getActivity(), null);
		uiHelper.onCreate(savedInstanceState);
		String applicationId = ForgeApp.configForPlugin("facebook").get("appid").getAsString();
		AppEventsLogger.activateApp(ForgeApp.getActivity(), applicationId);
	}
	
	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		Session session = Session.getActiveSession();
		if (session != null) {
			session.onActivityResult(ForgeApp.getActivity(), requestCode, resultCode, data);
		}
		uiHelper.onActivityResult(requestCode, resultCode, data, new FacebookDialog.Callback() {
	        @Override
	        public void onError(FacebookDialog.PendingCall pendingCall, Exception error, Bundle data) {
	            ForgeLog.e("ActivityResult " + String.format("Error: %s", error.toString()));
	        }

	        @Override
	        public void onComplete(FacebookDialog.PendingCall pendingCall, Bundle data) {
	            ForgeLog.i("ActivityResult: " + "Success -> " + pendingCall + " -> " + data);
	        }
	    });
	}
	
	@Override
	public void onResume() {
		uiHelper.onResume();
		String applicationId = ForgeApp.configForPlugin("facebook").get("appid").getAsString();
		AppEventsLogger.activateApp(ForgeApp.getActivity(), applicationId);
	}
	
	@Override
	public void onSaveInstanceState(Bundle outState) {
		uiHelper.onSaveInstanceState(outState);
	}
	
	@Override
	public void onPause() {
		uiHelper.onPause();
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		uiHelper.onDestroy();
	}
}
