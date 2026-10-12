import 'dart:developer' show log;

import 'package:flutter/foundation.dart';

abstract class AppLog {
  static final String _logDivider = "------------------------------------------";
  static final String _redColor = '\x1B[31m';
  static final String _resetColor = '\x1B[0m';

  static void errorLog(String method, dynamic error) {
    if (!kIsWeb) {
      final buffer = StringBuffer();
      buffer.writeln('API $method ERROR');
      buffer.writeln('${_redColor}ERROR: $error$_resetColor'); // Only error text is red
      buffer.writeln(_logDivider);
      log(buffer.toString());
    }
  }

  static void infoLog(String method, dynamic message) {
    if (!kIsWeb) {
      final buffer = StringBuffer();
      buffer.writeln('API $method INFO');
      buffer.writeln('INFO: $message');
      buffer.writeln(_logDivider);
      log(buffer.toString());
    }
  }
}
