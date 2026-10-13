import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_shop_app/core/api/api_client.dart';
import 'package:flutter_shop_app/features/products/data/product.dart';
import 'package:flutter_shop_app/features/products/data/product_repository.dart';
import 'package:flutter_shop_app/features/products/presentation/product_list_provider.dart';

import 'fixtures.dart';

List<Product> makePage(int start, int count) => [
      for (var i = start; i < start + count; i++)
        sampleProduct(id: i, title: 'Product $i'),
    ];

class FakeProductRepository implements ProductRepository {
  FakeProductRepository({
    List<List<Product>>? allPages,
    Map<String, List<List<Product>>>? categoryPages,
    Map<String, List<List<Product>>>? searchPages,
  })  : allPages = allPages ?? const [],
        categoryPages = categoryPages ?? const {},
        searchPages = searchPages ?? const {};

  final List<List<Product>> allPages;
  final Map<String, List<List<Product>>> categoryPages;
  final Map<String, List<List<Product>>> searchPages;
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

    final pages = query != null && query.trim().isNotEmpty
        ? searchPages[query] ?? const <List<Product>>[]
        : category != null
            ? categoryPages[category] ?? const <List<Product>>[]
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
  Future<List<ProductCategory>> fetchCategories() async => const [];

  @override
  Future<Product> fetchById(int id) async => sampleProduct(id: id);
}

void main() {
  late ProviderContainer container;

  ProductListNotifier notifier() => container.read(productListProvider.notifier);

  Future<void> settle() async {
    for (var i = 0; i < 100; i++) {
      final state = container.read(productListProvider);
      if (!state.isLoading && !state.isLoadingMore) return;
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
  }

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  test('loadInitial fetches the first page', () async {
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(allPages: [makePage(0, 20), makePage(20, 5)]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();

    final state = container.read(productListProvider);
    expect(state.isLoading, isFalse);
    expect(state.products, hasLength(20));
    expect(state.total, 25);
    expect(state.hasMore, isTrue);
    expect(state.products.first.title, 'Product 0');
  });

  test('loadMore appends the next page', () async {
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(allPages: [makePage(0, 20), makePage(20, 5)]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();
    await notifier().loadMore();

    final state = container.read(productListProvider);
    expect(state.products, hasLength(25));
    expect(state.hasMore, isFalse);
    expect(state.isLoadingMore, isFalse);
  });

  test('shows an error and retries', () async {
    final fake = FakeProductRepository(allPages: [makePage(0, 3)]);
    fake.error = const ApiException('KABOOM');
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();

    expect(container.read(productListProvider).error, 'KABOOM');

    fake.error = null;
    notifier().retry();
    await settle();

    expect(container.read(productListProvider).error, isNull);
    expect(container.read(productListProvider).products, hasLength(3));
  });

  test('switching category reloads from the category endpoint', () async {
    final fake = FakeProductRepository(
      categoryPages: {
        'beauty': [makePage(0, 2)],
      },
    );
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();
    notifier().setCategory('beauty');
    await settle();

    expect(fake.lastCategory, 'beauty');
    expect(container.read(productListProvider).category, 'beauty');
    expect(container.read(productListProvider).products, hasLength(2));
  });

  test('search sends the query to the server', () async {
    final fake = FakeProductRepository(searchPages: {'led': [makePage(0, 1)]});
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();
    notifier().setQuery('led');
    await settle();

    expect(fake.lastQuery, 'led');
    expect(container.read(productListProvider).query, 'led');
    expect(container.read(productListProvider).products.single.title, 'Product 0');
  });

  test('price and rating filters are applied locally', () async {
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(
          FakeProductRepository(allPages: [
            [
              sampleProduct(id: 1, price: 10, rating: 3),
              sampleProduct(id: 2, price: 200, rating: 5),
              sampleProduct(id: 3, price: 40, rating: 4.7),
            ],
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();
    notifier().applyPriceRating(minPrice: 30, maxPrice: 100, minRating: 4.5);

    final filtered = container.read(productListProvider).filtered;
    expect(filtered.map((p) => p.id), [3]);
  });

  test('falls back to a hinted category when search has no results', () async {
    final fake = FakeProductRepository(
      categoryPages: {
        'smartphones': [makePage(0, 2)],
      },
    );
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();
    notifier().setQuery('mobile');
    await settle();

    final state = container.read(productListProvider);
    expect(fake.lastCategory, 'smartphones');
    expect(state.queryCategory, 'smartphones');
    expect(state.products, hasLength(2));
    expect(state.products.first.title, 'Product 0');
    expect(fake.lastQuery, isNull); // second call was category-based
  });

  test('keeps loading more from the fallback category', () async {
    final fake = FakeProductRepository(
      categoryPages: {
        'smartphones': [makePage(0, 20), makePage(20, 3)],
      },
    );
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();
    notifier().setQuery('mobile');
    await settle();
    await notifier().loadMore();

    final state = container.read(productListProvider);
    expect(state.products, hasLength(23));
    expect(state.queryCategory, 'smartphones');
    expect(state.hasMore, isFalse);
  });

  test('changing the query resets the fallback category', () async {
    final fake = FakeProductRepository(
      searchPages: {
        'samsung': [makePage(0, 1)],
      },
      categoryPages: {
        'smartphones': [makePage(0, 2)],
      },
    );
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    await notifier().loadInitial();
    notifier().setQuery('mobile');
    await settle();
    expect(container.read(productListProvider).queryCategory, 'smartphones');

    notifier().setQuery('samsung');
    await settle();

    final state = container.read(productListProvider);
    expect(state.queryCategory, isNull);
    expect(state.products, hasLength(1));
    expect(fake.lastQuery, 'samsung');
  });
}