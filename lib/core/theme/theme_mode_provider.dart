import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../storage/hive_init.dart' show settingsBoxName;

/// Persists the user's theme preference (light / dark / system).
class ThemeModeController extends Notifier<ThemeMode> {
  final Box _settings = Hive.box(settingsBoxName);

  @override
  ThemeMode build() {
    final raw = _settings.get('themeMode') as String?;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  void set(ThemeMode mode) {
    _settings.put('themeMode', mode.name);
    state = mode;
  }

  void toggle() {
    set(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);