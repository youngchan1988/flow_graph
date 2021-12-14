import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

var _logger = Logger(
  level: kReleaseMode ? Level.info : Level.debug,
  printer: PrettyPrinter(
      stackTraceBeginIndex: 1,
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true),
);

void debug({String? tag, Object? object, String? message}) {
  var tagStr = tag ?? '';
  if (object != null) {
    tagStr += '(${object.runtimeType.toString()})';
  }
  _logger.d('$tagStr: ${message ?? ''}');
}

void warn({String? tag, Object? object, String? message}) {
  var tagStr = tag ?? '';
  if (object != null) {
    tagStr += '(${object.runtimeType.toString()})';
  }
  _logger.w('$tagStr: ${message ?? ''}');
}

void info({String? tag, Object? object, String? message}) {
  var tagStr = tag ?? '';
  if (object != null) {
    tagStr += '(${object.runtimeType.toString()})';
  }
  _logger.i('$tagStr: ${message ?? ''}');
}

void error(
    {String? tag,
    Object? object,
    String? message,
    Object? err,
    StackTrace? trace}) {
  var tagStr = tag ?? '';
  if (object != null) {
    tagStr += '(${object.runtimeType.toString()})';
  }

  _logger.e('$tagStr: ${message ?? ''}', err, trace);
}
