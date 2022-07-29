function sendInput() {
	wasmSendString(document.getElementById("mnum-input").value, 0);
}

/// exported so webassembly can send strings to JS
function mnumSendString(ptr, len, type) {
	const s = toJsString(ptr, len);
	switch (type) {
		case 0:
			console.log(s);
			break;
		case 1:
			document.getElementById("mnum-error").innerHTML = s;
			break;
		case 2:
			document.getElementById("mnum-output").value = s;
			break;
		case 3:
			document.getElementById("mnum-math-output").innerHTML = s;
			break;
	}
}

// Don't display errors while user is still typing
let timer;

function onMnumInput(str) {
	wasmSendString(str, 0);
    clearTimeout(timer);
    timer = setTimeout(() => {
		wasmSendString(str, 1);
	}, /*msec*/ 500);
}

function setRadix(str) {
	if (str == "auto") {
		wasmInstance.exports.mnumSetRadix(-1);
	} else {
		const r = parseInt(str);
		if (!isNaN(r)) {
			wasmInstance.exports.mnumSetRadix(r);
		} else {
			throw "Invalid radix " + r;
		}
	}
	sendInput()
}

async function initWasm() {
	wasmInstance = await loadWasm('mnum.wasm', {mnumSendString});
	document.getElementById('mnum-input').addEventListener('input', (ev) => onMnumInput(ev.target.value));
	document.getElementById('mnum-radix').addEventListener('input', (ev) => setRadix(ev.target.value));
	setRadix(document.getElementById('mnum-radix').value);
}

window.addEventListener('load', initWasm);
