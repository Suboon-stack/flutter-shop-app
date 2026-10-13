import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_shop_app/core/api/api_client.dart';
import 'package:flutter_shop_app/features/products/data/product_repository.dart';

import 'fixtures.dart';

void main() {
  late Uri? lastUri;

  ProductRepository buildRepo({int statusCode = 200, Object? body}) {
    lastUri = null;
    final client = MockClient((request) async {
      lastUri = request.url;
      return http.Response(
        body is String ? body : jsonEncode(body),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    });
    return ProductRepository(ApiClient(client: client));
  }

  test('GET /products with pagination and select params', () async {
    final repo =
        buildRepo(body: productListJson([productJson(), productJson(id: 2)]));

    final response = await repo.fetch(limit: 20, skip: 40);

    expect(lastUri!.path, '/products');
    expect(lastUri!.queryParameters['limit'], '20');
    expect(lastUri!.queryParameters['skip'], '40');
    expect(lastUri!.queryParameters['select'], contains('thumbnail'));
    expect(lastUri!.queryParameters.containsKey('q'), isFalse);
    expect(response.products, hasLength(2));
  });

  test('GET /products/category/{slug} when a category is set', () async {
    final repo = buildRepo(body: productListJson([productJson()]));

    await repo.fetch(category: 'beauty');

    expect(lastUri!.path, '/products/category/beauty');
  });

  test('GET /products/search with q when searching', () async {
    final repo = buildRepo(body: productListJson([productJson()]));

    await repo.fetch(query: 'phone');

    expect(lastUri!.path, '/products/search');
    expect(lastUri!.queryParameters['q'], 'phone');
  });

  test('Adds sortBy and order params when sorting', () async {
    final repo = buildRepo(body: productListJson([productJson()]));

    await repo.fetch(sortBy: 'price', ascending: false);

    expect(lastUri!.queryParameters['sortBy'], 'price');
    expect(lastUri!.queryParameters['order'], 'desc');
  });

  test('Fetches a single product by id', () async {
    final repo = buildRepo(body: productJson(id: 42));

    final product = await repo.fetchById(42);

    expect(lastUri!.path, '/products/42');
    expect(product.id, 42);
  });

  test('Fetches categories', () async {
    final repo = buildRepo(body: [
      {'slug': 'beauty', 'name': 'Beauty'},
    ]);

    final categories = await repo.fetchCategories();

    expect(categories.single.slug, 'beauty');
  });

  test('Throws ApiException on non-200 responses', () async {
    final repo = buildRepo(statusCode: 500, body: '{}');

    expect(
      () => repo.fetch(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('500'))),
    );
  });

  test('Throws ApiException on malformed response shape', () async {
    final repo = buildRepo(body: <dynamic>['not', 'a', 'map']);

    expect(() => repo.fetch(), throwsA(isA<ApiException>()));
  });
}