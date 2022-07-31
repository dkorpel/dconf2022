var wasmInstance;

function toJsString(ptr, len) {
	try {
		var buffer = new Uint8Array(wasmInstance.exports.memory.buffer, ptr, len);
		return string = new TextDecoder().decode(buffer)
	} catch(err) {
		return "eh?";
	}
}

/// Send strings from JS to webassembly
function wasmSendString(str) {
	const bytes = new TextEncoder().encode(str) // Encode in utf-8
	// Copy the string into memory allocated in the WebAssembly
	const ptr = wasmInstance.exports.getStringMessageBuffer()
	if (bytes.byteLength > 4000) {
		alert("input too big") // #meh
		return;
	}
	const buffer = new Uint8Array(wasmInstance.exports.memory.buffer, ptr, bytes.byteLength + 1) // '0' terminator
	buffer.set(bytes)
	buffer[bytes.byteLength] = 0; // while Uint8Array is initialized to 0, don't rely on that
	wasmInstance.exports.receiveStringMessage(buffer.byteOffset, bytes.byteLength + 1)
	return buffer
}

function jsConsoleLog(ptr, len) {console.log(toJsString(ptr, len));}
function jsAbort(ptr, len) {throw new Error(toJsString(ptr, len))}
function jsGetTimeMillis() {return new Date().getTime();}

// loadWasm('ctod.wasm', {jsConsoleLog, jsAbort, jsGetTimeMillis})

async function loadWasm(fileName, imports) {
	const importObject = {
		env: {...imports, jsConsoleLog, jsAbort, jsGetTimeMillis}
	};
	const fetchPromise = new Promise(resolve => {
		var request = new XMLHttpRequest();
		request.open('GET', fileName);
		request.responseType = 'arraybuffer';
		request.onload = e => resolve(request.response);
		request.onerror = function () {
			resolve(undefined);
			console.error("Could not retrieve WebAssembly object");
		};
		request.send();
	})

	const buffer = await fetchPromise;
	const module = await WebAssembly.compile(buffer);
	wasmInstance = await WebAssembly.instantiate(module, importObject);
	return wasmInstance;
}
