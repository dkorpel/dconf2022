// Minimal druntime for webassembly. Assumes your program has a main function.
module object;

import wasm.mem;

alias string = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];
alias size_t = typeof(int.sizeof);
alias ptrdiff_t = typeof(cast(void*)0 - cast(void*)0);
alias noreturn = typeof(*null);

pure nothrow @nogc {
	extern(C) void arsdFree(ubyte* ptr) @system pure;
	extern(C) ubyte[] arsdRealloc(ubyte* ptr, size_t newSize) @system pure;
	extern(C) ubyte[] arsdMalloc(size_t sz, string file = __FILE__, size_t line = __LINE__) @trusted pure;
}

extern(C) void jsConsoleLog(scope const(char)* ptr, size_t length) @system pure nothrow @nogc;
extern(C) noreturn jsAbort(scope const(char)* ptr, size_t length) @system pure nothrow @nogc;

nothrow:

// ldc defines this, used to find where wasm memory begins
private extern extern(C) ubyte __heap_base;
//                                           ---unused--- -- stack grows down -- -- heap here --
// this is less than __heap_base. memory map 0 ... __data_end ... __heap_base ... end of memory
private extern extern(C) ubyte __data_end;

private ubyte* nextFree;
private size_t memorySize;

alias _Unwind_Exception = void;
extern(C) void _Unwind_Resume(_Unwind_Exception* exception_object) {}

// then the entry point just for convenience so main works.
// extern(C) int _Dmain(string[] args);
extern(C) void _start() {
	//cast(void) _Dmain(null);
}

/// Quit the program immediately
extern(C) noreturn abort() @trusted {
	enum msg = "abort from wasm";
	jsAbort(msg.ptr, msg.length);
	// *(cast(int*) 0) = 0xDEADBEEF; // halt
	while(1) {}
}

/// duplicate a
T[] dup(T)(scope const(T)[] a) pure nothrow @trusted if (__traits(isPOD, T)) {
	if (__ctfe) {
		T[] result;
		foreach(ref e; a) {
			result ~= e;
		}
		return result;
	}

	auto arr = (cast(T*) malloc(T.sizeof * a.length))[0..a.length];
	arr[] = a[];
	return arr;
}

//public import core.internal.array.casting: __ArrayCast;

/**
The compiler lowers expressions of `cast(TTo[])TFrom[]` to
this implementation. Note that this does not detect alignment problems.

Params:
	from = the array to reinterpret-cast

Returns:
	`from` reinterpreted as `TTo[]`
 */
TTo[] __ArrayCast(TFrom, TTo)(return scope TFrom[] from) @nogc pure @trusted
{
	const fromSize = from.length * TFrom.sizeof;
	const toLength = fromSize / TTo.sizeof;
	if ((fromSize % TTo.sizeof) != 0) {
		assert(0);
	}
	struct Array {
		size_t length;
		void* ptr;
	}
	auto a = cast(Array*) &from;
	a.length = toLength; // jam new length
	return *cast(TTo[]*) a;
}

bool _xopEquals(const void*, const void*) {
	assert(0, "TypeInfo.equals is not implemented");
}

bool _xopCmp(const void*, const void*) {
	assert(0, "TypeInfo.compare is not implemented");
}

extern(C) ubyte* malloc(size_t sz) pure nothrow @nogc @trusted {
	return arsdMalloc(sz).ptr;
}
extern(C) void free(void* ptr) pure nothrow @nogc @system {
	return arsdFree(cast(ubyte*) ptr);
}
extern(C) ubyte* realloc(void* ptr, size_t sz) pure nothrow @nogc @system {
	return arsdRealloc(cast(ubyte*) ptr, sz).ptr;
}

immutable(T)[] idup(T)(scope const(T)[] array) pure nothrow @trusted if (__traits(isPOD, T)) {
	// only needed for ctfe casting to immutable
	immutable(T)[] result;
	foreach(ref e; array) {
		result ~= e;
	}
	return result;
	// TODO: why is immutable conversion disallowed here?
	// return array.dup;
}

extern(C) bool _xopEquals(in void*, in void*) { return false; } // assert(0);

