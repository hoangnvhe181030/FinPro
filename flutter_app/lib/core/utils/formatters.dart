import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  );

  static final _compactFormat = NumberFormat.compact(locale: 'vi_VN');

  static String formatCurrency(dynamic amount) {
    if (amount == null) return '0đ';
    final value = amount is double ? amount : double.tryParse(amount.toString()) ?? 0;
    return _currencyFormat.format(value);
  }

  static String formatCompactCurrency(dynamic amount) {
    if (amount == null) return '0đ';
    final value = amount is double ? amount : double.tryParse(amount.toString()) ?? 0;
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M đ';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K đ';
    }
    return '${value.toStringAsFixed(0)}đ';
  }

  static String formatCompactCountdown(Duration d) {
    if (d.isNegative) return 'Ended';
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }

  static String formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd/MM').format(dt);
  }
}
