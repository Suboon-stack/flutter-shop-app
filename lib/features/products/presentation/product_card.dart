import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/price_tag.dart';
import '../../../shared/widgets/rating_stars.dart';
import '../../cart/cart_provider.dart';
import '../../favorites/favorites_provider.dart';
import '../data/product.dart';
import 'product_detail_screen.dart';

/// A single product tile for the browse grid.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    void openDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _FavoriteButton(product: product),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  RatingStars(rating: product.rating, size: 13),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: PriceTag(
                          finalPrice: product.finalPrice,
                          originalPrice: product.price == product.finalPrice
                              ? null
                              : product.price,
                        ),
                      ),
                      _AddToCartButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  const _FavoriteButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(favoritesProvider).any((p) => p.id == product.id);

    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ref.read(favoritesProvider.notifier).toggle(product),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: saved ? const Color(0xFFFF5A79) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _AddToCartButton extends ConsumerWidget {
  const _AddToCartButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      style: IconButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
      ),
      onPressed: () {
        ref.read(cartProvider.notifier).add(product);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${product.title} added to cart'),
              duration: const Duration(seconds: 2),
            ),
          );
      },
      icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
      tooltip: 'Add to cart',
    );
  }
}