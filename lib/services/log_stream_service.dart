import 'dart:async';

class LogEntry {
  final String message;
  final String type;
  final DateTime timestamp;

  LogEntry(this.message, this.type, this.timestamp);
}

class LogStreamService {
  static final StreamController<LogEntry> _controller =
      StreamController<LogEntry>.broadcast();
  static final List<LogEntry> _logs = [];

  static Stream<LogEntry> get logStream => _controller.stream;
  static List<LogEntry> get currentLogs => List.unmodifiable(_logs);

  static void log(String message, {String type = 'INFO'}) {
    final entry = LogEntry(message, type, DateTime.now());
    _logs.add(entry);
    _controller.add(entry);
    // Print to console as well for traditional debugging
    print('[$type] $message');
  }

  static void clear() {
    _logs.clear();
    // Emit a special "clear" event if needed, but for now just clearing the list is enough for newcomers to the stream
    // or we can just send an empty list if we were using a different stream type.
    // For this implementation, we'll just have the UI clear its own state.
    _controller.add(LogEntry('CLEARED', 'SYSTEM', DateTime.now()));
  }
}
