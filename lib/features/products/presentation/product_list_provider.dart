import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/search_hints.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(apiClientProvider)),
);

/// Available sorting options (applied server-side).
enum SortCriteria {
  relevance('Relevance', null),
  priceAsc('Price: Low to High', 'price'),
  priceDesc('Price: High to Low', 'price'),
  ratingDesc('Top Rated', 'rating'),
  titleAsc('Name A-Z', 'title');

  const SortCriteria(this.label, this.apiField);
  final String label;
  final String? apiField;
}

/// Immutable browse state: loaded pages + active filters.
class ProductListState {
  const ProductListState({
    this.products = const [],
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.category,
    this.queryCategory,
    this.sort = SortCriteria.relevance,
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });

  final List<Product> products;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String query;
  final String? category;
  /// Category a search fell back to when the raw query matched nothing.
  final String? queryCategory;
  final SortCriteria sort;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;

  bool get hasMore => products.length < total;

  /// Products after applying the local (price / rating) filters.
  List<Product> get filtered => products.where((product) {
        final price = product.finalPrice;
        return (minPrice == null || price >= minPrice!) &&
            (maxPrice == null || price <= maxPrice!) &&
            (minRating == null || product.rating >= minRating!);
      }).toList(growable: false);

  ProductListState copyWith({
    List<Product>? products,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    String? query,
    String? category,
    bool clearCategory = false,
    String? queryCategory,
    bool clearQueryCategory = false,
    SortCriteria? sort,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    double? minRating,
    bool clearMinRating = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : error ?? this.error,
      query: query ?? this.query,
      category: clearCategory ? null : category ?? this.category,
      queryCategory:
          clearQueryCategory ? null : queryCategory ?? this.queryCategory,
      sort: sort ?? this.sort,
      minPrice: clearMinPrice ? null : minPrice ?? this.minPrice,
      maxPrice: clearMaxPrice ? null : maxPrice ?? this.maxPrice,
      minRating: clearMinRating ? null : minRating ?? this.minRating,
    );
  }
}

/// Drives browsing: pagination, search, category and sorting.
class ProductListNotifier extends Notifier<ProductListState> {
  static const int pageSize = 20;

  ProductRepository get _repo => ref.read(productRepositoryProvider);

  @override
  ProductListState build() => const ProductListState();

  Future<void> loadInitial() async {
    final query = state.query;
    final category = state.queryCategory ?? state.category;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Plain text search first...
      if (query.isNotEmpty && category == null) {
        final response = await _repo.fetch(
          limit: pageSize,
          skip: 0,
          query: query,
          sortBy: state.sort.apiField,
          ascending: state.sort != SortCriteria.priceDesc,
        );
        // ...then fall back to a hinted category when nothing matches.
        if (response.products.isEmpty) {
          final hints = inferCategorySlugs(query);
          if (hints.isNotEmpty) {
            final hint = hints.first;
            state = state.copyWith(queryCategory: hint, isLoading: true);
            final fallback = await _repo.fetch(
              limit: pageSize,
              skip: 0,
              category: hint,
              sortBy: state.sort.apiField,
              ascending: state.sort != SortCriteria.priceDesc,
            );
            state = state.copyWith(
              products: fallback.products,
              total: fallback.total,
              isLoading: false,
              isLoadingMore: false,
              clearError: true,
            );
            return;
          }
        }
        state = state.copyWith(
          products: response.products,
          total: response.total,
          queryCategory: null,
          isLoading: false,
          isLoadingMore: false,
          clearError: true,
        );
        return;
      }

      final response = await _repo.fetch(
        limit: pageSize,
        skip: 0,
        category: category,
        query: category == null ? query : null,
        sortBy: state.sort.apiField,
        ascending: state.sort != SortCriteria.priceDesc,
      );
      state = state.copyWith(
        products: response.products,
        total: response.total,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error.message,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading ||
        state.isLoadingMore ||
        state.error != null ||
        !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true);
    try {
      final category = state.queryCategory ?? state.category;
      final response = await _repo.fetch(
        limit: pageSize,
        skip: state.products.length,
        category: category,
        query: category == null ? state.query : null,
        sortBy: state.sort.apiField,
        ascending: state.sort != SortCriteria.priceDesc,
      );
      state = state.copyWith(
        products: [...state.products, ...response.products],
        total: response.total,
        isLoadingMore: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: error.message,
      );
    }
  }

  void setQuery(String query) {
    if (query == state.query) return;
    state = state.copyWith(query: query, clearQueryCategory: true);
    loadInitial();
  }

  void setCategory(String? category) {
    if (category == state.category) return;
    state = state.copyWith(
      category: category,
      clearCategory: category == null,
      clearQueryCategory: true,
    );
    loadInitial();
  }

  void setSort(SortCriteria sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort, isLoading: true);
    loadInitial();
  }

  void applyPriceRating({
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    state = state.copyWith(
      clearMinPrice: minPrice == null,
      minPrice: minPrice,
      clearMaxPrice: maxPrice == null,
      maxPrice: maxPrice,
      clearMinRating: minRating == null,
      minRating: minRating,
    );
  }

  void resetFilters() => applyPriceRating();

  void retry() => loadInitial();
}

final productListProvider =
    NotifierProvider<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
);

final categoriesProvider =
    FutureProvider<List<ProductCategory>>((ref) {
  return ref.watch(productRepositoryProvider).fetchCategories();
});