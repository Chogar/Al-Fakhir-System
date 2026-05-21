import '../../data/models/order_model.dart';
import 'receipt_print_service.dart';

Future<bool> printOrderReceiptEscPos({
  required OrderDetailDto order,
  required String restaurantName,
  String? printerName,
  bool arabic = false,
  double discountFcfa = 0,
}) async {
  final _ = printerName;
  final outcome = await printThermalReceipt(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
    discountFcfa: discountFcfa,
  );
  return outcome == ReceiptPrintOutcome.printed;
}
