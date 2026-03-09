import 'dart:io';
import 'memory_helper_base.dart';

class IoMemoryHelper implements MemoryHelper {
  @override
  Future<double> getMemoryUsageMB() async {
    try {
      final usage = ProcessInfo.currentRss;
      return usage / (1024 * 1024);
    } catch (e) {
      // ignore
    }
    return 0.0;
  }
}

MemoryHelper getPlatformHelper() => IoMemoryHelper();
