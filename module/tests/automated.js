module("forge.facebook");

/*

These tests shouldn't require interaction, but currently do.

asyncTest("logout", 1, function () {
	forge.facebook.logout(function () {
		ok(true);
		start()
	}, function () {
		ok(false);
		start();
	});
});

asyncTest("attempt api call", 1, function () {
	forge.facebook.api('me', function () {
		ok(forge.is.android());
		start()
	}, function () {
		ok(forge.is.ios());
		start();
	});
});
*/

asyncTest("authorize", 1, function () {
	forge.facebook.authorize(["publish_actions"], function () {
		ok(true);
		start()
	}, function () {
		ok(false);
		start();
	});
});


var unique_id = Math.floor(Math.random() * 1000);

asyncTest("Post an update", 1, function () {
	forge.facebook.api("/me/feed", "POST", {
		message: "forge.facebook.api automated test post: " + unique_id,
    }, function () {
		ok(true);
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

