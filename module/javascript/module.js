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
	}
};
