package io.trigger.forge.android.modules.facebook;

import io.trigger.forge.android.core.ForgeTask;

import java.util.List;

public class LoginContext {
	public ForgeTask task;
	public List<String> permissions;
	public boolean dialog;
	public boolean isRequestingPublishPermissions;
	public LoginContext(ForgeTask task, List<String> permissions, boolean dialog) {
		this.task = task;
		this.permissions = permissions;
		this.dialog = dialog;
		this.isRequestingPublishPermissions = false;
	}
}
