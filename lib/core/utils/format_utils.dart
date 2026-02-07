import 'package:intl/intl.dart';

class FormatUtils {
  static String formatAmount(dynamic value) {
    if (value == null) return "0";

    // Convert String to number safely
    final num number =
        value is num ? value : num.tryParse(value.toString()) ?? 0;
    final formatter = NumberFormat('#,##0.00');
    return formatter.format(number);
  }

  static String formatCurrency(
    dynamic amount, {
    String locale = 'en_NG',
    String symbol = '₦',
    int decimalDigits = 2,
  }) {
    if (amount == null) return "$symbol 0.00";

    // Convert to number safely
    final num number =
        amount is num ? amount : num.tryParse(amount.toString()) ?? 0;

    final format = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );

    return format.format(number);
  }

  static String getVehicleType(String? vehicle) {
    if (vehicle == null) return 'Car';
    final type = vehicle.toLowerCase();
    if (type.contains('van')) return 'Van';
    if (type.contains('truck')) return 'Truck';
    if (type.contains('motorcycle')) return 'Bike';
    if (type.contains('car')) return 'Car';
    return 'Bike';
  }
}
