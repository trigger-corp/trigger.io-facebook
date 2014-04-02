/* global module, asyncTest, ok, start, forge, askQuestion */

module("forge.facebook");

if (forge.is.mobile()) {
	asyncTest("authorize", 1, function () {
		forge.facebook.authorize(function () {
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
}
