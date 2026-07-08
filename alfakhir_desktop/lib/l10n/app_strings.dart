import 'package:flutter/material.dart';

import '../core/finance_period.dart';
import '../core/locale/app_locale_scope.dart';

class AppStrings {
  AppStrings(this.isAr);

  final bool isAr;

  /// Textes FR/AR ; se met à jour quand on appuie sur le bouton traduction.
  static AppStrings of(BuildContext context) {
    return AppStrings(AppLocaleScope.watch(context).isArabic);
  }

  String get appTitle => isAr ? 'مطعم الفخير' : 'Al-Fakhir Restaurant';
  String get authInvalid => isAr ? 'تسجيل الدخول غير صالح' : 'Identifiants incorrects';
  String get forbidden => isAr
      ? 'غير مسموح — أعد تسجيل الدخول أو اتصل بالمدير'
      : 'Action non autorisée — reconnectez-vous ou contactez le gérant';
  String get apiUnreachable =>
      isAr ? 'الخادم غير متاح' : 'Serveur local inaccessible (vérifiez l’API).';
  String get genericError => isAr ? 'خطأ' : 'Erreur';
  String get cancel => isAr ? 'إلغاء' : 'Annuler';
  String get save => isAr ? 'حفظ' : 'Enregistrer';
  String get yes => isAr ? 'نعم' : 'Oui';
  String get no => isAr ? 'لا' : 'Non';
  String get retry => isAr ? 'إعادة' : 'Réessayer';
  String get refresh => isAr ? 'تحديث' : 'Actualiser';
  String get allCategories => isAr ? 'كل الفئات' : 'Toutes les catégories';
  String get toggleLanguage =>
      isAr ? 'Français' : 'العربية';

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
  String get navPos => isAr ? 'الصندوق' : 'Caisse';
  String get navMenu => isAr ? 'القائمة' : 'Menu';
  String get menuTabProducts => isAr ? 'المنتجات' : 'Produits';
  String get menuTabCategories => isAr ? 'الفئات' : 'Catégories';
  String get menuNewCategory => isAr ? 'فئة جديدة' : 'Nouvelle catégorie';
  String get menuCategoryCreated => isAr ? 'تم إنشاء الفئة' : 'Catégorie créée';
  String get menuCatFab => isAr ? 'فئة جديدة' : 'Nouvelle catégorie';
  String get menuCatNewTitle => isAr ? 'فئة جديدة' : 'Nouvelle catégorie';
  String get menuCatEditTitle => isAr ? 'تعديل الفئة' : 'Modifier la catégorie';
  String get menuCatLabelFrField => isAr ? 'التسمية (فرنسي)' : 'Libellé (FR)';
  String get menuCatLabelArField => isAr ? 'التسمية (عربي)' : 'Libellé (AR, optionnel)';
  String get menuCatSortField => isAr ? 'الترتيب' : 'Ordre d\'affichage';
  String get menuCatLabelRequired =>
      isAr ? 'التسمية الفرنسية مطلوبة (حرفان)' : 'Libellé FR requis (2 caractères min.)';
  String get menuCatSortInvalid =>
      isAr ? 'ترتيب غير صالح' : 'Ordre d\'affichage invalide';
  String get menuCatSaved => isAr ? 'تم حفظ الفئة' : 'Catégorie enregistrée';
  String get menuCatDeleted => isAr ? 'تم حذف الفئة' : 'Catégorie supprimée';
  String get menuCatDeleteTitle => isAr ? 'حذف الفئة؟' : 'Supprimer cette catégorie ?';
  String get menuCatTooltipEdit => isAr ? 'تعديل' : 'Modifier';
  String get menuCatTooltipDelete => isAr ? 'حذف' : 'Supprimer';
  String get menuCatTooltipMerge => isAr ? 'دمج المنتجات' : 'Fusionner les produits';
  String get menuCatColSlug => isAr ? 'المعرّف' : 'Slug';
  String get menuCatColLabelFr => isAr ? 'فرنسي' : 'FR';
  String get menuCatColLabelAr => isAr ? 'عربي' : 'AR';
  String get menuCatColOrder => isAr ? 'ترتيب' : 'Ordre';
  String get menuCatColProducts => isAr ? 'منتجات' : 'Produits';
  String get menuCatNoOtherCategory => isAr
      ? 'لا توجد فئة أخرى للدمج'
      : 'Aucune autre catégorie pour fusionner';
  String get menuCatMergeTitle => isAr ? 'دمج الفئة' : 'Fusionner la catégorie';
  String get menuCatMergeInto => isAr ? 'نقل المنتجات إلى' : 'Déplacer les produits vers';
  String get menuCatMergeAction => isAr ? 'دمج' : 'Fusionner';
  String menuCatMergeSourceIntro(String name, String slug, int count) => isAr
      ? '« $name » ($slug) — $count منتج(ات). '
      : '« $name » ($slug) — $count produit(s). ';
  String get menuCatMergeBody => isAr
      ? 'اختر فئة الوجهة ثم ادمج (يُحذف المصدر).'
      : 'Choisissez la catégorie cible puis fusionnez (la source sera supprimée).';
  String menuCatMergedMoved(int n) => isAr
      ? 'تم نقل $n منتج(ات)'
      : '$n produit(s) déplacé(s)';
  String get menuProdFab => isAr ? 'منتج جديد' : 'Nouveau produit';
  String get menuProdNewTitle => isAr ? 'منتج جديد' : 'Nouveau produit';
  String get menuProdEditTitle => isAr ? 'تعديل المنتج' : 'Modifier le produit';
  String get menuProdNoCategoriesSeed => isAr
      ? 'أنشئ فئة واحدة على الأقل قبل إضافة منتج'
      : 'Créez au moins une catégorie avant d\'ajouter un produit';
  String get menuProdNoCategory =>
      isAr ? 'بدون فئة' : 'Sans catégorie';
  String get menuProdCategoryField => isAr ? 'الفئة' : 'Catégorie';
  String get menuProdNameField => isAr ? 'الاسم (فرنسي)' : 'Nom (FR)';
  String get menuProdNameArField => isAr ? 'الاسم (عربي)' : 'Nom (AR, optionnel)';
  String get menuProdPriceField => isAr ? 'السعر (FCFA)' : 'Prix (FCFA)';
  String get menuProdPickImage => isAr ? 'اختيار صورة' : 'Choisir une image';
  String get menuProdImageField => isAr ? 'صورة المنتج' : 'Photo du produit';
  String get menuProdTapToUpload =>
      isAr ? 'انقر لإضافة صورة' : 'Cliquer pour ajouter une photo';
  String get menuProdChangeImage => isAr ? 'تغيير الصورة' : 'Changer la photo';
  String get menuProdRemoveImage => isAr ? 'إزالة الصورة' : 'Retirer l\'image';
  String get menuProdImageKept => isAr ? 'الصورة الحالية محفوظة' : 'Image actuelle conservée';
  String get menuProdAvailable => isAr ? 'متاح للبيع' : 'Disponible à la vente';
  String get menuProdTrackStock => isAr ? 'تتبع المخزون' : 'Suivre le stock';
  String get menuProdTrackStockSubtitle => isAr
      ? 'كمية افتتاحية وحد تنبيه'
      : 'Quantité initiale et seuil d\'alerte';
  String get menuProdStockQty => isAr ? 'الكمية' : 'Quantité en stock';
  String get menuProdAlertThreshold => isAr ? 'حد التنبيه' : 'Seuil d\'alerte';
  String get menuProdInvalidPrice =>
      isAr ? 'سعر غير صالح' : 'Prix invalide';
  String get menuProdInvalidStockQty =>
      isAr ? 'كمية غير صالحة' : 'Quantité de stock invalide';
  String get menuProdImageNotFound =>
      isAr ? 'الملف غير موجود' : 'Fichier image introuvable';
  String get menuProdUploadFail =>
      isAr ? 'فشل رفع الصورة' : 'Échec du téléversement de l\'image';
  String get menuProdSaved => isAr ? 'تم حفظ المنتج' : 'Produit enregistré';
  String get menuProdDeleted => isAr ? 'تم حذف المنتج' : 'Produit supprimé';
  String get menuProdDisabled => isAr
      ? 'تم تعطيل الطبق (مباع مسبقاً) وإخفاؤه من الصندوق'
      : 'Plat désactivé (déjà vendu) et retiré de la caisse';
  String get menuProdDeleteTitle => isAr ? 'حذف المنتج؟' : 'Supprimer ce produit ?';
  String get menuProdDeleteHint => isAr
      ? 'إذا تم بيع الطبق من قبل، سيتم تعطيله فقط وإخفاؤه من الصندوق.'
      : 'Si le plat a déjà été vendu, il sera seulement désactivé et retiré de la caisse.';
  String get menuProdFilterCategory => isAr ? 'تصفية حسب الفئة' : 'Filtrer par catégorie';
  String get menuProdAllCategoriesHint =>
      isAr ? 'كل الفئات' : 'Toutes les catégories';
  String get menuProdColPhoto => isAr ? 'صورة' : 'Photo';
  String get menuProdColNumber => isAr ? 'رقم' : 'N°';
  String get menuProdColName => isAr ? 'الاسم' : 'Nom';
  String get menuProdColCategory => isAr ? 'الفئة' : 'Catégorie';
  String get menuProdColPrice => isAr ? 'السعر' : 'Prix';
  String get menuProdColStock => isAr ? 'المخزون' : 'Stock';
  String get menuProdColAvailable => isAr ? 'متاح' : 'Dispo.';
  String get menuProdRupture => isAr ? 'نفاد' : 'Rupture';
  String get menuProdStockOk => isAr ? 'متوفر' : 'OK';
  String get posLowStock => isAr ? 'مخزون منخفض' : 'Stock bas';
  String get menuProdTooltipEdit => isAr ? 'تعديل' : 'Modifier';
  String get menuProdTooltipDelete => isAr ? 'حذف' : 'Supprimer';
  String get menuProdColActions => isAr ? 'إجراءات' : 'Actions';
  String get menuProdBtnEdit => isAr ? 'تعديل' : 'Modifier';
  String get menuProdBtnDelete => isAr ? 'حذف' : 'Supprimer';
  String get posErrorGeneric => isAr ? 'خطأ' : 'Erreur';
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
  String get posDrawerFail =>
      isAr ? 'لم يُفتح الدرج — تحقق من الطابعة XP-58C والكابل RJ11' : 'Tiroir non ouvert — vérifiez l\'imprimante XP-58C et le câble RJ11';
  String get posSessionTotal => isAr ? 'مبيعات الجلسة' : 'Ventes de la session';
  String get posSessionOrders => isAr ? 'طلبات' : 'commandes';
  String get posDecaissement => isAr ? 'تصفية الصندوق' : 'Décaissement';
  String get posDecaissementTitle =>
      isAr ? 'تصفية وإعادة التعيين' : 'Décaissement de caisse';
  String get posDecaissementConfirm => isAr
      ? 'سيتم حذف سجل المبيعات لهذه الجلسة وإعادة العداد إلى الصفر. متابعة؟'
      : 'L\'historique des ventes de cette session sera supprimé et le compteur remis à zéro. Continuer ?';
  String get posCancelSale => isAr ? 'إلغاء البيع' : 'Annuler la vente';
  String get posCancelSaleTitle => isAr ? 'إلغاء البيع؟' : 'Annuler cette vente ?';
  String posCancelSaleConfirm(int orderNumber) => isAr
      ? 'سيتم إلغاء الطلب #$orderNumber وإرجاع المخزون.'
      : 'La commande #$orderNumber sera annulée et le stock sera réintégré.';
  String get posSaleCancelled => isAr ? 'تم إلغاء البيع' : 'Vente annulée';
  String get posDecaissementDone => isAr
      ? 'تم التصفية — العداد عند الصفر'
      : 'Décaissement effectué — compteur remis à zéro';

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
  String get homeSectionActivity => isAr ? 'النشاط' : 'Activité';
  String get homeSectionFinance => isAr ? 'المالية' : 'Finances';
  String get homeSectionMySales => isAr ? 'مبيعاتي' : 'Mes ventes';
  String get homeSectionCategories => isAr ? 'حسب الفئة' : 'Ventes par catégorie';
  String get homeSectionTopProducts =>
      isAr ? 'أفضل المنتجات' : 'Meilleures ventes';
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
  String get statsPageSubtitle => isAr
      ? 'المبيعات حسب المستخدم والمنتج'
      : 'Ventes par utilisateur et par produit';
  String get statsNoData => isAr ? 'لا توجد بيانات' : 'Aucune donnée sur cette période';
  String get statsTotalRevenue => isAr ? 'إجمالي الإيرادات' : 'Chiffre d\'affaires';
  String get statsTotalOrders => isAr ? 'الطلبات' : 'Commandes';
  String get statsColUser => isAr ? 'المستخدم' : 'Utilisateur';
  String get statsColOrders => isAr ? 'طلبات' : 'Commandes';
  String get statsColRevenue => isAr ? 'الإيرادات' : 'CA (FCFA)';
  String get statsColShare => isAr ? 'الحصة' : 'Part';
  String statsRoleHint(String username) => username;
  String get statsExportPdf => isAr ? 'تصدير PDF' : 'Exporter en PDF';
  String get statsExportPdfHint => isAr
      ? 'حمّل البيانات أولاً (مبيعات على الفترة)'
      : 'Chargez des données de ventes sur la période';
  String get statsExportPdfSuccess =>
      isAr ? 'تم حفظ تقرير المبيعات' : 'Rapport des ventes enregistré';
  String get statsExportPdfError =>
      isAr ? 'فشل تصدير PDF' : 'Échec de l\'export PDF';
  String get statsExportPdfPeriod => isAr ? 'الفترة' : 'Période';
  String get statsExportPdfGenerated =>
      isAr ? 'تاريخ الإنشاء' : 'Généré le';
  String get statsSectionByUser =>
      isAr ? 'المبيعات حسب المستخدم' : 'Ventes par utilisateur';
  String get statsSectionByProduct =>
      isAr ? 'المبيعات حسب المنتج' : 'Ventes par produit';
  String get statsColProduct => isAr ? 'المنتج' : 'Produit';
  String get statsColQuantity => isAr ? 'الكمية' : 'Quantité vendue';
  String get statsProductsNone =>
      isAr ? 'لا منتجات مباعة' : 'Aucun produit vendu sur cette période';
  String get statsProductsTotal => isAr ? 'المجموع' : 'Total produits';
}
