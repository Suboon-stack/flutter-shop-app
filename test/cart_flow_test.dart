import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shop_app/features/cart/presentation/cart_screen.dart';
import 'package:flutter_shop_app/features/cart/cart_provider.dart';
import 'package:flutter_shop_app/features/cart/data/cart_item.dart';
import 'package:flutter_shop_app/features/favorites/data/favorites_store.dart';
import 'package:flutter_shop_app/features/favorites/favorites_provider.dart';

import 'fixtures.dart';
import 'support/memory_cart_store.dart';
import 'support/test_hive.dart';

/// Builds a seeded, in-memory cart store and the app that uses it.
(ProviderScope, MemoryCartStore) _cartApp(List<CartItem> items) {
  final store = MemoryCartStore()..save(items);
  final scope = ProviderScope(
    overrides: [
      cartStoreProvider.overrideWithValue(store),
      favoritesStoreProvider.overrideWithValue(FavoritesStore()),
    ],
    child: const MaterialApp(home: CartScreen()),
  );
  return (scope, store);
}

void main() {
  setUpAll(initTestHive);
  setUp(clearTestHive);

  testWidgets('shows an empty state when the cart has no items', (tester) async {
    final (scope, _) = _cartApp([]);
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Browse products'), findsOneWidget);
    expect(find.text('Checkout'), findsNothing);
  });

  testWidgets(r'renders items, quantities and totals; free shipping above $50',
      (tester) async {
    final items = [
      CartItem(product: sampleProduct(id: 1, title: 'Serum', price: 100), quantity: 2),
      CartItem(product: sampleProduct(id: 2, title: 'Moisturizer', price: 50), quantity: 1),
    ];
    final (scope, _) = _cartApp(items);
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    expect(find.text('Serum'), findsOneWidget);
    expect(find.text('Moisturizer'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // Serum quantity
    expect(find.text('1'), findsOneWidget); // Moisturizer quantity
    expect(find.text('Subtotal (3 items)'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget); // 250 >= free threshold
    expect(find.text(r'$250.00'), findsNWidgets(2)); // subtotal + total
  });

  testWidgets('quantity controls update the running total', (tester) async {
    final items = [
      CartItem(product: sampleProduct(id: 1, title: 'Serum', price: 10), quantity: 1),
    ];
    final (scope, _) = _cartApp(items);
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    expect(find.text(r'$10.00'), findsNWidgets(2)); // unit price + subtotal
    // Shipping fee applies below the threshold.
    expect(find.text(r'$5.99'), findsOneWidget);
    expect(find.text(r'$15.99'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text(r'$20.00'), findsOneWidget);
    expect(find.text(r'$25.99'), findsOneWidget); // still below threshold
  });

  testWidgets('remove button deletes an item', (tester) async {
    final items = [
      CartItem(product: sampleProduct(id: 1, title: 'Serum'), quantity: 1),
    ];
    final (scope, _) = _cartApp(items);
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('checkout flow renders the order summary and places an order',
      (tester) async {
    final items = [
      CartItem(product: sampleProduct(id: 1, price: 100), quantity: 1),
    ];
    final (scope, store) = _cartApp(items);
    await tester.pumpWidget(scope);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Shipping details'), findsOneWidget);
    expect(find.text('Items (1)'), findsOneWidget);

    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your name'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full name'), 'Zay Yar Min');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone number'), '+66012345678');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Shipping address'), 'Bangkok, Thailand');

    await tester.ensureVisible(find.text('Place Order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place Order'));
    await tester.pumpAndSettle();

    expect(find.text('Order placed!'), findsOneWidget);
    expect(find.textContaining('Order #'), findsOneWidget);
    expect(find.text('Continue Shopping'), findsOneWidget);

    // The cart is empty again after ordering.
    expect(store.load(), isEmpty);
  });
}