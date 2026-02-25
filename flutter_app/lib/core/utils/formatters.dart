import 'package:intl/intl.dart';

class Formatters {
  // Currency Formatter
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  
  // Compact Currency (1K, 1M, 1B)
  static String formatCompactCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B đ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K đ';
    }
    return formatCurrency(amount);
  }
  
  // Date Time Formatters
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
  
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  // Relative Time (2h ago, 1d ago)
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  // Countdown Timer
  static String formatCountdown(Duration duration) {
    if (duration.isNegative) {
      return 'Ended';
    }
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 24) {
      final days = hours ~/ 24;
      return '$days days ${hours % 24}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  // Compact Countdown (for chips)
  static String formatCompactCountdown(Duration duration) {
    if (duration.isNegative) {
      return 'Ended';
    }
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 24) {
      final days = hours ~/ 24;
      return '${days}d';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
  
  // Number Formatter
  static String formatNumber(int number) {
    return NumberFormat('#,###', 'vi_VN').format(number);
  }
}
