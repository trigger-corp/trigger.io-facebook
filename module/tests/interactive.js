/* global module, asyncTest, ok, start, forge, askQuestion */

module("forge.facebook");

// NB: Safe permissions are: ["public_profile", "email", "user_friends"];
var permissions = ["public_profile", "email", "user_friends", "publish_actions"];

if (forge.is.mobile()) {

	asyncTest("Check if Facebook App is installed", 1, function () {
		askQuestion("Is the Facebook App installed on this device?", {
			Yes: function () {
				forge.facebook.installed(function (installed) {
					ok(installed === true);
					start();
				}, function (e) {
					ok(false, JSON.stringify(e));
					start();
				});
			},
			No: function () {
				forge.facebook.installed(function (installed) {
					ok(installed === false);
					start();
				}, function (e) {
					ok(false, JSON.stringify(e));
					start();
				});
			}
		});
	});

	asyncTest("authorize", 1, function () {
		forge.facebook.authorize(permissions, function () {
			ok(true);
			start();
		}, function () {
			ok(false);
			start();
		});
	});

	asyncTest("check permissions", 1, function () {
		forge.facebook.api('/me/permissions', function (data) {
			/* Looks like this:
			{ "data": [ {"status":"granted","permission":"installed"},
						{"status":"granted","permission":"public_profile"},
						{"status":"granted","permission":"email"},
						{"status":"granted","permission":"publish_actions"},
						{"status":"granted","permission":"user_birthday"},
						{"status":"granted","permission":"user_location"},
						{"status":"granted","permission":"user_friends"} ]} */
			forge.logging.log("Permissions: " + JSON.stringify(data));
			ok(true);
			start();
		}, function () {
			ok(false);
			start();
		});
	});

	asyncTest("attempt api call", 1, function () {
		forge.facebook.api('me', function (data) {
			ok(data.id);
			start();
		}, function () {
			ok(false);
			start();
		});
	});

	asyncTest("post to wall", 1, function () {
		var obj = {
			method: 'feed',
			link: 'https://trigger.io/',
			picture: 'https://trigger.io/forge-static/apple-touch-icon-114x114.png',
			name: 'Trigger.io',
			caption: 'Homepage',
			description: '†Ês†îñg API'
		};

		forge.facebook.ui(obj, function (res) {
			ok(res.post_id);
			start();
		}, function (err) {
			ok(false, JSON.stringify(err));
			start();
		});
	});

	asyncTest("cancel post to wall", 1, function () {
		askQuestion("In the dialog, cancel the share action", {
			Yes: function () {
				var obj = {
					method: 'feed',
					link: 'https://trigger.io/',
					picture: 'https://trigger.io/forge-static/apple-touch-icon-114x114.png',
					name: 'Trigger.io',
					caption: 'Homepage',
					description: 'Testing API'
				};

				forge.facebook.ui(obj, function (res) {
					ok(true, "cancelled ui action resulted in success with: " + JSON.stringify(res));
					start();
				}, function () {
					ok(true);
					start();
				});
			}
		});
	});

	asyncTest("Send apprequests", 1, function () {
		var obj = {
			method: 'apprequests',
			message: '†Ês†îñg API'
		};
		forge.facebook.ui(obj, function (res) {
			ok(res.request);
			start();
		}, function (err) {
			ok(false, JSON.stringify(err));
			start();
		});
	});

	// share
	asyncTest("Share link", 1, function () {
		var obj = {
			method: 'share',
			href: 'https://trigger.io' /* TODO it used to be link!? */
		};
		forge.facebook.ui(obj, function (res) {
			ok(res.post_id);
			start();
		}, function (err) {
			ok(false, JSON.stringify(err));
			start();
		});
	});

	// share_open_graph
	asyncTest("Share OpenGraph", 1, function () {
		var unique_id = Math.floor(Math.random() * 100000);
		var obj = {
			method: 'share_open_graph',
			action_type: 'og.likes',
			action_properties: JSON.stringify({
				object: 'https://developers.facebook.com/docs/#' + unique_id
			})
		};
		forge.facebook.ui(obj, function (res) {
			forge.logging.log("TODO GOT BACK: " + JSON.stringify(res));
			ok(true);
			start();
		}, function (err) {
			ok(false, JSON.stringify(err));
			start();
		});
	});
}
