import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shop_app/core/api/api_client.dart';
import 'package:flutter_shop_app/features/cart/cart_provider.dart';
import 'package:flutter_shop_app/features/cart/data/cart_store.dart';
import 'package:flutter_shop_app/features/favorites/data/favorites_store.dart';
import 'package:flutter_shop_app/features/favorites/favorites_provider.dart';
import 'package:flutter_shop_app/features/products/data/product.dart';
import 'package:flutter_shop_app/features/products/data/product_repository.dart';
import 'package:flutter_shop_app/features/products/presentation/browse_screen.dart';
import 'package:flutter_shop_app/features/products/presentation/product_list_provider.dart';
import 'package:flutter_shop_app/shared/widgets/shimmer_grid.dart';

import 'fixtures.dart';
import 'support/test_hive.dart';

class _FakeRepository implements ProductRepository {
  _FakeRepository({List<List<Product>>? allPages, this.categoryPages = const {}})
      : allPages = allPages ?? [makePage(0, 3)];

  final List<List<Product>> allPages;
  final Map<String, List<List<Product>>> categoryPages;
  final List<ProductCategory> categories = const [
    ProductCategory(slug: 'beauty', name: 'Beauty'),
    ProductCategory(slug: 'fragrances', name: 'Fragrances'),
  ];
  Object? error;
  String? lastCategory;
  String? lastQuery;

  @override
  Future<ProductListResponse> fetch({
    int limit = 20,
    int skip = 0,
    String? category,
    String? query,
    String? sortBy,
    bool ascending = true,
  }) async {
    if (error != null) throw error!;
    lastCategory = category;
    lastQuery = query;
    final pages = category != null && categoryPages.containsKey(category)
        ? categoryPages[category]!
        : query != null && query.trim().isNotEmpty
            ? const <List<Product>>[]
            : allPages;
    final flat = pages.expand((page) => page).toList();
    final from = skip.clamp(0, flat.length);
    final to = (from + limit).clamp(0, flat.length);
    return ProductListResponse(
      products: flat.sublist(from, to),
      total: flat.length,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<Product> fetchById(int id) async => sampleProduct(id: id);

  @override
  Future<List<ProductCategory>> fetchCategories() async => categories;
}

List<Product> makePage(int start, int count) => [
      for (var i = start; i < start + count; i++)
        sampleProduct(id: i, title: 'Product $i'),
    ];

ProviderScope _browseApp(_FakeRepository repo) {
  return ProviderScope(
    overrides: [
      productRepositoryProvider.overrideWithValue(repo),
      categoriesProvider.overrideWith(
        (ref) async => repo.fetchCategories(),
      ),
      cartStoreProvider.overrideWithValue(CartStore()),
      favoritesStoreProvider.overrideWithValue(FavoritesStore()),
    ],
    child: const MaterialApp(home: BrowseScreen()),
  );
}

void main() {
  setUpAll(initTestHive);
  setUp(clearTestHive);

  testWidgets('shows a shimmer while loading then the product grid',
      (tester) async {
    await tester.pumpWidget(_browseApp(_FakeRepository()));

    expect(find.byType(ShimmerGrid), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(ShimmerGrid), findsNothing);
    expect(find.text('Product 0'), findsOneWidget);
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('shows an error state and allows retry', (tester) async {
    final repo = _FakeRepository()..error = const ApiException('Network down');
    await tester.pumpWidget(_browseApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Network down'), findsOneWidget);

    repo.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Product 0'), findsOneWidget);
  });

  testWidgets('category chips filter the listing', (tester) async {
    final repo = _FakeRepository();
    await tester.pumpWidget(_browseApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beauty'));
    await tester.pumpAndSettle();

    expect(repo.lastCategory, 'beauty');
  });

  testWidgets('search box sends the query after a delay', (tester) async {
    final repo = _FakeRepository();
    await tester.pumpWidget(_browseApp(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'galaxy');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('No products found'), findsOneWidget);
  });

  testWidgets('search falls back to a hinted category and shows the hint',
      (tester) async {
    final repo = _FakeRepository(categoryPages: {
      'smartphones': [makePage(0, 2)],
    });
    await tester.pumpWidget(_browseApp(repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'mobile');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(repo.lastCategory, 'smartphones');
    expect(find.text('Showing Smartphones for "mobile"'), findsOneWidget);
    expect(find.text('Product 0'), findsOneWidget);
    expect(find.text('Product 1'), findsOneWidget);

    // Clearing the hint returns to the full listing from the repository.
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();
    expect(find.text('Showing Smartphones for "mobile"'), findsNothing);
    expect(repo.lastQuery, isEmpty);
  });
}