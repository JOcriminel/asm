/// Structured application logger.
///
/// Replaces all bare `print()` calls. In production builds log calls are
/// compiled away at the [LogLevel.none] level. Swap the implementation once
/// by changing [AppLogger._level] — all call sites remain unchanged (D).
library;

enum LogLevel { verbose, debug, info, warning, error, none }

class AppLogger {
  static const LogLevel _level = bool.fromEnvironment('dart.vm.product')
      ? LogLevel.none
      : LogLevel.debug;

  static void v(String tag, String message) =>
      _log(LogLevel.verbose, tag, message);

  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void w(String tag, String message) =>
      _log(LogLevel.warning, tag, message);

  static void e(String tag, String message, [Object? error]) {
    _log(LogLevel.error, tag, message);
    if (error != null) _log(LogLevel.error, tag, '  ↳ $error');
  }

  static void _log(LogLevel level, String tag, String message) {
    if (level.index < _level.index) return;
    final prefix = switch (level) {
      LogLevel.verbose => '🔍',
      LogLevel.debug   => '🐛',
      LogLevel.info    => 'ℹ️ ',
      LogLevel.warning => '⚠️ ',
      LogLevel.error   => '❌',
      LogLevel.none    => '',
    };
    // ignore: avoid_print
    print('$prefix [$tag] $message');
  }
}
