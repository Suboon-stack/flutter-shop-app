/// Formats a monetary value as a readable price string.
String formatPrice(num value, {String symbol = r'$'}) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final decimals = parts[1];

  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(whole[i]);
  }

  return '$symbol$buffer.$decimals';
}