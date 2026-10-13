import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shop_app/features/products/data/product.dart';

import 'fixtures.dart';

void main() {
  group('Product.fromJson', () {
    test('parses a complete product', () {
      final product = Product.fromJson(productJson());

      expect(product.id, 1);
      expect(product.title, 'Test Product');
      expect(product.description, isNotEmpty);
      expect(product.price, 10);
      expect(product.rating, 4.5);
      expect(product.thumbnail, startsWith('https://'));
      expect(product.images, hasLength(1));
    });

    test('tolerates missing optional fields', () {
      final product = Product.fromJson({
        'id': 2,
        'title': 'Minimal',
      });

      expect(product.description, '');
      expect(product.price, 0);
      expect(product.discountPercentage, 0);
      expect(product.rating, 0);
      expect(product.stock, 0);
      expect(product.images, isEmpty);
    });

    test('toJson round-trips', () {
      final original = sampleProduct(id: 7, title: 'Round Trip');
      expect(Product.fromJson(original.toJson()), original);
    });
  });

  group('Product pricing', () {
    test('finalPrice applies the discount', () {
      final product = sampleProduct(price: 100, discountPercentage: 25);
      expect(product.finalPrice, 75);
    });

    test('finalPrice is full price without discount', () {
      final product = sampleProduct(price: 49.99);
      expect(product.finalPrice, 49.99);
    });

    test('stock drives availability', () {
      expect(sampleProduct(stock: 5).inStock, isTrue);
      expect(sampleProduct(stock: 0).inStock, isFalse);
      expect(sampleProduct(stock: 0).availabilityLabel, 'Out of stock');
    });
  });

  group('ProductListResponse', () {
    test('wraps a product list and totals', () {
      final response = ProductListResponse.fromJson(
        productListJson([productJson(), productJson(id: 2)]),
      );

      expect(response.products, hasLength(2));
      expect(response.total, 2);
    });

    test('handles an empty payload', () {
      final response = ProductListResponse.fromJson(const {'products': <dynamic>[]});
      expect(response.products, isEmpty);
      expect(response.total, 0);
    });
  });

  group('ProductCategory', () {
    test('parses slug and name', () {
      const json = {'slug': 'beauty', 'name': 'Beauty'};
      final category = ProductCategory.fromJson(json);
      expect(category.slug, 'beauty');
      expect(category.name, 'Beauty');
    });
  });
}