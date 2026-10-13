import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shop_app/core/theme/theme_mode_provider.dart';

import 'support/test_hive.dart';

void main() {
  setUpAll(initTestHive);
  setUp(clearTestHive);

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('defaults to system theme', () {
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('toggle flips between light and dark', () {
    final controller = container.read(themeModeProvider.notifier);
    controller.toggle(); // system -> light
    expect(container.read(themeModeProvider), ThemeMode.light);
    controller.toggle(); // light -> dark
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('preference persists', () {
    container.read(themeModeProvider.notifier).set(ThemeMode.dark);

    final freshContainer = ProviderContainer();
    addTearDown(freshContainer.dispose);
    expect(freshContainer.read(themeModeProvider), ThemeMode.dark);
  });
}