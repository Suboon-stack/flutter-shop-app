import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shop_app/features/favorites/data/favorites_store.dart';
import 'package:flutter_shop_app/features/favorites/favorites_provider.dart';

import 'fixtures.dart';
import 'support/test_hive.dart';

void main() {
  setUpAll(initTestHive);
  setUp(clearTestHive);

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [favoritesStoreProvider.overrideWithValue(FavoritesStore())],
    );
    addTearDown(container.dispose);
  });

  test('starts empty', () {
    expect(container.read(favoritesProvider), isEmpty);
  });

  test('toggle() adds then removes a product', () {
    final favorites = container.read(favoritesProvider.notifier);
    final product = sampleProduct(id: 3);

    favorites.toggle(product);
    expect(favorites.isFavorite(3), isTrue);
    expect(container.read(favoritesProvider), hasLength(1));

    favorites.toggle(product);
    expect(container.read(favoritesProvider), isEmpty);
  });

  test('favorites persist across notifier recreation', () {
    container.read(favoritesProvider.notifier).toggle(
          sampleProduct(id: 5, title: 'Saved'),
        );

    final freshContainer = ProviderContainer(
      overrides: [favoritesStoreProvider.overrideWithValue(FavoritesStore())],
    );
    addTearDown(freshContainer.dispose);

    expect(freshContainer.read(favoritesProvider).single.title, 'Saved');
  });
}