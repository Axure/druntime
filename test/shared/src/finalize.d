import core.runtime, core.stdc.stdio, core.thread, core.sys.posix.dlfcn;

void runTest()
{
    Object obj;
    obj = Object.factory("lib.MyFinalizer");
    assert(obj.toString() == "lib.MyFinalizer");
    obj = Object.factory("lib.MyFinalizerBig");
    assert(obj.toString() == "lib.MyFinalizerBig");
}

class NoFinalize
{
    size_t _finalizeCounter;

    ~this()
    {
        ++_finalizeCounter;
    }
}

class NoFinalizeBig : NoFinalize
{
    ubyte[4096] _big = void;
}

extern (C) alias SetFinalizeCounter = void function(shared(size_t*));

void main(string[] args)
{
    auto name = args[0];
    assert(name[$-9 .. $] == "/finalize");
    name = name[0 .. $-8] ~ "lib.so";

    auto h = Runtime.loadLibrary(name);
    assert(h !is null);

    auto nf1 = new NoFinalize;
    auto nf2 = new NoFinalizeBig;

    shared size_t finalizeCounter;
    auto setFinalizeCounter = cast(SetFinalizeCounter)dlsym(h, "setFinalizeCounter");
    setFinalizeCounter(&finalizeCounter);

    runTest();
    auto thr = new Thread(&runTest);
    thr.start();
    thr.join();

    assert(Runtime.unloadLibrary(h));
    assert(finalizeCounter == 4);
    assert(nf1._finalizeCounter == 0);
    assert(nf2._finalizeCounter == 0);
}
