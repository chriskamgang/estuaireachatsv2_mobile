import 'package:intl/intl.dart';

String formatPrice(num amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount)} FCFA';
}

String formatPriceRange(num min, num max) {
  if (min == max) return formatPrice(min);
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(min)} - ${formatter.format(max)} FCFA';
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
  if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
  return DateFormat('dd/MM/yyyy').format(date);
}
