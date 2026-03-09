export 'memory_helper_base.dart';
import 'memory_helper_base.dart';
import 'memory_helper_stub.dart'
    if (dart.library.js_interop) 'memory_helper_web.dart'
    if (dart.library.io) 'memory_helper_io.dart';

MemoryHelper getHelper() => getPlatformHelper();
