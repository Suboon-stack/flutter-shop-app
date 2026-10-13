import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../products/data/product.dart';
import 'data/favorites_store.dart';

final favoritesStoreProvider = Provider<FavoritesStore>((ref) => FavoritesStore());

/// The user's saved products.
class FavoritesNotifier extends Notifier<List<Product>> {
  FavoritesStore get _store => ref.read(favoritesStoreProvider);

  @override
  List<Product> build() => _store.load();

  bool isFavorite(int id) => state.any((product) => product.id == id);

  void toggle(Product product) {
    state = isFavorite(product.id)
        ? state.where((p) => p.id != product.id).toList()
        : [...state, product];
    _persist();
  }

  void _persist() => _store.save(state);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<Product>>(FavoritesNotifier.new);