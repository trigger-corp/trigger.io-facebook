/*

These tests shouldn't require interaction, but currently do.

module("forge.facebook");

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