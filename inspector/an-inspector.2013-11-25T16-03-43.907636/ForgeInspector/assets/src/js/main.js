function updateTokenDisplay(token) {
	$('#token').text(JSON.stringify(token));
}

function basicAuth() {
	forge.facebook.authorize([], updateTokenDisplay);
}

function xmppAuth() {
	forge.facebook.authorize(['xmpp_login'], updateTokenDisplay);
}

function logout() {
	forge.facebook.logout(function () {
		$('#token').text('Logged out.');
	});
}