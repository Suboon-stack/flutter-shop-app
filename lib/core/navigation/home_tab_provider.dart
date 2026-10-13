import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index of the currently selected bottom navigation tab.
class HomeTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final homeTabProvider =
    NotifierProvider<HomeTabNotifier, int>(HomeTabNotifier.new);