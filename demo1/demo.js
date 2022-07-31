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
function onInput(str) {
	const bytes = new TextEncoder().encode(str) // Encode in utf-8
	// Copy the string into memory allocated in the WebAssembly
	const ptr = wasmInstance.exports.getStringMessageBuffer()
	if (bytes.byteLength > 4000) {
		alert("input too big")
		return;
	}
	const buffer = new Uint8Array(wasmInstance.exports.memory.buffer, ptr, bytes.byteLength + 1) // '0' terminator
	buffer.set(bytes)
	wasmInstance.exports.wasmReceiveString(buffer.byteOffset, bytes.byteLength)
	return buffer
}

function jsConsoleLog(ptr, len) {console.log(toJsString(ptr, len));}
function jsAbort(ptr, len) {throw new Error(toJsString(ptr, len))}

function jsReceiveString(ptr, len) {
	document.getElementById("dconf-output").innerHTML = toJsString(ptr, len);
}

// Reusable function
async function loadWasm(fileName, imports) {
	const importObject = {
		env: {...imports, jsConsoleLog, jsAbort}
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

// Specific to the app
async function initWasm() {
	wasmInstance = await loadWasm('demo.wasm', {jsReceiveString});
	document.getElementById('dconf-input').addEventListener('input', (ev) => onInput(ev.target.value));
}

window.addEventListener('load', initWasm);
