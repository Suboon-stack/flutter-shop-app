import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/debouncer.dart';
import '../../../core/utils/search_hints.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/shimmer_grid.dart';
import '../data/product.dart';
import 'product_card.dart';
import 'product_list_provider.dart';

/// Shop landing: search, categories, sort/filter and a product grid.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _searchController = TextEditingController();
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: const Duration(milliseconds: 450));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productListProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debouncer.run(
      () => ref.read(productListProvider.notifier).setQuery(value),
    );
  }

  void _clearSearchHint() {
    _searchController.clear();
    _debouncer.cancel();
    ref.read(productListProvider.notifier).setQuery('');
  }

  Future<void> _openSortFilter() async {
    final state = ref.read(productListProvider);
    final result = await showModalBottomSheet<(SortCriteria, double?, double?, double?)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _SortFilterSheet(
        currentSort: state.sort,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        minRating: state.minRating,
      ),
    );
    if (result == null || !mounted) return;
    final (sort, minPrice, maxPrice, minRating) = result;
    final notifier = ref.read(productListProvider.notifier);
    notifier.setSort(sort);
    notifier.applyPriceRating(
      minPrice: minPrice,
      maxPrice: maxPrice,
      minRating: minRating,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(productListProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ShopVerse',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Discover great deals',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openSortFilter,
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Sort & filter',
          ),
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              mode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (_showSearchHint(state)) _SearchHintBar(state: state, onClear: _clearSearchHint),
          _CategoryChips(selected: state.category),
          const SizedBox(height: 8),
          Expanded(child: _buildContent(state)),
        ],
      ),
    );
  }

  Widget _buildContent(ProductListState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const ShimmerGrid();
    }
    if (state.error != null && state.products.isEmpty) {
      return ErrorView(
        message: state.error,
        onRetry: () => ref.read(productListProvider.notifier).retry(),
      );
    }
    if (state.filtered.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No products found',
        subtitle: 'Try a different search or clear the filters.',
        actionLabel: state.minPrice != null ||
                state.maxPrice != null ||
                state.minRating != null ||
                state.sort != SortCriteria.relevance
            ? 'Clear filters'
            : null,
        onAction: () {
          final notifier = ref.read(productListProvider.notifier);
          notifier.resetFilters();
          notifier.setSort(SortCriteria.relevance);
          if (state.query.isNotEmpty) notifier.setQuery('');
        },
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(productListProvider.notifier).loadInitial(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >
              notification.metrics.maxScrollExtent - 400) {
            ref.read(productListProvider.notifier).loadMore();
          }
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: state.filtered.length + (state.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.filtered.length) {
              return _LoadMoreTile(
                isLoadingMore: state.isLoadingMore,
                onLoadMore: () =>
                    ref.read(productListProvider.notifier).loadMore(),
              );
            }
            return ProductCard(product: state.filtered[index]);
          },
        ),
      ),
    );
  }
}

class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({required this.selected});

  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final notifier = ref.read(productListProvider.notifier);

    final items = <String?>[null, ...?categories.value?.map((c) => c.slug)];

    Widget chip(String? category, String label) {
      final isSelected = selected == category;
      return GestureDetector(
        onTap: () => notifier.setCategory(category),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slug = items[index];
          return chip(
            slug,
            slug == null
                ? 'All'
                : categories.value!
                    .firstWhere(
                      (c) => c.slug == slug,
                      orElse: () => ProductCategory(slug: slug, name: slug),
                    )
                    .name,
          );
        },
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({required this.isLoadingMore, required this.onLoadMore});

  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: isLoadingMore
          ? const CircularProgressIndicator()
          : TextButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('Load more'),
              style: TextButton.styleFrom(foregroundColor: scheme.primary),
            ),
    );
  }
}

class _SortFilterSheet extends StatefulWidget {
  const _SortFilterSheet({
    required this.currentSort,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
  });

  final SortCriteria currentSort;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;

  @override
  State<_SortFilterSheet> createState() => _SortFilterSheetState();
}

class _SortFilterSheetState extends State<_SortFilterSheet> {
  static const double _priceMax = 2000;

  late SortCriteria _sort = widget.currentSort;
  late RangeValues _priceRange = RangeValues(
    widget.minPrice ?? 0,
    widget.maxPrice ?? _priceMax,
  );
  late double _minRating = widget.minRating ?? 0;

  bool get _priceChanged =>
      _priceRange.start != 0 || _priceRange.end != _priceMax;

  void _apply() {
    Navigator.of(context).pop((
      _sort,
      _priceChanged ? _priceRange.start : null,
      _priceChanged ? _priceRange.end : null,
      _minRating > 0 ? _minRating : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Sort & Filter',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Text(
                'Sort by',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              RadioGroup<SortCriteria>(
                groupValue: _sort,
                onChanged: (value) {
                  if (value != null) setState(() => _sort = value);
                },
                child: Column(
                  children: [
                    for (final criteria in SortCriteria.values)
                      RadioListTile<SortCriteria>(
                        value: criteria,
                        title: Text(criteria.label),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Price range',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: _priceMax,
                divisions: 40,
                labels: RangeLabels(
                  '${_priceRange.start.round()}',
                  '${_priceRange.end.round()}',
                ),
                onChanged: (values) => setState(() => _priceRange = values),
              ),
              Text(
                '${_priceRange.start.round()} - ${_priceRange.end.round()}+',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                'Minimum rating',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: _minRating.toStringAsFixed(1),
                      onChanged: (value) => setState(() => _minRating = value),
                    ),
                  ),
                  SizedBox(
                    width: 46,
                    child: Text(
                      _minRating == 0 ? 'Any' : _minRating.toStringAsFixed(1),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _showSearchHint(ProductListState state) =>
    state.query.isNotEmpty && state.queryCategory != null;

class _SearchHintBar extends StatelessWidget {
  const _SearchHintBar({required this.state, required this.onClear});

  final ProductListState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label =
        'Showing ${prettyCategoryName(state.queryCategory!)} for "${state.query}"';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onClear,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}