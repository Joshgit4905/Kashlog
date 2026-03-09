import 'dart:js_interop' as js;
import 'memory_helper_base.dart';

@js.JS('performance.memory')
external js.JSObject? get _webMemory;

extension type _WebMemory(js.JSObject _) {
  @js.JS('usedJSHeapSize')
  external int get usedJSHeapSize;
}

class WebMemoryHelper implements MemoryHelper {
  @override
  Future<double> getMemoryUsageMB() async {
    try {
      final mem = _webMemory;
      if (mem != null) {
        final used = (_WebMemory(mem)).usedJSHeapSize;
        return used / (1024 * 1024);
      }
    } catch (e) {
      // ignore
    }
    return 0.0;
  }
}

MemoryHelper getPlatformHelper() => WebMemoryHelper();
