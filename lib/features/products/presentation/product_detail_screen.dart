import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../cart/cart_provider.dart';
import '../../cart/presentation/checkout_screen.dart';
import '../../favorites/favorites_provider.dart';
import '../data/product.dart';

/// Full product view with image gallery, quantity picker and purchase actions.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _imageIndex = 0;

  void _addToCart() {
    ref.read(cartProvider.notifier).add(widget.product, quantity: _quantity);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  void _buyNow() {
    ref.read(cartProvider.notifier).add(widget.product, quantity: _quantity);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final images = product.images.isEmpty
        ? [product.thumbnail]
        : product.images;

    return Scaffold(
      appBar: AppBar(
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final saved =
                  ref.watch(favoritesProvider).any((p) => p.id == product.id);
              return IconButton(
                onPressed: () =>
                    ref.read(favoritesProvider.notifier).toggle(product),
                icon: Icon(
                  saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: saved ? const Color(0xFFFF5A79) : null,
                ),
                tooltip: 'Save',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (index) =>
                      setState(() => _imageIndex = index),
                  itemBuilder: (context, index) => Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: scheme.onSurfaceVariant,
                        size: 48,
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _imageIndex ? 20 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == _imageIndex
                                  ? scheme.primary
                                  : Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (product.brand.isNotEmpty) ...[
                      Text(
                        product.brand.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    RatingStars(rating: product.rating),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.title,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.2),
                ),
                const SizedBox(height: 12),
                PriceTag(
                  finalPrice: product.finalPrice,
                  originalPrice: product.price == product.finalPrice
                      ? null
                      : product.price,
                  discountLabel:
                      product.discountPercentage > 0
                          ? '-${product.discountPercentage.round()}%'
                          : null,
                  large: true,
                  spaced: true,
                ),
                const SizedBox(height: 8),
                Text(
                  product.availabilityLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: product.inStock
                        ? Colors.green.shade600
                        : scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Description',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              _QuantityStepper(
                quantity: _quantity,
                onChanged: (value) => setState(() => _quantity = value),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _addToCart,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('Add to Cart'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _buyNow,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Buy Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            iconSize: 20,
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add_rounded),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}