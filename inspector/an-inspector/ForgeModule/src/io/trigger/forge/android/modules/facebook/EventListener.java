package io.trigger.forge.android.modules.facebook;

import io.trigger.forge.android.core.ForgeEventListener;
import android.content.Intent;

public class EventListener extends ForgeEventListener {
	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		if (API.facebook != null) {
			API.facebook.authorizeCallback(requestCode, resultCode, data);
		}
	}
}
