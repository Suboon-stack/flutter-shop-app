import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';

/// Shows the discounted price with the original price struck through.
class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.finalPrice,
    this.originalPrice,
    this.discountLabel,
    this.large = false,
    this.spaced = false,
  });

  final double finalPrice;
  final double? originalPrice;
  final String? discountLabel;
  final bool large;
  final bool spaced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final priceText = Text(
      formatPrice(finalPrice),
      style: (large ? theme.textTheme.titleLarge : theme.textTheme.titleMedium)
          ?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w800,
      ),
    );
    final originalText = originalPrice == null || originalPrice == finalPrice
        ? null
        : Padding(
            padding: EdgeInsets.only(left: spaced ? 8 : 0),
            child: Text(
              formatPrice(originalPrice!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          );
    final discountText = discountLabel == null
        ? null
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              discountLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    final discountParagraph = discountText == null
        ? null
        : <Widget>[
            const SizedBox(width: 8),
            discountText,
          ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        priceText,
        ?originalText,
        ...?discountParagraph,
      ],
    );
  }
}