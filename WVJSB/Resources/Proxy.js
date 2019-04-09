;
(function() {
	const namespace = 'wvjsb_namespace';
	const proxyKey = namespace + '_wvjsb_proxy';

	function getProxy() {
		return window[proxyKey];
	}

	function setProxy(proxy) {
		window[proxyKey] = proxy;
	};
	let proxy = getProxy();
	if (proxy) return 'wvjsb proxy was already installed';
	const queryURL = 'https://wvjsb/' + namespace + '/query';
	const messageBuffers = [];
	const clients = {};
	const messageHandlerKey = namespace;
	const sendToClient = function(client, message) {
		const data = {};
		data[namespace] = message;
		client.postMessage(data, '*');
	}
	const sendToServer = (function() {
		let v = null;
		try {
			v = window[messageHandlerKey].postMessage; //android WebView
			if (v) return function(message) {
				try {
					window[messageHandlerKey].postMessage(JSON.stringify(message));
				} catch (e) {}
			};
		} catch (e) {}
		try {
			v = webkit.messageHandlers[messageHandlerKey].postMessage; //WKWebView
			if (v) return function(message) {
				try {
					webkit.messageHandlers[messageHandlerKey].postMessage(JSON.stringify(message));
				} catch (e) {}
			};
		} catch (e) {}
		v = function(message) { //iOS UIWebView WebView
			try {
				messageBuffers.push(JSON.stringify(message));
				const iframe = document.createElement('iframe');
				iframe.style.display = 'none';
				iframe.src = queryURL;
				document.documentElement.appendChild(iframe);
				setTimeout(function() {
					document.documentElement.removeChild(iframe);
				}, 0);
			} catch (e) {}
		};
		return v;
	})();
	proxy = {
		query: function() {
			const jsonString = JSON.stringify(messageBuffers);
			messageBuffers.splice(0, messageBuffers.length);
			return jsonString;
		},
		send: function(jsonString) {
			const message = JSON.parse(jsonString);
			const {
				to
			} = message;
			const client = clients[to];
			if (client) sendToClient(client,message);
			return 'true';
		}
	}
	setProxy(proxy);

	window.addEventListener('message', function({
		source, data
	}) {
		try {
			const message = data[namespace];
			if (!message) return;
			const {
				from = null, to = null
			} = message;
			if (!from) return;
			let client = clients[from];
			if (client) {
				if (client != source) {
					throw 'client window mismatched';
				}
			} else {
				clients[from] = source;
			}
			if (to != namespace) return;
			sendToServer(message);
		} catch (e) {}
	});


	function broadcast(wd, data) {
		wd.postMessage(data, '*');
		const frames = wd.frames;
		for (let i = 0; i < frames.length; i++) {
			broadcast(frames[i]);
		}
	};

	function proxyConnect() {
		const data = {};
		data[namespace] = {};
		broadcast(window, data);
	}

	function proxyDisconnect() {
		sendToServer({});
	}

	window.addEventListener('unload', function() {
		proxyDisconnect();
	});
	proxyConnect();
	return 'wvjsb proxy was installed';
})();