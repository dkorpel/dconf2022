/**
Memory helpers

Simple allocator implementation by Adam Ruppe.

See_Also: https://github.com/adamdruppe/webassembly
*/
module wasm.mem;

import dbg;

@nogc nothrow @safe:
extern(C):

noreturn abort();

/// Copy `n` bytes from `source` to `destination`
void* memcpy(return scope void* destination, scope const void* source, size_t n) @system {
	ubyte* d = cast(ubyte*) destination;
	ubyte* s = cast(ubyte*) source;
	foreach (i; 0..n) {
		d[i] = s[i];
	}
	return destination;
}

/// Set `len` bytes from `source` to `value` (truncated to a byte)
void* memset(void* source, int value, size_t len) @system {
	ubyte* dst = cast(ubyte*) source;
	while (len > 0) {
		*dst = cast(ubyte) value;
		dst++;
		len--;
	}
	return source;
}

/// Returns: the difference between the first different byte within `n` bytes of `s0` and `s1`, or 0 if identical
int memcmp(scope const void* s0, scope const void* s1, size_t n) @system {
	byte* b0 = cast(byte*) s0;
	byte* b1 = cast(byte*) s1;
	foreach (i; 0..n) {
		const d = b0[i] - b1[i];
		if (d != 0) {
			return d;
		}
	}
	return 0;
}

/// LDC defines these:
/// `0..__data_end..__heap_base..end`
private extern extern(C) ubyte __heap_base;
private extern extern(C) ubyte __data_end;

/// Params:
///   mem = index of memory (set to 0)
///   delta = how many 64 KB pages to grow
/// Returns: old size in 64 KB pages, or `size_t.max` if it failed
pragma(LDC_intrinsic, "llvm.wasm.memory.grow.i32")
private int llvm_wasm_memory_grow(int mem, int delta);

// in 64 KB pages
pragma(LDC_intrinsic, "llvm.wasm.memory.size.i32")
private int llvm_wasm_memory_size(int mem);

private __gshared ubyte* nextFree;
private __gshared size_t memorySize; // in units of 64 KB pages

align(16)
private struct AllocatedBlock {
	@nogc nothrow @safe:
	enum Magic = 0x731a_9bec;
	enum Flags {
		inUse = 1,
		unique = 2,
	}

	size_t blockSize;
	size_t flags;
	size_t magic;
	size_t checksum;

	size_t used; // the amount actually requested out of the block; used for assumeSafeAppend

	/* debug */
	string file;
	size_t line;

	// note this struct MUST align each alloc on an 8 byte boundary or JS is gonna throw bullshit

	void populateChecksum() {
		checksum = blockSize ^ magic;
	}

	bool checkChecksum() const {
		return magic == Magic && checksum == (blockSize ^ magic);
	}

	ubyte[] dataSlice() return @trusted {
		return ((cast(ubyte*) &this) + typeof(this).sizeof)[0 .. blockSize];
	}

	static int opApply(scope int delegate(AllocatedBlock*) nothrow @nogc dg) @trusted {
		if (nextFree is null) {
			return 0;
		}
		ubyte* next = &__heap_base;
		AllocatedBlock* block = cast(AllocatedBlock*) next;
		while(block.checkChecksum()) {
			if (auto result = dg(block)) {
				return result;
			}
			next += AllocatedBlock.sizeof;
			next += block.blockSize;
			block = cast(AllocatedBlock*) next;
		}

		return 0;
	}
}

static assert(AllocatedBlock.sizeof % 16 == 0);

private void arsdFree(ubyte* ptr) @system {
	auto block = (cast(AllocatedBlock*) ptr) - 1;
	if (!block.checkChecksum()) {
		abort();
	}

	block.used = 0;
	block.flags = 0;

	// last one
	if (ptr + block.blockSize == nextFree) {
		nextFree = cast(ubyte*) block;
		assert(cast(size_t)nextFree % 16 == 0);
	}
}

private ubyte[] arsdRealloc(ubyte* ptr, size_t newSize) @system {
	if (ptr is null) {
		return arsdMalloc(newSize);
	}

	auto block = (cast(AllocatedBlock*) ptr) - 1;
	if (!block.checkChecksum()) {
		abort();
	}

	// block.populateChecksum();
	if (newSize <= block.blockSize) {
		block.used = newSize;
		return ptr[0..newSize];
	} else {
		// FIXME: see if we can extend teh block into following free space before resorting to malloc

		// assert trips?
		version(none) if (ptr + block.blockSize == nextFree) {
			while(growMemoryIfNeeded(newSize)) {}

			block.blockSize = newSize + newSize % 16;
			block.used = newSize;
			block.populateChecksum();
			nextFree = ptr + block.blockSize;
			// dprint(newSize, cast(size_t) nextFree, block.blockSize, cast(size_t) ptr % 16);
			assert(cast(size_t) nextFree % 16 == 0);
			return ptr[0..newSize];
		}

		auto newThing = arsdMalloc(newSize);
		newThing[0..block.used] = ptr[0..block.used];

		if (block.flags & AllocatedBlock.Flags.unique) {
			// if we do malloc, this means we are allowed to free the existing block
			free(ptr);
		}

		assert(cast(size_t) newThing.ptr % 16 == 0);

		return newThing;
	}
}

private bool growMemoryIfNeeded(size_t sz) @trusted {
	if (cast(size_t) nextFree + AllocatedBlock.sizeof + sz >= memorySize * 64*1024) {
		if (llvm_wasm_memory_grow(0, 4) == size_t.max) {
			assert(0, "OOM"); // out of memory
		}
		memorySize = llvm_wasm_memory_size(0);
		return true;
	}
	return false;
}

private ubyte[] arsdMalloc(size_t sz, string file = __FILE__, size_t line = __LINE__) @trusted {
	// lol bumping that pointer
	if (nextFree is null) {
		nextFree = &__heap_base; // seems to be 75312
		assert(cast(size_t) nextFree % 16 == 0);
		memorySize = llvm_wasm_memory_size(0);
	}

	while(growMemoryIfNeeded(sz)) {}

	auto base = cast(AllocatedBlock*) nextFree;

	auto blockSize = sz;
	if (auto val = blockSize % 16) {
		blockSize += 16 - val; // does NOT include this metadata section!
	}

	// debug list allocations
	//import std.stdio; writeln(file, ":", line, " / ", sz, " +", blockSize);

	base.blockSize = blockSize;
	base.flags = AllocatedBlock.Flags.inUse;
	// these are just to make it more reliable to detect this header by backtracking through the pointer from a random array.
	// otherwise it'd prolly follow the linked list from the beginning every time or make a free list or something. idk tbh.
	base.magic = AllocatedBlock.Magic;
	base.populateChecksum();

	base.used = sz;

	// debug
	base.file = file;
	base.line = line;

	nextFree += AllocatedBlock.sizeof;

	auto ret = nextFree;

	nextFree += blockSize;

	//writeln(cast(size_t) nextFree);
	//import std.stdio; writeln(cast(size_t) ret, " of ", sz, " rounded to ", blockSize);
	//writeln(file, ":", line);

	// dprint(sz, blockSize, cast(size_t) nextFree % 16, cast(size_t) ret % 16);
	assert(cast(size_t) ret % 16 == 0);

	return ret[0..sz];
}
