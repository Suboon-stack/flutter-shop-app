import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_shop_app/core/storage/hive_init.dart';

/// Initializes Hive in a throwaway temp directory for the test process.
Future<void> initTestHive() async {
  final dir = await Directory.systemTemp.createTemp('shop_test_');
  Hive.init(dir.path);
  await Hive.openBox(cartBoxName);
  await Hive.openBox(favoritesBoxName);
  await Hive.openBox(settingsBoxName);
}

Future<void> clearTestHive() async {
  await Hive.box(cartBoxName).clear();
  await Hive.box(favoritesBoxName).clear();
  await Hive.box(settingsBoxName).clear();
}