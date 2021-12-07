import 'dart:developer';

void debug({String? tag, String? message}) {
  log(message ?? '', time: DateTime.now(), name: tag ?? 'Debug');
}

void debugInObject({required Object object, String? message}) {
  debug(tag: object.runtimeType.toString(), message: message);
}

void warn({String? tag, String? message}) {
  log(message ?? '', time: DateTime.now(), name: tag ?? 'Warn');
}

void warnInObject({required Object object, String? message}) {
  warn(tag: object.runtimeType.toString(), message: message);
}

void error({String? tag, String? message, Object? err, StackTrace? trace}) {
  log(message ?? '',
      time: DateTime.now(),
      name: tag ?? 'Error',
      error: err,
      stackTrace: trace);
}

void errorInObject(
    {required Object object, String? message, Object? err, StackTrace? trace}) {
  error(
      tag: object.runtimeType.toString(),
      message: message,
      err: err,
      trace: trace);
}
