__gshared char[4096] stringBuffer;

extern(C):

char* getStringMessageBuffer() { return stringBuffer.ptr; }

void wasmReceiveString(const(char)* ptr, size_t length)
{
    const char[] slice = ptr[0..length];

    auto result = slice ~ "& Knuckles";

    jsReceiveString(result.ptr, result.length);
}

void jsReceiveString(const(char)* ptr, size_t len);
