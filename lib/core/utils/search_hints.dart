/// Maps everyday shopping words to DummyJSON category slugs so that fuzzy
/// search terms that match nothing ("mobile", "laptop"...) can fall back to a
/// meaningful category.
const Map<String, String> searchCategoryHints = {
  'mobile': 'smartphones',
  'phone': 'smartphones',
  'smartphone': 'smartphones',
  'iphone': 'mobile-accessories',
  'headphone': 'mobile-accessories',
  'headphones': 'mobile-accessories',
  'earbuds': 'mobile-accessories',
  'laptop': 'laptops',
  'laptops': 'laptops',
  'computer': 'laptops',
  'notebook': 'laptops',
  'macbook': 'laptops',
  'tv': 'home-decoration',
  'television': 'home-decoration',
  'perfume': 'fragrances',
  'perfumes': 'fragrances',
  'fragrance': 'fragrances',
  'cologne': 'fragrances',
  'deodorant': 'fragrances',
  'watch': 'mens-watches',
  'watches': 'mens-watches',
  'wristwatch': 'mens-watches',
  'skincare': 'skincare',
  'skin': 'skincare',
  'cream': 'skincare',
  'lotion': 'skincare',
  'serum': 'skincare',
  'makeup': 'beauty',
  'beauty': 'beauty',
  'cosmetics': 'beauty',
  'shoe': 'mens-shoes',
  'shoes': 'mens-shoes',
  'sneaker': 'mens-shoes',
  'sneakers': 'mens-shoes',
  'boots': 'mens-shoes',
  'heels': 'womens-shoes',
  'flats': 'womens-shoes',
  'dress': 'womens-dresses',
  'dresses': 'womens-dresses',
  'gown': 'womens-dresses',
  'shirt': 'mens-shirts',
  'shirts': 'mens-shirts',
  'tshirt': 'mens-shirts',
  't-shirt': 'mens-shirts',
  'jacket': 'mens-shirts',
  'bag': 'womens-bags',
  'bags': 'womens-bags',
  'handbag': 'womens-bags',
  'backpack': 'womens-bags',
  'purse': 'womens-bags',
  'sunglasses': 'sunglasses',
  'glasses': 'sunglasses',
  'jewelry': 'womens-jewellery',
  'jewellery': 'womens-jewellery',
  'necklace': 'womens-jewellery',
  'earring': 'womens-jewellery',
  'ring': 'womens-jewellery',
  'furniture': 'furniture',
  'sofa': 'furniture',
  'couch': 'furniture',
  'chair': 'furniture',
  'chairs': 'furniture',
  'table': 'furniture',
  'tables': 'furniture',
  'bed': 'furniture',
  'lamp': 'home-decoration',
  'lamps': 'home-decoration',
  'lighting': 'home-decoration',
  'light': 'home-decoration',
  'decor': 'home-decoration',
  'decoration': 'home-decoration',
  'kitchen': 'kitchen-accessories',
  'cookware': 'kitchen-accessories',
  'appliance': 'kitchen-accessories',
  'groceries': 'groceries',
  'grocery': 'groceries',
  'food': 'groceries',
  'snack': 'groceries',
  'snacks': 'groceries',
  'motorcycle': 'motorcycle',
  'bike': 'motorcycle',
  'motorbike': 'motorcycle',
  'helmet': 'motorcycle',
};

/// Returns the category slugs a query might be hinting at, most specific
/// first. Only full word matches count, so "samsung" and "iphone 9" keep
/// behaving as plain text searches.
List<String> inferCategorySlugs(String query) {
  final words = query
      .toLowerCase()
      .trim()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty);
  final matches = <String>[];
  for (final word in words) {
    final slug = searchCategoryHints[word];
    if (slug != null && !matches.contains(slug)) matches.add(slug);
  }
  return matches;
}

/// A human-friendly label for a DummyJSON slug like `mens-shoes`.
String prettyCategoryName(String slug) {
  return slug
      .split('-')
      .where((part) => part.isNotEmpty)
      .map(_capitalize)
      .join(' ');
}

String _capitalize(String word) {
  if (word.isEmpty) return word;
  return word[0].toUpperCase() + word.substring(1).toLowerCase();
}