import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;

/// Utility that fires [action] only after [duration] passes without a new call.
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 400)});

  final Duration duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels a pending action without invalidating the debouncer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }
}