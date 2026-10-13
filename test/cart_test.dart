import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shop_app/features/cart/cart_provider.dart';
import 'package:flutter_shop_app/features/cart/data/cart_store.dart';

import 'fixtures.dart';
import 'support/test_hive.dart';

void main() {
  setUpAll(initTestHive);
  setUp(clearTestHive);

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [cartStoreProvider.overrideWithValue(CartStore())],
    );
    addTearDown(container.dispose);
  });

  test('starts empty', () {
    expect(container.read(cartProvider), isEmpty);
  });

  test('add() inserts or increases quantity', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(sampleProduct(id: 1));
    cart.add(sampleProduct(id: 1));
    cart.add(sampleProduct(id: 2), quantity: 3);

    expect(container.read(cartCountProvider), 5);
    expect(container.read(cartProvider).length, 2);
    expect(container.read(cartProvider)[1]!.quantity, 2);
    expect(container.read(cartProvider)[2]!.quantity, 3);
  });

  test('setQuantity updates and caps out (removes at 0)', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(sampleProduct(id: 1), quantity: 2);
    cart.setQuantity(1, 4);
    expect(container.read(cartProvider)[1]!.quantity, 4);

    cart.setQuantity(1, 0);
    expect(container.read(cartProvider), isEmpty);
  });

  test('removeItem drops a product', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(sampleProduct(id: 1));
    cart.add(sampleProduct(id: 2));
    cart.removeItem(1);
    expect(container.read(cartProvider).keys, {2});
  });

  test('clear empties the cart', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(sampleProduct(id: 1));
    cart.clear();
    expect(container.read(cartProvider), isEmpty);
  });

  test('totals: subtotal, shipping and grand total', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(sampleProduct(id: 1, price: 100, discountPercentage: 10)); // 90
    cart.add(sampleProduct(id: 2, price: 50)); // 50

    expect(container.read(cartSubtotalProvider), closeTo(140, 0.001));
    expect(container.read(cartShippingProvider), 0); // >= threshold
    expect(container.read(cartGrandTotalProvider), closeTo(140, 0.001));
  });

  test('shipping fee applies below the free threshold', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(sampleProduct(id: 1, price: 20));

    expect(container.read(cartSubtotalProvider), 20);
    expect(container.read(cartShippingProvider), shippingFee);
    expect(container.read(cartGrandTotalProvider), closeTo(20 + shippingFee, 0.001));
  });

  test('cart persists across notifier recreation', () {
    final cart = container.read(cartProvider.notifier);
    cart.add(sampleProduct(id: 9, title: 'Persisted'), quantity: 2);

    final freshContainer = ProviderContainer(
      overrides: [cartStoreProvider.overrideWithValue(CartStore())],
    );
    addTearDown(freshContainer.dispose);

    final restored = freshContainer.read(cartProvider);
    expect(restored[9]!.product.title, 'Persisted');
    expect(restored[9]!.quantity, 2);
  });
}