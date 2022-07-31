
.PHONY: wasm
mnum-wasm:
	ldc2 -i -mtriple=wasm32-unknown-unknown-wasm -L-allow-undefined wasm/object.d \
	demo.d \
	-of=demo.wasm

.PHONY: clean
clean:
	rm -f demo.wasm demo.o
