const WVJSBClient = function(namespace = 'wvjsb_namespace', info = {}) {
	const clientKey = namespace + '_wvjsb_client';
	const proxyKey = namespace + '_wvjsb_proxy';

	function getClient() {
		return window[clientKey];
	}

	function setClient(client) {
		window[clientKey] = client;
	}

	let client = getClient();

	if (client) return client;

	const error = {
		cancelled: {
			code: -999,
			description: 'cancelled'
		},
		timedOut: {
			code: -1001,
			description: 'timed out'
		},
		connectionLost: {
			code: -1005,
			description: 'connection lost'
		}
	}

	const installURL = 'https://wvjsb/' + namespace + '/install';

	function createGuid() {
		return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			var r = Math.random() * 16 | 0,
				v = c == 'x' ? r : (r & 0x3 | 0x8);
			return v.toString(16);
		});
	}

	const clientId = createGuid();

	let connected = false;
	let nextSeq = 0;
	const cancels = {};
	const handlers = {};
	const operations = {};

	function sendToProxy(message) {
		const data = {};
		data[namespace] = message;
		window.top.postMessage(data, '*');
	}

	function connect() {
		sendToProxy({
			from: clientId,
			to: namespace,
			type: 'connect',
			parameter: info
		});
	}

	function disconnect() {
		sendToProxy({
			from: clientId,
			to: namespace,
			type: 'disconnect'
		});
	}

	function startAllOperation() {
		for (let id in operations) {
			const operation = operations[id];
			operation._start();
		}
	}


	function finishAllOperation() {
		for (let id in operations) {
			const operation = operations[id];
			operation._ack(null, error.connectionLost);
		}
	}

	client = {
		on: function(type) {
			let handler = handlers[type];
			if (handler){
				return handler;
			}
			handler = {
				onEvent: function(func) {
					const handler = this;
					handler.event = func;
					return handler;
				},
				onCancel: function(func) {
					const handler = this;
					handler.cancel = func;
				}
			};
			handlers[type] = handler;
			return handler;
		},
		event: function(type, parameter) {
			const id = (nextSeq++).toString();
			const operation = {
				id: id,
				type: type,
				parameter: parameter,
				onAck: function(func) {
					const operation = this;
					if (operation.ok) return;
					operation.ack = function(result,error){
						func(operation,result,error);
					};
					operations[id] = operation;
					return operation;
				},
				timeout: function(timeout) {
					const operation = this;
					if (operation.ok || timeout <= 0 || operation.timer) return;
					operation.timer = window.setTimeout(function() {
						if (operation.ok) return;
						operation.ok = true;
						delete operations[id];
						const timer = operation.timer;
						if (timer){
							window.clearTimeout(timer);
							delete operation.timer;
						}
						const ack = operation.ack;
						if (ack) ack(null, error.timedOut);
					}, timeout);
					return operation;
				},
				cancel: function() {
					const operation = this;
					if (operation.ok) return;
					operation.ok = true;
					delete operations[id];
					const timer = operation.timer;
					if (timer) {
						window.clearTimeout(timer);
						delete operation.timer;
					}
					const ack = operation.ack;
					if (ack) ack(null, error.cancelled);

				},
				_ack: function(result, error) {
					const operation = this;
					if (operation.ok) return;
					operation.ok = true;
					delete operations[id];
					const timer = operation.timer;
					if (timer) {
						window.clearTimeout(timer);
						delete operation.timer;
					}
					const ack = operation.ack;
					if (ack) ack(result, error);
				},
				_start: function() {
					if (!connected) return;
					const operation = this;
					sendToProxy({
						id: operation.id,
						parameter: operation.parameter,
						type: operation.type,
						from: clientId,
						to: namespace
					});
				}
			};
			operations[id] = operation;
			operation._start();
			return operation;
		}
	};
	window.addEventListener('message', function({
		data
	}) {
		try {
			const message = data[namespace];
			if (!message) return;
			const {
				id, from, to, type, parameter, error
			} = message;
			if (proxyKey==from) {
				if ('connect'==type){
					if (true==connected){
						connected=false;
					}
					connect();
				}else if("disconnect"==type){
					if (true==connected){
						connected=false;
						finishAllOperation();
					}
				}
				return;
			}
			if (to != clientId) return;
			if (from != namespace) return;
			if ('connect' == type) {
				if (connected == true) return;
				connected = true;
				startAllOperation();
				const handler = handlers[type];
				if (!handler) return;
				handler.event(null,function(){
					return function(_,_){}
				});
				return;
			}
			if ('cancel' == type) {
				const cancel = cancels[id];
				if (cancel) cancel();
				return;
			}
			if ('ack' == type) {
				const operation = operations[id];
				if (!operation) return;
				if (operation) operation._ack(parameter, error);
				return;
			}
			const handler = handlers[type];
			if (!handler) return;
			const context = handler.event(message.parameter, function() {
				delete cancels[id];
				return function(result,error){
					sendToProxy({
						id: id,
						from: clientId,
						to: from,
						type: 'ack',
						parameter: result,
						error: error
					});
				}
			});
			cancels[id]=function (){
				handler.cancel(context);
				delete cancels[id];
			}
		} catch (e) {}
	});

	window.addEventListener('unload', function() {
		if (connected == false) return;
		connected = false;
		finishAllOperation();
		disconnect();
	});

	function tellServerToInstall() {
		const iframe = document.createElement('iframe');
		iframe.style.display = 'none';
		iframe.src = installURL;
		document.documentElement.appendChild(iframe);
		window.setTimeout(function() {
			document.documentElement.removeChild(iframe);
		}, 0);
	}
	tellServerToInstall();
	connect();
	setClient(client);
	return client;
};