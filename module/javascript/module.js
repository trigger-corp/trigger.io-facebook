forge['facebook'] = {
	'authorize': function(permissions, audience, success, error) {
		if (typeof permissions == "function") {
			error = audience;
			success = permissions;
			permissions = [];
			audience = undefined;
		} else if (typeof audience === "function") {
			error = success;
			success = audience;
			audience = undefined;
		}

		// check permissions
		var unknown = permissions.filter(function (permission) {
			return forge.facebook.permissions.indexOf(permission) === -1;
		});
		if (unknown.length) {
			forge.logging.error("You have specified one or more unknown Facebook permissions: " + unknown.join(", "));
		}

		forge.internal.call("facebook.authorize", {
			permissions: permissions,
			audience: audience,
			dialog: true
		}, success, error);
	},
	'hasAuthorized': function(permissions, audience, success, error) {
		if (typeof permissions == "function") {
			error = audience;
			success = permissions;
			permissions = [];
			audience = undefined;
		} else if (typeof audience === "function") {
			error = success;
			success = audience;
			audience = undefined;
		}

		// check permissions
		var unknown = permissions.filter(function (permission) {
			return forge.facebook.permissions.indexOf(permission) === -1;
		});
		if (unknown.length) {
			forge.logging.error("You have specified one or more unknown Facebook permissions: " + unknown.join(", "));
		}

		forge.internal.call("facebook.authorize", {
			permissions: permissions,
			audience: audience,
			dialog: false
		}, success, error);
	},
	'logout': function (success, error) {
		forge.internal.call("facebook.logout", {}, success, error);
	},
	'api': function (path, method, params, success, error) {
		if (typeof method == "function" || arguments.length == 1) {
			error = params;
			success = method;
			method = "GET";
			params = {};
		} else if (typeof params == "function" || arguments.length == 2) {
			error = success;
			success = params;
			params = method;
			method = "GET";
		}
		if (params) {
			// FB seems to always want stringy param values
			for (var key in params) {
				params[key] = String(params[key]);
			}
		}
		forge.internal.call("facebook.api", {
			path: path,
			method: method,
			params: params
		}, success, error);
	},
	'ui': function (params, success, error) {
		function convertQSArrayToJSArray (obj) {
			/*
			Convert
				{"a[0]": 10, "a[1]": 11, "b": 12, "c[1]": 13}
			To
				{"a": [10, 11], "b":12, "c":[null,13]}
			*/
			var result = {};
			for (var key in obj) {
				if (!obj.hasOwnProperty(key)) { continue; }
				var index = key.search(/\[\d+\]/);
				if (index > 0) {
					var arrayKey = key.substring(0, index),
						arrayIndex = key.substring(index+1, key.length-1);
					if (typeof result[arrayKey] === 'undefined') {
						result[arrayKey] = [];
					}
					result[arrayKey][Number(arrayIndex)] = obj[key];
				} else {
					result[key] = obj[key];
				}
			}
			return result;
		}
		forge.internal.call("facebook.ui", params, function (resp) {
			if (success) {
				success(convertQSArrayToJSArray(resp));
			}
		}, error);
	},
	'installed': function (success, error) {
		forge.internal.call("facebook.installed", {}, success, error);
	},
	/**
	 * Known valid permissions
	 * From: https://developers.facebook.com/docs/facebook-login/permissions/v2.0#reference
	 *
	 * auth methods check against this list and warn if requested permission is
	 * not present
	 */
	'permissions': [
		// these permissions won't require that your app be reviewed by facebook
		"public_profile", "user_friends", "email",
		// extended profile properties
		"user_about_me", "user_activities", "user_birthday", "user_education_history",
		"user_events", "user_groups", "user_hometown", "user_interests", "user_likes",
		"user_location", "user_photos", "user_relationships", "user_relationship_details",
		"user_religion_politics", "user_status", "user_tagged_places", "user_videos",
		"user_website", "user_work_history",
		// extended permissions
		"read_friendlists", "read_insights", "read_mailbox", "read_stream",
		// extended permissions - Publish
		/*"create_event", ??? */ "manage_notifications", "publish_actions", "rsvp_event",
		// open graph permissions
		/*"publish_actions",*/ "user_actions.books", "user_actions.fitness", "user_actions.music",
		"user_actions.news", "user_actions.video", /*"user_actions.APP_NAMESPACE",*/
		// pages
		"manage_pages", "read_page_mailboxes"
	]
};