// basic array support
extern(C) void _d_array_slice_copy(void* dst, size_t dstlen, void* src, size_t srclen, size_t elemsz) {
	auto d = cast(ubyte*) dst;
	auto s = cast(ubyte*) src;
	auto len = dstlen * elemsz;

	while (len) {
		*d = *s;
		d++;
		s++;
		len--;
	}
}

extern(C) void _d_arraybounds(string file, size_t line) {
	// arsd.webassembly.eval(q{ console.error("Range error: " + $0 + ":" + $1); /*, "[" + $2 + ".." + $3 + "] <> " + $4);*/ }, file, line);//, lwr, upr, length);
	_d_assert(file, line);
}

extern(C) void _d_arraybounds_slice(string file, size_t line, size_t lwr, size_t upr, size_t length) {
	_d_assert(file, line);
}

extern(C) void _d_arraybounds_index(string file, size_t line, size_t i, size_t length) {
	_d_assert(file, line);
}

extern(C) void _d_assert(string file, int line) {
	enum msg = "assertion failure";
	jsConsoleLog(msg.ptr, msg.length);
	jsConsoleLog(file.ptr, file.length);

	char[5] buf = '\0';
	foreach_reverse(i; 0.. 5) {
		buf[i] = cast(char) ('0' + line % 10);
		line /= 10;
	}

	jsConsoleLog(buf.ptr, buf.length);
	abort();
}

extern(C) void _d_assert_msg(string msg, string file, uint line) {
	jsConsoleLog(msg.ptr, msg.length);
	_d_assert(file, line);
}

extern(C) size_t strlen(const(char)* str) @system pure @nogc nothrow {
	auto start = str;
	while (*str) {
		str++;
	}
	return cast(size_t) (str - start);
}

// C assert for -betterC
noreturn __assert(const(char)* msg, const(char)* file, uint line) @system {
	jsConsoleLog(file, strlen(file));
	jsAbort(msg, strlen(msg));
}

void _d_array_slice_copy(void* dst, size_t dstlen, void* src, size_t srclen, size_t elemsz) @system {
	auto d = cast(ubyte*) dst;
	auto s = cast(ubyte*) src;
	auto len = dstlen * elemsz;
	while (len) {
		*d = *s;
		d++;
		s++;
		len--;
	}
}

/// Copy `n` bytes from `source` to `destination`
extern(C) void* memcpy(return scope void* destination, scope const void* source, size_t n) @system pure @nogc {
	ubyte* d = cast(ubyte*) destination;
	ubyte* s = cast(ubyte*) source;
	foreach (i; 0..n) {
		d[i] = s[i];
	}
	return destination;
}

/// Set `len` bytes from `source` to `value` (truncated to a byte)
extern(C) void* memset(void* source, int value, size_t len) @system pure @nogc {
	ubyte* dst = cast(ubyte*) source;
	while (len > 0) {
		*dst = cast(ubyte) value;
		dst++;
		len--;
	}
	return source;
}

