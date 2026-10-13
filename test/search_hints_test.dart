import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_shop_app/core/utils/search_hints.dart';

void main() {
  group('inferCategorySlugs', () {
    test('maps mobile keywords to smartphones', () {
      expect(inferCategorySlugs('mobile'), ['smartphones']);
      expect(inferCategorySlugs('MOBILE'), ['smartphones']);
      expect(inferCategorySlugs('Mobile Phone'), ['smartphones']);
      expect(inferCategorySlugs('smartphone'), ['smartphones']);
    });

    test('maps shopping words to their categories', () {
      expect(inferCategorySlugs('laptop'), ['laptops']);
      expect(inferCategorySlugs('perfume'), ['fragrances']);
      expect(inferCategorySlugs('sneakers'), ['mens-shoes']);
      expect(inferCategorySlugs('dress'), ['womens-dresses']);
      expect(inferCategorySlugs('bag'), ['womens-bags']);
      expect(inferCategorySlugs('couch'), ['furniture']);
      expect(inferCategorySlugs('lamp'), ['home-decoration']);
    });

    test('returns unique slugs in first-seen order', () {
      expect(inferCategorySlugs('phone mobile'), ['smartphones']);
      expect(inferCategorySlugs('laptop watch'), ['laptops', 'mens-watches']);
    });

    test('ignores punctuation and partial words', () {
      expect(inferCategorySlugs('mobile!'), ['smartphones']);
      expect(inferCategorySlugs('mobile-phone'), ['smartphones']);
      expect(inferCategorySlugs('mobilephones'), isEmpty);
    });

    test('brand and model terms produce no hint', () {
      expect(inferCategorySlugs('samsung galaxy'), isEmpty);
      expect(inferCategorySlugs('nike air'), isEmpty);
      expect(inferCategorySlugs('shoe'), isNotEmpty); // guard sanity
    });

    test('empty and whitespace queries give no hints', () {
      expect(inferCategorySlugs(''), isEmpty);
      expect(inferCategorySlugs('   '), isEmpty);
    });
  });

  group('prettyCategoryName', () {
    test('title-cases words in a slug', () {
      expect(prettyCategoryName('smartphones'), 'Smartphones');
      expect(prettyCategoryName('mens-shoes'), 'Mens Shoes');
      expect(prettyCategoryName('womens-dresses'), 'Womens Dresses');
      expect(prettyCategoryName('mobile-accessories'), 'Mobile Accessories');
    });
  });
}