import 'package:flutter/material.dart';

class AppLogger {
  static void log(Object? message) {
    debugPrint('[APP] $message');
  }

  static void info(Object? message) {
    debugPrint('[APP][INFO] $message');
  }

  static void warn(Object? message) {
    debugPrint('[APP][WARN] $message');
  }

  static void error(Object? message) {
    debugPrint('[APP][ERROR] $message');
  }
}
