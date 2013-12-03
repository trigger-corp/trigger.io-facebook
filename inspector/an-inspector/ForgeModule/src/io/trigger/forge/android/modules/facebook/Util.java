package io.trigger.forge.android.modules.facebook;

import java.util.ArrayList;
import java.util.List;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;

public class Util {

	public static boolean grantedPermissionsAreSuperset(List<String> grantedPermissions, JsonArray newPermissions) {
		List<String> listCopy = new ArrayList<String>(grantedPermissions);
		
		for (JsonElement element : newPermissions) {
			if (element.isJsonPrimitive()) {
				if (!listCopy.remove(element.getAsString())) {
					return false;
				}
			} else {
				return false;
			}
		}
		
		return true;
	}
}
