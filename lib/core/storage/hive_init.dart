import 'package:hive_flutter/hive_flutter.dart';

const String cartBoxName = 'cart';
const String favoritesBoxName = 'favorites';
const String settingsBoxName = 'settings';

/// Opens every Hive box the app needs. Call once before `runApp`.
Future<void> initHiveStorage() async {
  await Hive.initFlutter();
  await Hive.openBox(cartBoxName);
  await Hive.openBox(favoritesBoxName);
  await Hive.openBox(settingsBoxName);
}