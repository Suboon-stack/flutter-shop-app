import 'package:flutter_shop_app/features/products/data/product.dart';

Map<String, dynamic> productJson({
  int id = 1,
  String title = 'Test Product',
  double price = 10,
  double discountPercentage = 0,
  double rating = 4.5,
  int stock = 10,
}) {
  return {
    'id': id,
    'title': title,
    'description': 'A description for $title.',
    'category': 'beauty',
    'price': price,
    'discountPercentage': discountPercentage,
    'rating': rating,
    'stock': stock,
    'brand': 'TestBrand',
    'thumbnail': 'https://example.com/t$id.png',
    'images': ['https://example.com/t${id}_1.png'],
  };
}

Product sampleProduct({
  int id = 1,
  String title = 'Test Product',
  double price = 10,
  double discountPercentage = 0,
  double rating = 4.5,
  int stock = 10,
}) {
  return Product.fromJson(productJson(
    id: id,
    title: title,
    price: price,
    discountPercentage: discountPercentage,
    rating: rating,
    stock: stock,
  ));
}

Map<String, dynamic> productListJson(List<Map<String, dynamic>> products) {
  return {
    'products': products,
    'total': products.length,
    'skip': 0,
    'limit': products.length,
  };
}