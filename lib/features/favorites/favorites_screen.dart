import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/home_tab_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import 'favorites_provider.dart';
import '../products/presentation/product_card.dart';

/// Grid of products the user saved.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), centerTitle: true),
      body: favorites.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              subtitle: 'Tap the heart on any product to save it here.',
              actionLabel: 'Browse products',
              onAction: () => ref.read(homeTabProvider.notifier).set(0),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.7,
              ),
              itemCount: favorites.length,
              itemBuilder: (context, index) =>
                  ProductCard(product: favorites[index]),
            ),
    );
  }
}