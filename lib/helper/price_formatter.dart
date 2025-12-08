import 'package:intl/intl.dart';

String formatRupiah(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id',
    symbol: '',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}
