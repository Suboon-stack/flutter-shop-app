import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../products/data/product.dart';
import 'data/cart_item.dart';
import 'data/cart_store.dart';

final cartStoreProvider = Provider<CartStore>((ref) => CartStore());

/// Free shipping threshold; below it a flat fee applies.
const double freeShippingThreshold = 50;
const double shippingFee = 5.99;

/// The shopping cart: a map of product id -> [CartItem].
class CartNotifier extends Notifier<Map<int, CartItem>> {
  CartStore get _store => ref.read(cartStoreProvider);

  @override
  Map<int, CartItem> build() => _store.load();

  void add(Product product, {int quantity = 1}) {
    final current = Map<int, CartItem>.of(state);
    final existing = current[product.id];
    current[product.id] = CartItem(
      product: product,
      quantity: (existing?.quantity ?? 0) + quantity,
    );
    state = current;
    _persist();
  }

  void setQuantity(int id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final current = Map<int, CartItem>.of(state);
    final item = current[id];
    if (item == null) return;
    current[id] = item.copyWith(quantity: quantity);
    state = current;
    _persist();
  }

  void removeItem(int id) {
    final current = Map<int, CartItem>.of(state)..remove(id);
    state = current;
    _persist();
  }

  void clear() {
    state = <int, CartItem>{};
    _persist();
  }

  void _persist() => _store.save(state.values.toList());
}

final cartProvider =
    NotifierProvider<CartNotifier, Map<int, CartItem>>(CartNotifier.new);

/// Total number of items in the cart (sum of quantities).
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).values.fold(0, (sum, item) => sum + item.quantity);
});

/// Sum of every line total.
final cartSubtotalProvider = Provider<double>((ref) {
  return ref
      .watch(cartProvider)
      .values
      .fold(0.0, (sum, item) => sum + item.lineTotal);
});

/// Shipping fee based on subtotal.
final cartShippingProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  if (subtotal <= 0) return 0;
  return subtotal >= freeShippingThreshold ? 0 : shippingFee;
});

/// Subtotal + shipping.
final cartGrandTotalProvider = Provider<double>((ref) {
  return ref.watch(cartSubtotalProvider) + ref.watch(cartShippingProvider);
});