/// Returns: the difference between the first different byte within `n` bytes of `s0` and `s1`, or 0 if identical
extern(C) int memcmp(scope const void* s0, scope const void* s1, size_t n) @system pure @nogc {
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

void __switch_error(string file, size_t line) @nogc nothrow pure @safe {}

bool __equals(T1, T2)(scope const T1[] lhs, scope const T2[] rhs) {
	if (lhs.length != rhs.length) {
		return false;
	}
	foreach(i; 0..lhs.length) {
		if (lhs[i] != rhs[i]) {
			return false;
		}
	}
	return true;
}

// for closures
extern(C) void* _d_allocmemory(size_t sz) {
	return malloc(sz);
}

template _d_arraysetlengthTImpl(Tarr : T[], T) {
	size_t _d_arraysetlengthT(return scope ref Tarr arr, size_t newlength) pure nothrow @trusted {
		auto orig = arr;
		if (newlength <= arr.length) {
			arr = arr[0..newlength];
		} else {
			auto ptr = cast(T*) realloc(cast(ubyte*) arr.ptr, newlength * T.sizeof);
			arr = ptr[0..newlength];
			if (orig !is null) {
				arr[0.. orig.length] = orig[];
			}
		}
		return newlength;
	}
}
// CLASS / TYPEINFO
// bare basics class support {

version(D_BetterC) {} else:

extern(C) void[] _d_newarrayU(const TypeInfo ti, size_t length) nothrow @trusted {
	size_t elsi = arrayElemSize(ti);
	return cast(void[]) arsdMalloc(length * elsi); // FIXME size actually depends on ti
}

extern(C) void[] _d_newarrayT(const TypeInfo ti, size_t length) {
	auto result = cast(ubyte[]) _d_newarrayU(ti, length);
	// const size = ti.next.tsize;
	result[] = 0; memset(result.ptr, 0, result.length); // size * length
	return cast(void[]) result;
}

extern (C) void[] _d_newarrayiT(const TypeInfo ti, size_t length) nothrow {
	void[] result = _d_newarrayU(ti, length);
	const size = ti.next.tsize;
	memset(result.ptr, 0, size * length); // TODO: use TypeInfo.initializer instead
	return result;
}

private size_t arrayElemSize(const TypeInfo ti, int line = __LINE__) {
	// TODO: ti.next.tsize gives 'indirect null call', abi mismatch?
	return ti.next().tsize();
	// TypeInfo ti =
	if (TypeInfo_Array s = cast(TypeInfo_Array) ti) {
		if (TypeInfo_Struct s1 = cast(TypeInfo_Struct) s.value) {
			return s1.m_init.length;
		} else if (TypeInfo_Const c1 = cast(TypeInfo_Const) s.value) {
			if (TypeInfo_Struct s2 = cast(TypeInfo_Struct) c1.base) {
				return s2.m_init.length;
			}
		} else if (TypeInfo_Invariant i1 = cast(TypeInfo_Invariant) s.value) {
			assert(0, "immutable type");
		} else {
			return s.next().tsize();
		}
		assert(0, "unknown element type");
	} else {
		assert(0, "no array type");
	}
}

extern (C) byte[] _d_arraycatT(const TypeInfo ti, byte[] x, byte[] y) {
	const sizeelem = arrayElemSize(ti); // array element size

	size_t xlen = x.length * sizeelem;
	size_t ylen = y.length * sizeelem;
	size_t len  = xlen + ylen;
	if (!len) {
		return null;
	}
	byte[] p = cast(byte[]) arsdMalloc(len);
	p.ptr[0..xlen] = x[];
	p.ptr[xlen..len] = y[];
	return p[0..x.length+y.length];
}

extern (C) void[] _d_arrayappendT(const TypeInfo ti, ref byte[] x, byte[] y) {
	auto length = x.length;
	const elemSize = arrayElemSize(ti);              // array element size
	cast(void) _d_arrayappendcTX(ti, x, y.length);
	memcpy(x.ptr + length * elemSize, y.ptr, y.length * elemSize);
	return x;
}

extern (C) byte[] _d_arrayappendcTX(const TypeInfo ti, ref byte[] px, size_t n) @trusted {
	const elemSize = arrayElemSize(ti);
	auto newLength = n + px.length;
	auto newSize = newLength * elemSize;
	//import std.stdio; writeln(newSize, " ", newLength);
	ubyte* ptr;
	if (px.ptr is null)
		ptr = arsdMalloc(newSize).ptr;
	else // FIXME: anti-stomping by checking length == used
		ptr = arsdRealloc(cast(ubyte*) px.ptr, newSize).ptr;
	auto ns = ptr[0 .. newSize];
	auto op = px.ptr;
	auto ol = px.length * elemSize;

	foreach(i, b; op[0 .. ol])
		ns[i] = b;

	(cast(size_t *)(&px))[0] = newLength;
	(cast(void **)(&px))[1] = ns.ptr;
	return px;
}

/// Concatenate multiple arrays at once
extern (C) void[] _d_arraycatnTX(const TypeInfo ti, scope byte[][] arrs) {
	size_t length;
	auto size = ti.next.tsize;   // array element size
	foreach(b; arrs) {
		length += b.length;
	}
	if (!length) {
		return null;
	}
	void *a = _d_newarrayU(ti, length).ptr;
	size_t j = 0;
	foreach (b; arrs) {
		if (b.length) {
			memcpy(a + j, b.ptr, b.length * size);
			j += b.length * size;
		}
	}
	return a[0..length];
}

/// Array equality test
extern (C) int _adEq2(void[] a1, void[] a2, TypeInfo ti)
{
	debug(adi) printf("_adEq2(a1.length = %d, a2.length = %d)\n", a1.length, a2.    length);
	if (a1.length != a2.length) {
		return 0;               // not equal
	}
	if (!ti.equals(&a1, &a2)) {
		return 0;
	}
	return 1;
}

extern(C) Object _d_allocclass(TypeInfo_Class ti) {
	auto ptr = (cast(ubyte*)malloc(ti.m_init.length))[0..ti.m_init.length];
	ptr[] = ti.m_init[];
	return cast(Object) ptr.ptr;
}

extern(C) void* _d_dynamic_cast(Object o, TypeInfo_Class c) {
	void* res = null;
	size_t offset = 0;
	if (o && _d_isbaseof2(typeid(o), c, offset)) {
		res = cast(void*) o + offset;
	}
	return res;
}

/// Is `oc` child of `c`?
extern(C) int _d_isbaseof2(scope TypeInfo_Class oc, scope const TypeInfo_Class c, scope ref size_t offset) @safe {
	if (oc is c) {
		return true;
	}
	do {
		if (oc.base is c) {
			return true;
		}
		// Bugzilla 2013: Use depth-first search to calculate offset
		// from the derived (oc) to the base (c).
		foreach (iface; oc.interfaces) {
			if (iface.classinfo is c || _d_isbaseof2(iface.classinfo, c, offset)) {
				offset += iface.offset;
				return true;
			}
		}
		oc = oc.base;
	} while (oc);
	return false;
}

extern(C) void _D9invariant12_d_invariantFC6ObjectZv(Object o) {
	// Object.invariant
}

class Object
{
nothrow:
	/// Convert Object to human readable string
	string toString() const { return "Object"; }
	/// Compute hash function for Object
	size_t toHash() const @trusted nothrow
	{
		auto addr = cast(size_t)cast(void*)this;
		return addr ^ (addr >>> 4);
	}

	/// Compare against another object. NOT IMPLEMENTED!
	int opCmp(Object o) const { assert(false, "not implemented"); }
	/// Check equivalence againt another object
	bool opEquals(Object o) const { return this is o; }
}

/// Returns: `true` if `lhs` and `rhs` are equal
bool opEquals(Object lhs, Object rhs) {
	// If aliased to the same object or both null => equal
	if (lhs is rhs) {
		return true;
	}
	// If either is null => non-equal
	if (lhs is null || rhs is null) {
		return false;
	}
	if (!lhs.opEquals(rhs)) {
		return false;
	}

	// If same exact type => one call to method opEquals
	if (typeid(lhs) is typeid(rhs) || (!__ctfe && typeid(lhs).opEquals(typeid(rhs)))) {
		// CTFE doesn't like typeid much. 'is' works, but opEquals doesn't (issue 7147).
		// But CTFE also guarantees that equal TypeInfos are always identical.
		// So, no opEquals needed during CTFE.
		return true;
	}

	// General case => symmetric calls to method opEquals
	return rhs.opEquals(lhs);
}

/// ditto
bool opEquals(const Object lhs, const Object rhs) {
	return opEquals(cast()lhs, cast()rhs); // A hack for the moment.
}

class Throwable {}

// TYPEINFO

class TypeInfo {
nothrow:
	override string toString() const @safe nothrow {return typeid(this).name;}

	bool opEquals(const TypeInfo ti) @safe nothrow const {return this is ti;}
	size_t getHash(scope const void* p) @trusted nothrow const {return 0;}
	bool equals(void* p1, void* p2) {return p1 == p2;}
	/// Compares two instances for &lt;, ==, or &gt;.
	int compare(in void* p1, in void* p2) const { return _xopCmp(p1, p2); }
	size_t tsize() const {return 1;}
	void swap(void* p1, void* p2) const {}
	const(TypeInfo) next() const {return null;}

	/// Return default initializer. If the type should be initialized to all
	/// zeros, an array with a null ptr and a length equal to the type size will
	/// be returned. For static arrays, this returns the default initializer for
	/// a single element of the array, use `tsize` to get the correct size.
	abstract const(void)[] initializer() const pure nothrow @safe;

	// Get flags for type: 1 means GC should scan for pointers,
	/// 2 means arg of this type is passed in SIMD register(s) if available
	@property uint flags() nothrow pure const @safe @nogc { return 0; }
	/// Get type information on the contents of the type; null if not available
	const(OffsetTypeInfo)[] offTi() const { return null; }
	/// Run the destructor on the object and all its sub-objects
	void destroy(void* p) const {}
	/// Run the postblit on the object and all its sub-objects
	void postblit(void* p) const {}

	/// Return alignment of type
	@property size_t talign() /*nothrow pure @safe @nogc*/ const { return tsize; }

	@property immutable(void)* rtInfo() nothrow pure const @safe @nogc { return null; }
}

class TypeInfo_Class : TypeInfo {
nothrow:
	ubyte[] m_init; /// class static initializer (length gives class size)
	string name; /// name of class
	void*[] vtbl; // virtual function pointer table
	Interface[] interfaces;
	TypeInfo_Class base;
	void* destructor;
	void function(Object) classInvariant;
	uint flags;
	void* deallocator;
	void*[] offTi;
	void function(Object) defaultConstructor;
	immutable(void)* rtInfo;

	override @property size_t tsize() nothrow pure const {return Object.sizeof;}
	override bool equals(in void* p1, in void* p2) const @trusted {
		Object o1 = *cast(Object*) p1;
		Object o2 = *cast(Object*) p2;
		return (o1 is o2) || (o1 && o1.opEquals(o2));
	}
	override const(void)[] initializer() nothrow pure const @safe {return m_init;}
}
class TypeInfo_Pointer : TypeInfo {
nothrow:
	TypeInfo m_next;
	override bool equals(void* p1, void* p2) { return *cast(void**)p1 == *cast(void**)p2; }
	override @property size_t tsize() nothrow pure const { return (void*).sizeof; }
	override const(void)[] initializer() const @trusted { return initZero[0..size_t.sizeof]; }
	override const (TypeInfo) next() const { return m_next; }
}

private immutable ubyte[16] initZero = 0;

class TypeInfo_Array : TypeInfo {
nothrow:
	TypeInfo value;
	override size_t tsize() const { return 2*size_t.sizeof; }
	override const(TypeInfo) next() const { return value; }
	override const(void)[] initializer() const @trusted { return initZero[0..size_t.sizeof*2]; }
}

class TypeInfo_StaticArray : TypeInfo {
nothrow:
	TypeInfo value;
	size_t len;
	override size_t tsize() const { return value.tsize * len; }
	override const(TypeInfo) next() const { return value; }
	override bool equals(void* p1, void* p2) {
		size_t sz = value.tsize;
		for (size_t u = 0; u < len; u++) {
			if (!value.equals(p1 + u * sz, p2 + u * sz)) {
				return false;
			}
		}
		return true;
	}
}

class TypeInfo_Enum : TypeInfo {
nothrow:
	TypeInfo base;
	string name;
	void[] m_init;

	override size_t tsize() const {return base.tsize;}
	override const(TypeInfo) next() const {return base.next;}
	override bool equals(void* p1, void* p2) {return base.equals(p1, p2);}
	override const(void)[] initializer() const @trusted {return m_init;}
}

alias Seq(T...) = T;
static foreach(type; Seq!(
	byte, char, dchar, double, float, int, long, short, ubyte, uint, ulong, ushort, void, wchar
)) {
	mixin(q{
		class TypeInfo_}~type.mangleof~q{ : TypeInfo {
			nothrow:
			override size_t tsize() const { return type.sizeof; }
			override const(void)[] initializer() const @trusted {return initZero[0..type.sizeof];}

			override bool equals(void* a, void* b) {
				static if(is(type == void)) {
					return false;
				} else {
					return (*(cast(type*) a) == (*(cast(type*) b)));
				}
			}
		}
		class TypeInfo_A}~type.mangleof~q{ : TypeInfo_Array {
			nothrow:

			override const(TypeInfo) next() const { return typeid(type); }
			override bool equals(void* av, void* bv) {
				type[] a = *(cast(type[]*) av);
				type[] b = *(cast(type[]*) bv);

				static if(is(type == void)) {
					return false;
				} else {
					foreach(idx, item; a) {
						if(item != b[idx]) {
							return false;
						}
					}
					return true;
				}
			}
		}
	});
}

struct Interface {
	TypeInfo_Class classinfo;
	void*[] vtbl;
	size_t offset;
}

/// Array of pairs giving the offset and type information for each
/// member in an aggregate.
struct OffsetTypeInfo {
	size_t   offset;    /// Offset of member from start of object
	TypeInfo ti;        /// TypeInfo for this member
}

class TypeInfo_Aya : TypeInfo_Aa {

}

class TypeInfo_Delegate : TypeInfo {
nothrow:
	TypeInfo next;
	string deco;
	override size_t tsize() const {return size_t.sizeof * 2;}
}

//Directly copied from LWDR source.
class TypeInfo_Interface : TypeInfo {
nothrow:
	TypeInfo_Class info;

	override bool equals(in void* p1, in void* p2) const {
		Interface* pi = **cast(Interface ***)*cast(void**)p1;
		Object o1 = cast(Object)(*cast(void**)p1 - pi.offset);
		pi = **cast(Interface ***)*cast(void**)p2;
		Object o2 = cast(Object)(*cast(void**)p2 - pi.offset);

		return o1 == o2 || (o1 && o1.opCmp(o2) == 0);
	}

	override const(void)[] initializer() const @trusted {
		return (cast(void *)null)[0 .. Object.sizeof];
	}

	override @property size_t tsize() nothrow pure const {
		return Object.sizeof;
	}
}

class TypeInfo_Const : TypeInfo {
nothrow:
	TypeInfo base;
	override size_t tsize() const {return base.tsize;}
	override const(TypeInfo) next() const {return base.next;}
	override bool equals(void* p1, void* p2) {return base.equals(p1, p2);}
	override const(void)[] initializer() const @trusted {return base.initializer();}
}

class TypeInfo_Invariant : TypeInfo_Const {} // immutable
class TypeInfo_Shared : TypeInfo_Const {}
class TypeInfo_Inout : TypeInfo_Const {}

class TypeInfo_AssociativeArray : TypeInfo {
	TypeInfo value;
	TypeInfo key;
	override @property size_t tsize() nothrow pure const {return (char[int]).sizeof;}
	override @property const(TypeInfo) next() nothrow pure const { return value; }
	override const(void)[] initializer() const @trusted {return (cast(void *)null)[0 .. (char[int]).sizeof];}
	override bool equals(in void* p1, in void* p2) @trusted const {
		assert(0);
		//return !!_aaEqual(this, *cast(const AA*) p1, *cast(const AA*) p2);
	}
}

class TypeInfo_Struct : TypeInfo {
nothrow:
	string mangledName;
	void[] m_init;
	size_t function(in void*) xtohash;
	bool function(in void*, in void*) xopEquals;
	int function(in void*, in void*) xopCmp;
	string function(in void*) xtostring;
	uint flags;
	union {
		void function(void*) xdtor;
		void function(void*, const TypeInfo_Struct) xdtori;
	}
	void function(void*) xpostblit;
	uint align_;
	immutable(void)* m_RTInfo;

	final @property string name() nothrow const @trusted {return mangledName;}
	override string toString() const {return name;}
	override size_t tsize() const {return m_init.length;}
	override const(void)[] initializer() const pure nothrow @safe {return m_init;}

	override bool equals(in void* p1, in void* p2) @trusted
	{
		if (!p1 || !p2) {
			return false;
		} else if (xopEquals) {
			return (*xopEquals)(p1, p2);
		} else if (p1 == p2) {
			return true;
		} else {
			// BUG: relies on the GC not moving objects
			return memcmp(p1, p2, m_init.length) == 0;
		}
	}
}
