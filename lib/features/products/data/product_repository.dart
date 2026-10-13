import '../../../core/api/api_client.dart';
import 'product.dart';

/// Fetches products from the DummyJSON API.
class ProductRepository {
  ProductRepository(this._api);

  final ApiClient _api;

  /// Fetches a page of products.
  ///
  /// [category] and [query] select the DummyJSON endpoint; [sortBy] /
  /// [ascending] configure server-side sorting.
  Future<ProductListResponse> fetch({
    int limit = 20,
    int skip = 0,
    String? category,
    String? query,
    String? sortBy,
    bool ascending = true,
  }) async {
    final path = switch ((category, query)) {
      (final String c, _) => '/products/category/$c',
      (_, final String q) when q.trim().isNotEmpty => '/products/search',
      _ => '/products',
    };

    final params = <String, dynamic>{
      'limit': limit,
      'skip': skip,
      'select': 'id,title,description,category,price,discountPercentage,'
          'rating,stock,brand,thumbnail,images',
    };
    if (query != null && query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }
    if (sortBy != null) {
      params['sortBy'] = sortBy;
      params['order'] = ascending ? 'asc' : 'desc';
    }

    final json = await _api.get(path, params);
    try {
      return ProductListResponse.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException('Unexpected server response.');
    }
  }

  Future<Product> fetchById(int id) async {
    final json = await _api.get('/products/$id');
    try {
      return Product.fromJson(json as Map<String, dynamic>);
    } catch (_) {
      throw const ApiException('Unexpected server response.');
    }
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final json = await _api.get('/products/categories');
    try {
      return (json as List)
          .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const ApiException('Unexpected server response.');
    }
  }
}