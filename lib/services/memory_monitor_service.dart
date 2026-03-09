import 'dart:async';
import 'package:flutter/foundation.dart';
import 'memory_helper.dart';

class MemoryMonitorService {
  static final MemoryMonitorService _instance =
      MemoryMonitorService._internal();
  factory MemoryMonitorService() => _instance;
  MemoryMonitorService._internal();

  final ValueNotifier<double> memoryUsageMB = ValueNotifier<double>(0.0);
  Timer? _timer;
  bool _isActive = false;
  final MemoryHelper _helper = getHelper();

  void start() {
    if (_isActive) return;
    _isActive = true;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final mb = await _helper.getMemoryUsageMB();
      memoryUsageMB.value = double.parse(mb.toStringAsFixed(2));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
  }

  void dispose() {
    stop();
    memoryUsageMB.dispose();
  }
}
