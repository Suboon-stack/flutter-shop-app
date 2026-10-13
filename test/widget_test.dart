import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shop_app/main.dart' as app;
import 'package:flutter_shop_app/features/products/data/product.dart';
import 'package:flutter_shop_app/features/products/data/product_repository.dart';
import 'package:flutter_shop_app/features/products/presentation/product_list_provider.dart';

import 'fixtures.dart';
import 'support/test_hive.dart';

class _EmptyRepository implements ProductRepository {
  @override
  Future<ProductListResponse> fetch({
    int limit = 20,
    int skip = 0,
    String? category,
    String? query,
    String? sortBy,
    bool ascending = true,
  }) async {
    return ProductListResponse(products: const [], total: 0, skip: skip, limit: limit);
  }

  @override
  Future<Product> fetchById(int id) async => sampleProduct(id: id);

  @override
  Future<List<ProductCategory>> fetchCategories() async => const [];
}

void main() {
  setUpAll(initTestHive);

  testWidgets('ShopApp boots with the shop shell and bottom navigation',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(_EmptyRepository()),
        categoriesProvider.overrideWith(
          (ref) async => const <ProductCategory>[],
        ),
      ],
      child: const app.ShopApp(),
    ));

    // The shell shows the brand and bottom navigation.
    expect(find.text('ShopVerse'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('My Cart'), findsNothing); // offstage until selected

    // Navigating to the cart tab shows the cart screen.
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    expect(find.text('My Cart'), findsOneWidget);
  });
}