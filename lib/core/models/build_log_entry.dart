enum LogLevel { info, success, warning, error, header }

class BuildLogEntry {
  final DateTime timestamp;
  final String message;
  final LogLevel level;

  BuildLogEntry(
    this.message, {
    this.level = LogLevel.info,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
