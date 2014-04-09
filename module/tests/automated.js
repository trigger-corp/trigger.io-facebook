/* global module, asyncTest, ok, start, forge */

module("forge.facebook");

asyncTest("logout", 1, function () {
	forge.facebook.logout(function () {
		ok(true);
		start();
	}, function () {
		ok(false);
		start();
	});
});

var permissions = ["basic_info", "publish_actions"];

asyncTest("hasAuthorized - logged out", 1, function () {
	forge.facebook.hasAuthorized(permissions, function () {
		ok(false);
		start();
	}, function () {
		ok(true);
		start();
	});
});

asyncTest("authorize", 1, function () {
	forge.facebook.authorize(permissions, function (auth) {
		ok(auth !== null);
		start();
	}, function () {
		ok(false);
		start();
	});
});

asyncTest("hasAuthorized - logged in", 1, function () {
	forge.facebook.hasAuthorized(permissions, function (auth) {
		ok(auth !== null);
		start();
	}, function () {
		ok(false);
		start();
	});
});

asyncTest("attempt api call", 1, function () {
	forge.facebook.api("/me", function (data) {
		ok(data !== null);
		start();
	}, function () {
		ok(false);
		start();
	});
});

var unique_id = Math.floor(Math.random() * 1000);

asyncTest("Post an update", 1, function () {
	forge.facebook.api("/me/feed", "POST", {
		message: "forge.facebook.api automated test post: " + unique_id,
    }, function (data) {
		ok(data !== null);
		start();
	}, function () {
		ok(false);
		start();
	});
});

asyncTest("Post a duplicate update", 1, function () {
	forge.facebook.api("/me/feed", "POST", {
		message: "forge.facebook.api automated test post: " + unique_id,
    }, function () {
		ok(false);
		start();
	}, function () {
		ok(true);
		start();
	});
});


