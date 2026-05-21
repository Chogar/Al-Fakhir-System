import 'package:flutter/material.dart';

import '../core/finance_period.dart';

class AppStrings {
  AppStrings(this.isAr);

  final bool isAr;

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale.languageCode == 'ar');
  }

  String get appTitle => isAr ? 'مطعم الفخير' : 'Al-Fakhir Restaurant';
  String get authInvalid => isAr ? 'تسجيل الدخول غير صالح' : 'Identifiants incorrects';
  String get forbidden => isAr ? 'غير مسموح' : 'Action non autorisée';
  String get apiUnreachable =>
      isAr ? 'الخادم غير متاح' : 'Serveur local inaccessible (vérifiez l’API).';
  String get genericError => isAr ? 'خطأ' : 'Erreur';
  String get cancel => isAr ? 'إلغاء' : 'Annuler';
  String get refresh => isAr ? 'تحديث' : 'Actualiser';

  String get loginTitle => isAr ? 'تسجيل الدخول' : 'Connexion';
  String get loginUsername => isAr ? 'المستخدم' : 'Identifiant';
  String get loginPassword => isAr ? 'كلمة المرور' : 'Mot de passe';
  String get loginSubmit => isAr ? 'دخول' : 'Se connecter';
  String get loginRemember =>
      isAr ? 'تذكر معلوماتي' : 'Mémoriser les informations';
  String get loginResetPassword =>
      isAr ? 'إعادة تعيين كلمة المرور' : 'Réinitialiser le mot de passe';
  String get loginResetTitle =>
      isAr ? 'كلمة مرور جديدة' : 'Nouveau mot de passe';
  String get loginCurrentPassword =>
      isAr ? 'كلمة المرور الحالية' : 'Mot de passe actuel';
  String get loginNewPassword =>
      isAr ? 'كلمة المرور الجديدة' : 'Nouveau mot de passe';
  String get loginConfirmPassword =>
      isAr ? 'تأكيد كلمة المرور' : 'Confirmer le mot de passe';
  String get loginPasswordMismatch =>
      isAr ? 'كلمتا المرور غير متطابقتين' : 'Les mots de passe ne correspondent pas';
  String get loginPasswordChanged =>
      isAr ? 'تم تغيير كلمة المرور' : 'Mot de passe modifié avec succès';
  String get loginApplyReset => isAr ? 'تطبيق' : 'Appliquer';

  String get navHome => isAr ? 'الرئيسية' : 'Accueil';
  String get navTables => isAr ? 'الطاولات' : 'Tables';
  String get navPos => isAr ? 'الصندوق' : 'Caisse';
  String get navMenu => isAr ? 'القائمة' : 'Menu';
  String get navFinance => isAr ? 'المالية' : 'Finances';
  String get navStats => isAr ? 'الإحصائيات' : 'Statistiques';
  String get navUsers => isAr ? 'المستخدمون' : 'Utilisateurs';

  String get posTitle => isAr ? 'نقطة البيع' : 'Point de vente';
  String get posSegmentNew => isAr ? 'بيع جديد' : 'Nouvelle vente';
  String posSegmentHistoryScoped(bool all) =>
      isAr ? 'السجل' : (all ? 'Historique' : 'Mes ventes');
  String get posHistoryScopedHint =>
      isAr ? 'طلباتك فقط' : 'Affichage de vos commandes uniquement.';
  String get posCategoryLabel => isAr ? 'فئة القائمة' : 'Catégorie menu';
  String get posCategoryAll => isAr ? 'الكل' : 'Toutes';
  String get posCartTitle => isAr ? 'السلة' : 'Panier';
  String get posCartHint =>
      isAr ? 'اضغط على منتج لإضافته' : 'Tapez un produit pour l\'ajouter';
  String get posCartEmpty => isAr ? 'السلة فارغة' : 'Panier vide';
  String get posTotal => isAr ? 'المجموع' : 'Total panier';
  String get posServiceType => isAr ? 'نوع الخدمة' : 'Type de service';
  String get posTable => isAr ? 'طاولة' : 'Table';
  String get posTableNone => isAr ? '— لا شيء —' : '— Aucune —';
  String get posServiceDineIn => isAr ? 'في المكان' : 'Sur place';
  String get posServiceTakeaway => isAr ? 'خارجي' : 'À emporter';
  String get posCreateOrder => isAr ? 'إنشاء الطلب' : 'Créer la commande';
  String get posAddOneItem =>
      isAr ? 'أضف منتجاً واحداً على الأقل' : 'Ajoutez au moins un produit';
  String get posOrderTitle => isAr ? 'طلب' : 'Commande';
  String get posFinalTotal => isAr ? 'المجموع النهائي' : 'Total final';
  String get posDiscountOnTotal => isAr ? 'تخفيض (FCFA)' : 'Remise (FCFA)';
  String get posInvalidDiscount => isAr ? 'مبلغ غير صالح' : 'Montant de remise invalide';
  String get posConfirmAndPrint =>
      isAr ? 'تأكيد وطباعة' : 'Confirmer et imprimer';
  String get posOrderPaidPrinted =>
      isAr ? 'تم الدفع والطباعة' : 'Commande encaissée et ticket imprimé';
  String get posOrderSavedPrintCancelled =>
      isAr ? 'تم الحفظ — ألغيت الطباعة' : 'Commande enregistrée — impression annulée';
  String get posOrderSaved => isAr ? 'تم حفظ الطلب' : 'Commande enregistrée';
  String get posPrintFail => isAr ? 'فشل الطباعة' : 'Échec impression';
  String get posSessionTotal => isAr ? 'مبيعات الجلسة' : 'Ventes de la session';
  String get posSessionOrders => isAr ? 'طلبات' : 'commandes';
  String get posDecaissement => isAr ? 'تصفية الصندوق' : 'Décaissement';
  String get posDecaissementTitle =>
      isAr ? 'تصفية وإعادة التعيين' : 'Décaissement de caisse';
  String get posDecaissementConfirm => isAr
      ? 'سيتم حذف سجل المبيعات لهذه الجلسة وإعادة العداد إلى الصفر. متابعة؟'
      : 'L\'historique des ventes de cette session sera supprimé et le compteur remis à zéro. Continuer ?';
  String get posDecaissementDone => isAr
      ? 'تم التصفية — العداد عند الصفر'
      : 'Décaissement effectué — compteur remis à zéro';
  String get posDrawerOpened => isAr ? 'تم فتح الدرج' : 'Tiroir-caisse ouvert';
  String get posDrawerFailed =>
      isAr ? 'تعذر فتح الدرج' : 'Ouverture du tiroir impossible (vérifiez l\'imprimante RJ11)';

  String get financeModalTitle => isAr ? 'فترة مخصصة' : 'Période personnalisée';
  String get financeModalHint =>
      isAr ? 'اختر التواريخ' : 'Choisissez les dates de début et de fin.';
  String get financePickStart => isAr ? 'البداية' : 'Date de début';
  String get financePickEnd => isAr ? 'النهاية' : 'Date de fin';
  String get financeApplyRange => isAr ? 'تطبيق' : 'Appliquer la période';
  String get financeClearCustom => isAr ? 'مسح' : 'Effacer la période';
  String get financeCustomOpen => isAr ? 'مخصص' : 'Période personnalisée';
  String financePeriodSegmentCaption(FinancePeriod p) {
    switch (p) {
      case FinancePeriod.today:
        return isAr ? 'اليوم' : 'Aujourd\'hui';
      case FinancePeriod.week:
        return isAr ? 'أسبوع' : 'Semaine';
      case FinancePeriod.month:
        return isAr ? 'شهر' : 'Mois';
      case FinancePeriod.year:
        return isAr ? 'سنة' : 'Année';
      case FinancePeriod.custom:
        return financeCustomOpen;
    }
  }

  String get homeTitle => isAr ? 'الرئيسية' : 'Tableau de bord';
  String get homeSubtitle =>
      isAr ? 'نظرة عامة على المطعم' : 'Vue d\'ensemble de l\'activité';
  String get homeNoAccess =>
      isAr ? 'لا صلاحية' : 'Vous n\'avez pas accès à l\'accueil.';
  String get homeSectionTables => isAr ? 'الطاولات' : 'Salle';
  String get homeSectionFinance => isAr ? 'المالية' : 'Finances';
  String get homeSectionMySales => isAr ? 'مبيعاتي' : 'Mes ventes';
  String get homeSectionCategories => isAr ? 'حسب الفئة' : 'Ventes par catégorie';
  String get homeSectionTopProducts =>
      isAr ? 'أفضل المنتجات' : 'Meilleures ventes';
  String get homeTablesTotal => isAr ? 'الطاولات' : 'Tables';
  String get homeTablesFree => isAr ? 'متاحة' : 'Libres';
  String get homeTablesOccupied => isAr ? 'مشغولة' : 'Occupées';
  String get homeTablesReserved => isAr ? 'محجوزة' : 'Réservées';
  String get homeOrdersInProgress => isAr ? 'طلبات جارية' : 'Commandes en cours';
  String get homeReservationsToday =>
      isAr ? 'حجوزات اليوم' : 'Réservations aujourd\'hui';
  String get homeRevenueToday => isAr ? 'إيرادات اليوم' : 'CA aujourd\'hui';
  String get homeExpensesToday => isAr ? 'مصروفات اليوم' : 'Dépenses aujourd\'hui';
  String get homeRevenuePeriod => isAr ? 'إيرادات الفترة' : 'CA période';
  String get homeExpensesPeriod => isAr ? 'مصروفات الفترة' : 'Dépenses période';
  String get homeMyRevenueToday => isAr ? 'إيراداتي اليوم' : 'Mon CA aujourd\'hui';
  String get homeMyOrdersToday => isAr ? 'طلباتي اليوم' : 'Mes commandes';
  String get homeUnits => isAr ? 'وحدة' : 'unités';

  String get financePageTitle => isAr ? 'المالية' : 'Finances';
  String get financePageSubtitle =>
      isAr ? 'الإيرادات والمصروفات' : 'Revenus et dépenses';
  String get financeNoAccess =>
      isAr ? 'لا صلاحية' : 'Accès finances non autorisé.';
  String get financeNoExpenses =>
      isAr ? 'لا مصروفات' : 'Aucune dépense sur cette période.';
  String get financeAddExpense => isAr ? 'مصروف جديد' : 'Nouvelle dépense';
  String get financeExpenseLabel => isAr ? 'الوصف' : 'Libellé';
  String get financeExpenseAmount => isAr ? 'المبلغ (FCFA)' : 'Montant (FCFA)';
  String get financeExpenseCategory => isAr ? 'الفئة' : 'Catégorie (optionnel)';
  String get financeExpenseDate => isAr ? 'التاريخ' : 'Date';
  String get financeSaveExpense => isAr ? 'حفظ' : 'Enregistrer';

  String get usersPageTitle => isAr ? 'المستخدمون' : 'Utilisateurs';
  String get usersPageSubtitle =>
      isAr ? 'مديرون فقط' : 'Administrateurs et gérants uniquement';
  String get usersNoAccess =>
      isAr ? 'لا صلاحية' : 'Gestion des utilisateurs non autorisée.';
  String get usersEmpty => isAr ? 'لا مستخدمين' : 'Aucun utilisateur.';
  String get usersActive => isAr ? 'نشط' : 'Actif';
  String get usersInactive => isAr ? 'معطل' : 'Inactif';
  String get usersAddUser => isAr ? 'مستخدم جديد' : 'Nouvel utilisateur';
  String get usersCreateTitle => isAr ? 'إضافة مستخدم' : 'Ajouter un utilisateur';
  String get usersUsername => isAr ? 'اسم المستخدم' : 'Identifiant';
  String get usersPassword => isAr ? 'كلمة المرور' : 'Mot de passe';
  String get usersFullName => isAr ? 'الاسم الكامل' : 'Nom complet (optionnel)';
  String get usersRole => isAr ? 'الدور' : 'Rôle';
  String get usersActiveAccount => isAr ? 'حساب نشط' : 'Compte actif';
  String get usersSave => isAr ? 'إنشاء' : 'Créer';
  String get usersCreatedSuccess =>
      isAr ? 'تم إنشاء المستخدم' : 'Utilisateur créé avec succès';
  String get usersValidationUsername =>
      isAr ? 'معرّف قصير جداً (حرفان على الأقل)' : 'Identifiant trop court (2 caractères min.)';
  String get usersValidationPassword =>
      isAr ? 'كلمة المرور قصيرة (8 أحرف على الأقل)' : 'Mot de passe trop court (8 caractères min.)';
  String get usersSelectRole => isAr ? 'اختر دوراً' : 'Choisissez un rôle';

  String usersRoleLabel(String role) {
    switch (role) {
      case 'ADMIN':
        return isAr ? 'مدير النظام' : 'Administrateur';
      case 'MANAGER':
        return isAr ? 'مدير' : 'Gérant';
      case 'RECEPTIONIST':
        return isAr ? 'استقبال' : 'Réception';
      case 'SERVER':
        return isAr ? 'نادل' : 'Serveur';
      case 'CASHIER':
        return isAr ? 'أمين الصندوق' : 'Caissier';
      default:
        return role;
    }
  }

  String get statsPageTitle => isAr ? 'إحصائيات' : 'Statistiques';
  String get statsPageSubtitle =>
      isAr ? 'المبيعات حسب المستخدم' : 'Répartition des ventes par utilisateur';
  String get statsNoData => isAr ? 'لا توجد بيانات' : 'Aucune donnée sur cette période';
  String get statsTotalRevenue => isAr ? 'إجمالي الإيرادات' : 'Chiffre d\'affaires';
  String get statsTotalOrders => isAr ? 'الطلبات' : 'Commandes';
  String get statsColUser => isAr ? 'المستخدم' : 'Utilisateur';
  String get statsColOrders => isAr ? 'طلبات' : 'Commandes';
  String get statsColRevenue => isAr ? 'الإيرادات' : 'CA (FCFA)';
  String get statsColShare => isAr ? 'الحصة' : 'Part';
  String statsRoleHint(String username) => username;
}
