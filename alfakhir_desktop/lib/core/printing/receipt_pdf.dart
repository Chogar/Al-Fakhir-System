/// Libellés ticket (partagés impression thermique / PDF).
class ReceiptPdfLabels {
  const ReceiptPdfLabels._(this.ar);

  final bool ar;

  factory ReceiptPdfLabels.arabic() => const ReceiptPdfLabels._(true);
  factory ReceiptPdfLabels.french() => const ReceiptPdfLabels._(false);

  String receiptNo(int orderNumber) =>
      ar ? 'إيصال رقم $orderNumber' : 'Reçu n°$orderNumber';

  String get date => ar ? 'التاريخ' : 'Date';
  String get service => ar ? 'الخدمة' : 'Service';
  String get table => ar ? 'طاولة' : 'Table';
  String get client => ar ? 'العميل' : 'Client';
  String get status => ar ? 'الحالة' : 'Statut';
  String get colArticle => ar ? 'الصنف' : 'Article';
  String get colQty => ar ? 'الكمية' : 'Qté';
  String get colTotal => ar ? 'المجموع' : 'Total';
  String get subtotal => ar ? 'المجموع الفرعي' : 'Sous-total';
  String get discount =>
      ar ? 'تخفيض على المجموع' : 'Réduction sur le montant total';
  String get total => ar ? 'المجموع' : 'Total';
  String get paid => ar ? 'المدفوع' : 'Payé';
  String get due => ar ? 'المتبقي' : 'Reste';
  String get payments => ar ? 'المدفوعات' : 'Paiements';

  String get customerFooter => ar
      ? 'شكراً لاختياركم مطعم الفاخر\nبالهناء والشفاء !'
      : 'Merci d\'avoir choisi Restaurant Al-Fakhir\nBon appétit !';

  String noteLine(String notes) =>
      ar ? 'ملاحظة : $notes' : 'Note : $notes';

  String serviceType(String code) {
    if (!ar) {
      return switch (code) {
        'DINE_IN' => 'Sur place',
        'TAKEAWAY' => 'À emporter',
        'DELIVERY' => 'Livraison',
        _ => code,
      };
    }
    return switch (code) {
      'DINE_IN' => 'داخل الصالة',
      'TAKEAWAY' => 'سفري',
      'DELIVERY' => 'توصيل',
      _ => code,
    };
  }

  String orderStatus(String code) {
    if (!ar) {
      return switch (code) {
        'PLACED' => 'Enregistrée',
        'PREPARING' => 'En préparation',
        'READY' => 'Prête',
        'SERVED' => 'Servie',
        'PAID' => 'Payée',
        'CANCELLED' => 'Annulée',
        _ => code,
      };
    }
    return switch (code) {
      'PLACED' => 'مسجلة',
      'PREPARING' => 'قيد التحضير',
      'READY' => 'جاهزة',
      'SERVED' => 'مقدمة',
      'PAID' => 'مدفوعة',
      'CANCELLED' => 'ملغاة',
      _ => code,
    };
  }

  String paymentMethod(String code) {
    if (!ar) {
      return switch (code) {
        'CASH' => 'Espèces',
        'MOBILE_MONEY' => 'Mobile money',
        'BANK_CARD' => 'Carte bancaire',
        _ => code,
      };
    }
    return switch (code) {
      'CASH' => 'نقداً',
      'MOBILE_MONEY' => 'محفظة إلكترونية',
      'BANK_CARD' => 'بطاقة',
      _ => code,
    };
  }
}
