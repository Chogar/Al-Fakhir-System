import '../../data/models/order_model.dart';
import 'receipt_ticket_text.dart';

Future<bool> printOrderReceiptAsText({
  required OrderDetailDto order,
  required String restaurantName,
  required String printerName,
  bool arabic = false,
}) async {
  // Fallback logic intentionally simplified during restore.
  final _ = buildReceiptTicketText(
    order: order,
    restaurantName: restaurantName,
    arabic: arabic,
  );
  return false;
}
