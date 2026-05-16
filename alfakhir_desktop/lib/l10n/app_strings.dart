import 'package:flutter/material.dart';

import '../core/finance_period.dart';

/// Chaînes FR / AR + accès [isAr] pour RTL via [MaterialApp.locale].
class AppStrings extends InheritedWidget {
  const AppStrings({
    super.key,
    required this.locale,
    required super.child,
  });

  final Locale locale;

  bool get isAr => locale.languageCode == 'ar';

  static AppStrings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStrings>();
    assert(scope != null, 'AppStrings manquant : enveloppez MaterialApp.builder');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppStrings oldWidget) =>
      oldWidget.locale.languageCode != locale.languageCode;

  // ——— Général ———
  String get appTitle => isAr
      ? 'نظام إدارة مطعم الفاخر'
      : 'Al-Fakhir Restaurant Management System';
  String get cancel => isAr ? 'إلغاء' : 'Annuler';
  String get confirm => isAr ? 'تأكيد' : 'Valider';
  String get save => isAr ? 'حفظ' : 'Enregistrer';
  String get yes => isAr ? 'نعم' : 'Oui';
  String get no => isAr ? 'لا' : 'Non';
  String get retry => isAr ? 'إعادة المحاولة' : 'Réessayer';
  String get noneShort => isAr ? '— بدون —' : '— Aucune —';
  String get allCategories => isAr ? 'الكل' : 'Toutes';
  String get refresh => isAr ? 'تحديث' : 'Actualiser';

  // ——— Connexion ———
  String get loginBrandSubtitle =>
      isAr ? 'إدارة المطعم' : 'Gestion restaurant';
  String get loginContinue =>
      isAr ? 'سجّل الدخول للمتابعة' : 'Connectez-vous pour continuer';
  String get loginUsername => isAr ? 'اسم المستخدم' : 'Nom d’utilisateur';
  String get loginPassword => isAr ? 'كلمة المرور' : 'Mot de passe';
  String get loginButton => isAr ? 'دخول' : 'Se connecter';
  String get loginRememberCredentials => isAr
      ? 'حفظ اسم الدخول وكلمة المرور'
      : 'Mémoriser identifiant et mot de passe';
  String get loginFieldRequired =>
      isAr ? 'هذا الحقل مطلوب' : 'Champ requis';
  String loginPasswordVisibilityTooltip(bool passwordVisible) => passwordVisible
      ? (isAr ? 'إخفاء كلمة المرور' : 'Masquer le mot de passe')
      : (isAr ? 'إظهار كلمة المرور' : 'Afficher le mot de passe');

  // ——— Réseau / API ———
  String get networkTimeout => isAr
      ? 'انتهت مهلة الاتصال بالخادم. تحقق من الشبكة ثم أعد المحاولة.'
      : 'Délai dépassé : le serveur ne répond pas. Vérifiez le réseau puis réessayez.';
  String get networkUnreachable => isAr
      ? 'تعذّر الاتصال بالخادم. تحقق من أن التطبيق يشير إلى عنوان الـ API الصحيح وأن الخادم يعمل.'
      : 'Impossible de joindre le serveur. Vérifiez l’URL de l’API et que le backend est démarré.';
  String get networkUnknown => isAr
      ? 'حدث خطأ غير متوقع أثناء الاتصال.'
      : 'Une erreur réseau inattendue s’est produite.';
  String get networkUnauthorized => isAr
      ? 'غير مصرّح. سجّل الدخول من جديد.'
      : 'Non autorisé. Reconnectez-vous.';
  String get networkCancelled => isAr ? 'تم إلغاء الطلب.' : 'Requête annulée.';
  String networkHttpError(int code) => isAr
      ? 'خطأ HTTP ($code)'
      : 'Erreur HTTP ($code)';

  // ——— Shell ———
  String get shellNavTitle => isAr ? 'التنقل' : 'Navigation';
  String get shellRailFooter => isAr ? 'اختر قسماً' : 'Sélectionnez un module';
  String get shellLogoutTooltip => isAr ? 'تسجيل الخروج' : 'Se déconnecter';
  String get shellLogoutSheet => isAr ? 'تسجيل الخروج' : 'Se déconnecter';
  String get shellConnectedSpace => isAr ? 'مساحة متصلة' : 'Espace connecté';
  String get shellNoAccessTitle =>
      isAr ? 'لا يوجد قسم متاح' : 'Aucun module accessible';
  String get shellNoAccessBody => isAr
      ? 'صلاحياتك الحالية لا تسمح بفتح أي قسم. اتصل بالمسؤول.'
      : 'Vos droits actuels ne permettent d’ouvrir aucune section. '
          'Contactez un administrateur pour ajuster vos permissions.';

  String shellHome(bool ar) => ar ? 'الرئيسية' : 'Accueil';
  String shellTables(bool ar) => ar ? 'الطاولات' : 'Tables';
  String shellPos(bool ar) => ar ? 'الصندوق' : 'Caisse';
  String shellMenu(bool ar) => ar ? 'القائمة' : 'Menu';
  String shellFinance(bool ar) => ar ? 'المالية' : 'Finances';
  String shellStatistics(bool ar) => ar ? 'إحصائيات' : 'Statistiques';

  String get statsPageTitle => isAr ? 'إحصائيات المبيعات' : 'Statistiques';
  String get statsPageSubtitle => isAr
      ? 'مبيعات كل مستخدم (الطلبات المدفوعة).'
      : 'Ventes par utilisateur (commandes payées).';
  String get statsTotalRevenue => isAr ? 'إجمالي المبيعات' : 'CA total';
  String get statsTotalOrders => isAr ? 'عدد الطلبات' : 'Commandes';
  String get statsColUser => isAr ? 'المستخدم' : 'Utilisateur';
  String get statsColOrders => isAr ? 'طلبات' : 'Cmd.';
  String get statsColRevenue => isAr ? 'المبيعات' : 'Ventes';
  String get statsColShare => isAr ? 'الحصة' : 'Part';
  String get statsNoData => isAr
      ? 'لا توجد مبيعات على هذه الفترة.'
      : 'Aucune vente sur cette période.';
  String statsRoleHint(String username) =>
      isAr ? 'تسجيل الدخول : $username' : 'Identifiant : $username';
  String shellUsers(bool ar) => ar ? 'المستخدمون' : 'Utilisateurs';

  String get langFr => 'FR';
  String get langAr => 'عربي';

  // ——— Périodes (finances / stats) ———
  String periodCaption(FinancePeriod p) {
    if (!isAr) return financePeriodCaptionFr(p);
    return switch (p) {
      FinancePeriod.day => 'يوم',
      FinancePeriod.week => 'أسبوع',
      FinancePeriod.month => 'شهر',
      FinancePeriod.year => 'سنة',
      FinancePeriod.custom => 'مخصص',
    };
  }

  String periodSubtitle(FinancePeriod p) {
    if (!isAr) return financePeriodSubtitleFr(p);
    return switch (p) {
      FinancePeriod.day => 'اليوم',
      FinancePeriod.week => 'الأسبوع',
      FinancePeriod.month => 'الشهر',
      FinancePeriod.year => 'السنة',
      FinancePeriod.custom => 'الفترة',
    };
  }

  // ——— Finances ———
  String get financeTitle => isAr ? 'المالية' : 'Finances';
  String get financeSubtitle => isAr
      ? 'ملخص ومصروفات حسب الفترة المختارة.'
      : 'Synthèse et dépenses selon la période choisie.';
  String get financeCustomOpen =>
      isAr ? 'فترة مخصصة…' : 'Personnalisé…';
  String get financeClearCustom => isAr ? 'مسح' : 'Effacer';
  String get financeModalTitle =>
      isAr ? 'اختيار فترة مخصصة' : 'Période personnalisée';
  String get financeModalHint => isAr
      ? 'اختر تاريخ البداية ثم النهاية.'
      : 'Choisissez la date de début puis celle de fin.';
  String get financePickStart => isAr ? 'تاريخ البداية' : 'Date de début';
  String get financePickEnd => isAr ? 'تاريخ النهاية' : 'Date de fin';
  String get financeApplyRange => isAr ? 'تطبيق الفترة' : 'Appliquer la période';
  String get financeKpiTodayRevenue =>
      isAr ? 'إيراد اليوم' : 'CA du jour';
  String get financeKpiTodayExpenses =>
      isAr ? 'مصروفات اليوم' : 'Dépenses du jour';
  String get financeKpiPeriodRevenue =>
      isAr ? 'إيراد الفترة' : 'CA période';
  String get financeKpiPeriodExpenses =>
      isAr ? 'مصروفات الفترة' : 'Dépenses période';
  String get financeExpensesTitle => isAr ? 'المصروفات' : 'Dépenses';
  String get financeNoExpenses => isAr
      ? 'لا توجد مصروفات في هذه الفترة.'
      : 'Aucune dépense dans cette période.';
  String get financeFabExpense => isAr ? 'مصروف' : 'Dépense';
  String get financeNewExpense => isAr ? 'مصروف جديد' : 'Nouvelle dépense';
  String get financeEditExpense => isAr ? 'تعديل مصروف' : 'Modifier dépense';
  String get financeDeleteExpenseTitle =>
      isAr ? 'حذف هذا المصروف؟' : 'Supprimer cette dépense ?';
  String get financeLabelField => isAr ? 'البيان' : 'Libellé';
  String get financeAmountField =>
      isAr ? 'المبلغ (فرنك)' : 'Montant (FCFA)';
  String get financeDateField =>
      isAr ? 'التاريخ (سنة-شهر-يوم)' : 'Date (AAAA-MM-JJ)';
  String get financeCategoryField =>
      isAr ? 'البند (اختياري)' : 'Rubrique (optionnel)';
  String get financeCategoryHint => isAr
      ? 'مثال: وقود، مشتريات…'
      : 'Ex. Achats marché, Carburant…';
  String get financeInvalidAmount =>
      isAr ? 'مبلغ غير صالح' : 'Montant invalide';
  String get financeExpenseSaved =>
      isAr ? 'تم حفظ المصروف' : 'Dépense enregistrée';
  String get financeDeleted => isAr ? 'تم الحذف' : 'Supprimé';

  // ——— Menu ———
  String get menuTabProducts => isAr ? 'الأطباق' : 'Produits';
  String get menuTabCategories => isAr ? 'الفئات' : 'Catégories';
  String get menuPageTitle => isAr ? 'قائمة الطعام' : 'Carte & menu';
  String get menuPageSubtitle => isAr
      ? 'إدارة الأطباق والفئات'
      : 'Gérez les plats et les catégories de la carte';

  // ——— Tableau de bord ———
  String get dashboardOverviewTitle =>
      isAr ? 'نظرة عامة' : 'Vue d’ensemble';
  String get dashboardHeroSubtitle => isAr
      ? 'ملخص سريع: الصالة، الطلبات النشطة ومالية اليوم.'
      : 'Synthèse rapide : salle, file active et finances du jour.';
  String get dashboardKpiTablesTitle => isAr ? 'الطاولات' : 'Tables';
  String get dashboardKpiTablesSubtitle =>
      isAr ? 'سعة قاعة الجلوس' : 'Capacité du plan de salle';
  String get dashboardKpiOrdersTitle =>
      isAr ? 'طلبات قيد التنفيذ' : 'Commandes en cours';
  String get dashboardKpiOrdersSubtitle =>
      isAr ? 'في المطبخ أو الصالة' : 'En cuisine ou en salle';
  String get dashboardKpiRevenueDayTitle => isAr ? 'إيراد اليوم' : 'CA du jour';
  String get dashboardKpiRevenueDaySubtitle =>
      isAr ? 'المقبوضات المسجلة' : 'Encaissements enregistrés';
  String get dashboardKpiExpensesDayTitle =>
      isAr ? 'مصروفات اليوم' : 'Dépenses du jour';
  String get dashboardKpiExpensesDaySubtitle =>
      isAr ? 'خروجيات اليوم' : 'Sorties du jour';
  String get dashboardKpiRevenuePeriodSubtitle =>
      isAr ? 'على الفترة الحالية' : 'Sur la période en cours';
  String get dashboardKpiExpensesPeriodSubtitle =>
      isAr ? 'على نفس الفترة' : 'Sur la même période';
  String get dashboardSalesStatsTitle =>
      isAr ? 'إحصائيات المبيعات' : 'Statistiques de vente';
  String get dashboardSalesStatsSubtitle => isAr
      ? 'الأكثر مبيعاً والتوزيع حسب الفئة.'
      : 'Produits les plus vendus et répartition par catégorie.';
  String get dashboardNoBreakdownData => isAr
      ? 'لا توجد بيانات لهذه الفترة أو صلاحيات غير كافية.'
      : 'Pas de données pour cette période ou droits insuffisants.';
  String get dashboardTopProductsTitle =>
      isAr ? 'أكثر الأطباق مبيعاً' : 'Top produits';
  String get dashboardUnitsAbbr => isAr ? 'وحدة' : 'u.';
  String get dashboardNoSalesPeriod => isAr
      ? 'لا مبيعات في هذه الفترة.'
      : 'Aucune vente sur cette période.';
  String get dashboardByCategoryTitle =>
      isAr ? 'حسب الفئة' : 'Par catégorie';
  String get dashboardOrdersAbbr => isAr ? 'طلب' : 'cmd.';

  String financePeriodSegmentCaption(FinancePeriod p) {
    if (!isAr) return financePeriodCaptionFr(p);
    return switch (p) {
      FinancePeriod.day => 'يوم',
      FinancePeriod.week => 'أسبوع',
      FinancePeriod.month => 'شهر',
      FinancePeriod.year => 'سنة',
      FinancePeriod.custom => 'مخصص',
    };
  }

  String dashboardRevenueKpiTitleForApiPeriod(String? apiPeriod) {
    final p = financePeriodFromApi(apiPeriod);
    if (!isAr) return 'CA ${financePeriodSubtitleFr(p)}';
    return switch (p) {
      FinancePeriod.day => 'إيراد اليوم',
      FinancePeriod.week => 'إيراد الأسبوع',
      FinancePeriod.month => 'إيراد الشهر',
      FinancePeriod.year => 'إيراد السنة',
      FinancePeriod.custom => 'إيراد الفترة',
    };
  }

  String dashboardExpensesKpiTitleForApiPeriod(String? apiPeriod) {
    final p = financePeriodFromApi(apiPeriod);
    if (!isAr) return 'Dépenses ${financePeriodSubtitleFr(p)}';
    return switch (p) {
      FinancePeriod.day => 'مصروفات اليوم',
      FinancePeriod.week => 'مصروفات الأسبوع',
      FinancePeriod.month => 'مصروفات الشهر',
      FinancePeriod.year => 'مصروفات السنة',
      FinancePeriod.custom => 'مصروفات الفترة',
    };
  }

  String get dashboardCategoryEmpty =>
      isAr ? 'لا بيانات.' : 'Aucune donnée.';

  // ——— Menu — produits ———
  String get menuProdNoCategoriesSeed => isAr
      ? 'لا توجد فئات — شغّل تهيئة الخادم (seed).'
      : 'Aucune catégorie — lancez le seed backend.';
  String get menuProdNewTitle =>
      isAr ? 'طبق / مشروب جديد' : 'Nouveau plat / boisson';
  String get menuProdEditTitle => isAr ? 'تعديل' : 'Modifier';
  String get menuProdCategoryField => isAr ? 'الفئة' : 'Catégorie';
  String get menuProdNameField => isAr ? 'الاسم' : 'Nom';
  String get menuProdNameArField =>
      isAr ? 'الاسم بالعربية (اختياري)' : 'Nom en arabe (optionnel)';
  String get menuProdNameArHint =>
      isAr ? 'مثال: كسكس بالخضر' : 'Ex. Couscous aux légumes';
  String get menuProdPriceField => isAr ? 'السعر (فرنك)' : 'Prix (FCFA)';
  String get menuProdPriceHint => isAr ? 'مثال: 2500' : 'ex. 2500';
  String get menuProdPickImage => isAr ? 'اختيار صورة' : 'Choisir une image';
  String get menuProdImageKept =>
      isAr ? 'الصورة الحالية محفوظة' : 'Image actuelle conservée';
  String get menuProdRemoveImage => isAr ? 'إزالة الصورة' : 'Retirer l’image';
  String get menuProdAvailable => isAr ? 'متوفر' : 'Disponible';
  String get menuProdTrackStock => isAr ? 'تتبع المخزون' : 'Suivre le stock';
  String get menuProdTrackStockSubtitle => isAr
      ? 'يُنقص تلقائياً مع كل طلب.'
      : 'Décrémente automatiquement à chaque commande.';
  String get menuProdStockQty => isAr ? 'الكمية في المخزون' : 'Quantité en stock';
  String get menuProdStockQtyHint => isAr ? 'مثال: 12' : 'ex. 12';
  String get menuProdAlertThreshold =>
      isAr ? 'عتبة التنبيه (مخزون منخفض)' : 'Seuil d’alerte (stock bas)';
  String get menuProdAlertHint => isAr ? 'مثال: 5' : 'ex. 5';
  String get menuProdApply => isAr ? 'تطبيق' : 'Appliquer';
  String menuProdAdjustStockTitleNamed(String name) => isAr
      ? 'تعديل المخزون — $name'
      : 'Ajuster le stock — $name';
  String menuProdStockCurrentVal(int n) => isAr
      ? 'المخزون الحالي: $n'
      : 'Stock actuel : $n';
  String get menuProdStockNotTrackedHint => isAr
      ? 'المخزون غير متبوع: أول إدخال موجب يفعّل التتبع.'
      : 'Stock non suivi : la première entrée positive initialisera le suivi.';
  String get menuProdDirectionIn => isAr ? 'إدخال +' : 'Entrée +';
  String get menuProdDirectionOut => isAr ? 'إخراج −' : 'Sortie −';
  String get menuProdQtyField => isAr ? 'الكمية' : 'Quantité';
  String get menuProdReasonField =>
      isAr ? 'السبب (اختياري)' : 'Motif (optionnel)';
  String get menuProdReasonHint => isAr
      ? 'مثال: شراء، كسر، جرد…'
      : 'ex. Achat marché, casse, inventaire…';
  String get menuProdInvalidPrice => isAr ? 'سعر غير صالح' : 'Prix invalide';
  String get menuProdImageNotFound =>
      isAr ? 'ملف الصورة غير موجود' : 'Fichier image introuvable';
  String get menuProdUploadFail =>
      isAr ? 'فشل رفع الصورة' : 'Échec du téléversement de l’image';
  String get menuProdInvalidStockQty =>
      isAr ? 'كمية المخزون غير صالحة' : 'Quantité en stock invalide';
  String get menuProdInvalidQty => isAr ? 'كمية غير صالحة' : 'Quantité invalide';
  String menuProdStockAdjustedVal(String delta) => isAr
      ? 'تم تعديل المخزون بـ $delta'
      : 'Stock ajusté de $delta';
  String get menuProdRupture => isAr ? 'نفد' : 'Rupture';
  String get menuProdStockOk => isAr ? 'جيد' : 'OK';
  String get menuProdChangeCategoryTooltip =>
      isAr ? 'تغيير الفئة' : 'Changer la catégorie';
  String get menuProdDeleteTitle =>
      isAr ? 'حذف هذا المنتج؟' : 'Supprimer ce produit ?';
  String get menuProdPageTitle => isAr ? 'الأطباق' : 'Produits';
  String get menuProdFilterCategory =>
      isAr ? 'تصفية حسب الفئة' : 'Filtrer par catégorie';
  String get menuProdAllCategoriesHint =>
      isAr ? 'كل الفئات' : 'Toutes les catégories';
  String get menuProdColPhoto => isAr ? 'صورة' : 'Photo';
  String get menuProdColNumber => isAr ? 'رقم' : 'N°';
  String get menuProdNumberLabel => isAr ? 'رقم المنتج' : 'Numéro produit';
  String get menuProdColName => isAr ? 'الاسم' : 'Nom';
  String get menuProdColCategory => isAr ? 'الفئة' : 'Catégorie';
  String get menuProdColPrice => isAr ? 'السعر' : 'Prix';
  String get menuProdColStock => isAr ? 'المخزون' : 'Stock';
  String get menuProdColAvailable => isAr ? 'متوفر' : 'Dispo';
  String get menuProdTooltipAdjustStock =>
      isAr ? 'تعديل المخزون' : 'Ajuster le stock';
  String get menuProdTooltipEdit => isAr ? 'تعديل' : 'Modifier';
  String get menuProdTooltipDelete => isAr ? 'حذف' : 'Supprimer';
  String get menuProdFab => isAr ? 'طبق' : 'Produit';
  String get menuProdSaved => isAr ? 'تم الحفظ' : 'Enregistré';
  String get menuProdDeleted => isAr ? 'تم الحذف' : 'Supprimé';
  String menuProdCategoryChangedNamed(String p, String c) => isAr
      ? '« $p » ← $c'
      : '« $p » → $c';

  // ——— Menu — catégories ———
  String get menuCatNewTitle => isAr ? 'فئة جديدة' : 'Nouvelle catégorie';
  String get menuCatLabelField => isAr ? 'التسمية' : 'Libellé';
  String get menuCatLabelHint => isAr ? 'مثال: مشاوي' : 'Ex. Grillades';
  String get menuCatSortField => isAr ? 'ترتيب العرض' : 'Ordre d’affichage';
  String get menuCatLabelRequired =>
      isAr ? 'التسمية مطلوبة (حرفان على الأقل)' : 'Libellé requis (2 caractères min.)';
  String get menuCatSortInvalid => isAr ? 'ترتيب غير صالح' : 'Ordre invalide';
  String get menuCatSaved => isAr ? 'تم حفظ الفئة' : 'Catégorie enregistrée';
  String get menuCatDeleteTitle =>
      isAr ? 'حذف هذه الفئة؟' : 'Supprimer cette catégorie ?';
  String get menuCatMergeTitle => isAr ? 'دمج الفئة' : 'Fusionner la catégorie';
  String get menuCatMergeBody => isAr
      ? 'اختر فئة الوجهة: تُنقل الأطباق ثم تُحذف هذه الفئة.'
      : 'Choisissez la catégorie de destination : les produits y seront déplacés, '
          'puis cette catégorie sera supprimée.';
  String get menuCatMergeInto => isAr ? 'الدمج في…' : 'Fusionner dans…';
  String get menuCatMergeAction =>
      isAr ? 'دمج وحذف' : 'Fusionner et supprimer';
  String menuCatMergedMoved(int n) => isAr
      ? 'تم الدمج: نُقل $n طبقاً.'
      : 'Fusionnée : $n produit(s) déplacé(s).';
  String get menuCatNoOtherCategory => isAr
      ? 'لا توجد فئة أخرى لإعادة تعيين الأطباق.'
      : 'Aucune autre catégorie disponible pour réaffecter les produits.';
  String get menuCatDedupNone => isAr ? 'لا تكرارات.' : 'Aucun doublon détecté.';
  String get menuCatDedupTitle =>
      isAr ? 'تنظيف الفئات المكررة' : 'Nettoyer les catégories doublons';
  String get menuCatDedupHint => isAr
      ? 'حدد الفئات للدمج في الهدف المقترح لكل مجموعة.'
      : 'Sélectionnez les catégories à fusionner dans la cible suggérée '
          'pour chaque groupe.';
  String get menuCatDedupFab => isAr ? 'تنظيف التكرار' : 'Nettoyer doublons';
  String get menuCatPageTitle => isAr ? 'فئات القائمة' : 'Catégories menu';
  String get menuCatPageSubtitle => isAr
      ? 'إدارة أقسام القائمة يدوياً: المعرف، التسمية والترتيب.'
      : 'Gestion manuelle des sections carte : créez vos slugs techniques, '
          'libellés et ordre d’affichage (les produits restent reliés aux catégories).';
  String get menuCatColSlug => isAr ? 'المعرف' : 'Slug';
  String get menuCatColLabelFr => isAr ? 'التسمية (فر)' : 'Libellé FR';
  String get menuCatColLabelAr => isAr ? 'التسمية (ع)' : 'Libellé AR';
  String get menuCatColOrder => isAr ? 'الترتيب' : 'Ordre';
  String get menuCatColProducts => isAr ? 'الأطباق' : 'Produits';
  String get menuCatTooltipEdit => isAr ? 'تعديل' : 'Modifier';
  String get menuCatTooltipMerge =>
      isAr ? 'دمج في فئة أخرى' : 'Fusionner dans une autre catégorie';
  String get menuCatTooltipDelete => isAr ? 'حذف' : 'Supprimer';
  String get menuCatFab => isAr ? 'فئة' : 'Catégorie';
  String get menuCatLabelFrField => menuCatLabelField;
  String get menuCatLabelArField =>
      isAr ? 'التسمية بالعربية (اختياري)' : 'Libellé AR (optionnel)';
  String get menuCatLabelArHint =>
      isAr ? 'مثال: مشاوي' : 'Ex. مشاوي';
  String get menuCatDeleted => isAr ? 'تم الحذف' : 'Supprimé';
  String get menuCatErrorGeneric => isAr ? 'خطأ' : 'Erreur';
  String menuCatDedupSuccess(int applied, int moved, [int errs = 0]) {
    var s = isAr
        ? 'تم تطبيق $applied دمجاً، نُقل $moved طبقاً.'
        : '$applied fusion(s) appliquée(s), $moved produit(s) déplacé(s).';
    if (errs > 0) {
      s += isAr ? ' ($errs خطأ)' : ' $errs erreur(s).';
    }
    return s;
  }

  String menuCatMergeCount(int n) =>
      isAr ? 'دمج ($n)' : 'Fusionner ($n)';

  String get menuCatEditTitle => isAr ? 'تعديل الفئة' : 'Modifier';

  String menuCatMergeSourceIntro(String name, String slug, int n) => isAr
      ? '« $name » ($slug) يحتوي على $n طبقاً.\n'
      : '« $name » ($slug) contient $n produit(s).\n';

  String menuCatDedupOverview(int groups) => isAr
      ? 'تم رصد $groups مجموعة تكرار. اختر الفئات للدمج في الهدف المقترح (بخط عريض). '
          'ستُنقل الأطباق ثم تُحذف المصدر.'
      : '$groups groupe(s) de doublons détecté(s). '
          'Sélectionnez les catégories à fusionner dans la cible suggérée (en gras). '
          'Les produits seront déplacés, puis la source supprimée.';

  String menuCatDedupTargetCaption(String label, String slug, int products) =>
      isAr
          ? 'الهدف: $label ($slug) — $products طبقاً'
          : 'Cible : $label ($slug) — $products produit(s)';

  String menuCatDedupProductsToMove(int n) => isAr
      ? '$n طبقاً للنقل'
      : '$n produit(s) à déplacer';

  String menuCatDedupSelectedCount(int pairs) => isAr
      ? '$pairs دمجاً محدداً.'
      : '$pairs fusion(s) sélectionnée(s).';

  String menuCatErrorColon(Object e) =>
      isAr ? 'خطأ: $e' : 'Erreur : $e';

  // ——— Tables ———
  String get tablesPageTitle => isAr ? 'الطاولات' : 'Tables';
  String get tablesColNo => isAr ? 'رقم' : 'N°';
  String get tablesColCapacity => isAr ? 'السعة' : 'Capacité';
  String get tablesColType => isAr ? 'النوع' : 'Type';
  String get tablesColStatus => isAr ? 'الحالة' : 'Statut';
  String get tablesFab => isAr ? 'طاولة' : 'Table';
  String get tablesNewTitle => isAr ? 'طاولة جديدة' : 'Nouvelle table';
  String get tablesEditTitle => isAr ? 'تعديل الطاولة' : 'Modifier la table';
  String get tablesFieldNumber => isAr ? 'الرقم' : 'Numéro';
  String get tablesFieldCapacity => isAr ? 'السعة' : 'Capacité';
  String get tablesFieldType => isAr ? 'النوع' : 'Type';
  String get tablesFieldStatus => isAr ? 'الحالة' : 'Statut';
  String get tablesDeleteTitle =>
      isAr ? 'حذف الطاولة؟' : 'Supprimer la table ?';
  String tablesDeleteBody(int n) => isAr
      ? 'سيتم حذف الطاولة رقم $n نهائياً.'
      : 'Table n°$n sera supprimée définitivement.';
  String get tablesInvalidNumCap =>
      isAr ? 'رقم أو سعة غير صالحة' : 'Numéro et capacité invalides';
  String get tablesSaved => isAr ? 'تم الحفظ' : 'Enregistré';
  String get tablesDeleted => isAr ? 'تم الحذف' : 'Supprimé';
  String get tablesErrGeneric => isAr ? 'خطأ' : 'Erreur';

  String tablesType(String code) {
    if (!isAr) {
      return switch (code) {
        'STANDARD' => 'Standard',
        'VIP' => 'VIP',
        'FAMILY' => 'Famille',
        _ => code,
      };
    }
    return switch (code) {
      'STANDARD' => 'عادية',
      'VIP' => 'VIP',
      'FAMILY' => 'عائلية',
      _ => code,
    };
  }

  String tablesStatus(String code) {
    if (!isAr) {
      return switch (code) {
        'FREE' => 'Libre',
        'OCCUPIED' => 'Occupée',
        'RESERVED' => 'Réservée',
        'CLEANING' => 'Nettoyage',
        _ => code,
      };
    }
    return switch (code) {
      'FREE' => 'متاحة',
      'OCCUPIED' => 'مشغولة',
      'RESERVED' => 'محجوزة',
      'CLEANING' => 'تنظيف',
      _ => code,
    };
  }

  // ——— Utilisateurs ———
  String get usersPageTitle => isAr ? 'المستخدمون' : 'Utilisateurs';
  String get usersPageSubtitle => isAr
      ? 'حسابات الدخول: كلمة المرور، الدور، التفعيل والصلاحيات.'
      : 'Comptes d’accès : mot de passe, rôle, activation et permissions fines.';
  String get usersFab => isAr ? 'مستخدم' : 'Utilisateur';
  String get usersNewTitle => isAr ? 'مستخدم جديد' : 'Nouvel utilisateur';
  String get usersEditTitle =>
      isAr ? 'تعديل المستخدم' : 'Modifier l’utilisateur';
  String get usersPasswordOptional => isAr
      ? 'كلمة مرور جديدة (اختياري)'
      : 'Nouveau mot de passe (optionnel)';
  String get usersPasswordNew => isAr ? 'كلمة المرور' : 'Mot de passe';
  String get usersPasswordConfirm => isAr
      ? 'تأكيد كلمة المرور'
      : 'Confirmer le mot de passe';
  String get usersPasswordMismatch => isAr
      ? 'كلمتا المرور غير متطابقتين'
      : 'Les mots de passe ne correspondent pas';
  String get usersFullNameField =>
      isAr ? 'الاسم الكامل (اختياري)' : 'Nom complet (optionnel)';
  String get usersRoleField => isAr ? 'الدور' : 'Rôle';
  String get usersActiveSwitch => isAr ? 'حساب نشط' : 'Compte actif';
  String get usersInheritTitle =>
      isAr ? 'وراثة صلاحيات الدور' : 'Hériter des droits du rôle';
  String get usersInheritSubtitle => isAr
      ? 'ألغِ التحديد لمنح امتيازات محددة.'
      : 'Décochez pour attribuer des privilèges précis.';
  String get usersPrivileges => isAr ? 'الصلاحيات' : 'Privilèges';
  String get users403 => isAr
      ? 'رفض الوصول: مطلوب إذن « المستخدمون ».'
      : 'Accès refusé : la permission « utilisateurs » est requise.';
  String get usersPwdMin8 => isAr
      ? 'كلمة المرور: 8 أحرف على الأقل'
      : 'Mot de passe : au moins 8 caractères';
  String get usersPickRole => isAr ? 'اختر دوراً' : 'Choisissez un rôle';
  String get usersSaved => isAr ? 'تم حفظ المستخدم' : 'Utilisateur enregistré';
  String get usersDeactivateTitle =>
      isAr ? 'تعطيل هذا الحساب؟' : 'Désactiver ce compte ?';
  String get usersInactive => isAr ? 'غير نشط' : 'Inactif';
  String get usersRightsRole => isAr ? 'صلاحيات الدور' : 'Droits du rôle';
  String get usersRightsCustom =>
      isAr ? 'صلاحيات مخصصة' : 'Droits personnalisés';
  String usersPermCount(int n) => isAr
      ? '$n صلاحية فعّالة'
      : '$n permission(s) effective(s)';
  String get usersPermEffectiveHeader =>
      isAr ? 'الصلاحيات الفعّالة' : 'Permissions effectives';
  String get usersNoPerms => isAr
      ? 'لا صلاحيات: المستخدم لن يتمكن من شيء.'
      : 'Aucune permission active : l’utilisateur ne pourra rien faire.';
  String get usersExtrasTitle =>
      isAr ? 'مضافة فوق الدور' : 'Ajoutées en plus du rôle';
  String get usersMissingTitle =>
      isAr ? 'مُزالة مقارنة بالدور' : 'Retirées par rapport au rôle';
  String get usersTooltipEdit => isAr ? 'تعديل' : 'Modifier';
  String get usersTooltipDeactivate => isAr ? 'تعطيل' : 'Désactiver';
  String get usersDeactivatedOk =>
      isAr ? 'تم تعطيل الحساب' : 'Compte désactivé';

  String userRole(String code) {
    if (!isAr) {
      return switch (code) {
        'ADMIN' => 'Administrateur',
        'MANAGER' => 'Manager',
        'RECEPTIONIST' => 'Réception',
        'SERVER' => 'Serveur',
        'CASHIER' => 'Caissier',
        _ => code,
      };
    }
    return switch (code) {
      'ADMIN' => 'مسؤول',
      'MANAGER' => 'مدير',
      'RECEPTIONIST' => 'استقبال',
      'SERVER' => 'نادل',
      'CASHIER' => 'أمين صندوق',
      _ => code,
    };
  }

  String permissionLabel(String key) {
    if (!isAr) {
      return switch (key) {
        'dashboard.view' => 'Accueil / tableau de bord',
        'tables.manage' => 'Tables & plan',
        'pos.access' => 'Caisse & commandes',
        'menu.manage' => 'Carte & catégories',
        'finance.view' => 'Finances & dépenses',
        'users.manage' => 'Gestion des utilisateurs',
        'customers.manage' => 'Clients',
        'reservations.manage' => 'Réservations',
        _ => key,
      };
    }
    return switch (key) {
      'dashboard.view' => 'الرئيسية / لوحة التحكم',
      'tables.manage' => 'الطاولات والخطة',
      'pos.access' => 'الصندوق والطلبات',
      'menu.manage' => 'القائمة والفئات',
      'finance.view' => 'المالية والمصروفات',
      'users.manage' => 'إدارة المستخدمين',
      'customers.manage' => 'الزبائن',
      'reservations.manage' => 'الحجوزات',
      _ => key,
    };
  }

  // ——— Caisse ———
  String get posPageTitle => isAr ? 'نقطة البيع' : 'Point de vente';
  String get posNetworkBannerHint => isAr
      ? 'تعذّر تحديث البيانات. السلة تبقى على هذا الجهاز — أعد المحاولة عند عودة الاتصال.'
      : 'Synchronisation impossible. Le panier reste sur cet appareil — réessayez quand le serveur répond.';
  String get posSegmentNew => isAr ? 'بيع جديد' : 'Nouvelle vente';
  String get posSegmentOpen => isAr ? 'مفتوحة' : 'Ouvertes';
  String get posSegmentHistory => isAr ? 'السجل' : 'Historique';
  String posSegmentHistoryScoped(bool allOrders) => isAr
      ? (allOrders ? 'السجل' : 'مبيعاتي')
      : (allOrders ? 'Historique' : 'Mes ventes');
  String get posHistoryScopedHint => isAr
      ? 'تظهر هنا الطلبات التي أنشأتها أنت فقط.'
      : 'Seules vos commandes créées avec ce compte sont affichées ici.';
  String get posCartTitle => isAr ? 'السلة' : 'Panier';
  String get posCartEmpty => isAr
      ? 'اضغط على منتج للإضافة'
      : 'Tapez un produit pour l’ajouter';
  String get posCartTotal => isAr ? 'مجموع السلة' : 'Total panier';
  String get posCreateOrder =>
      isAr ? 'إنشاء الطلب' : 'Créer la commande';
  String get posDiscountOnTotal => isAr
      ? 'تخفيض على المجموع (FCFA)'
      : 'Réduction sur le montant total (FCFA)';
  String get posFinalTotal => isAr ? 'المجموع النهائي' : 'Total à payer';
  String get posConfirmAndPrint =>
      isAr ? 'تأكيد وطباعة' : 'Valider et imprimer';
  String get posInvalidDiscount => isAr
      ? 'تخفيض غير صالح'
      : 'Réduction invalide (0 au maximum du sous-total)';
  String get posServiceType => isAr ? 'نوع الخدمة' : 'Type de service';
  String get posTable => isAr ? 'طاولة' : 'Table';
  String get posTableCapacity =>
      isAr ? 'مقعد' : 'pers.';
  String get posCategoryFilter =>
      isAr ? 'فئة القائمة' : 'Catégorie menu';
  String get posNoOpenOrders => isAr
      ? 'لا توجد طلبات مفتوحة'
      : 'Aucune commande ouverte';
  String get posFilterDates => isAr ? 'تصفية بالتاريخ…' : 'Filtrer par date…';
  String get posHistoryModalTitle =>
      isAr ? 'تصفية السجل بالتاريخ' : 'Filtrer l’historique';
  String get posHistoryModalHint => isAr
      ? 'اختر تاريخ البداية والنهاية ثم طبّق الفترة.'
      : 'Choisissez la date de début et de fin, puis appliquez la période.';
  String get posClearFilter => isAr ? 'إلغاء التصفية' : 'Effacer filtre';
  String get posPrintFail =>
      isAr ? 'فشل الطباعة' : 'Impression impossible';
  String get posAddOneItem =>
      isAr ? 'أضف منتجاً واحداً على الأقل' : 'Ajoutez au moins un article';
  String get posOrderCreated => isAr ? 'تم إنشاء الطلب' : 'Commande créée';
  String get posOrderPaidPrinted => isAr
      ? 'تم الدفع وإرسال الإيصال للطباعة'
      : 'Commande encaissée — reçu envoyé à l’impression';
  String get posOrderSavedPrintCancelled => isAr
      ? 'تم حفظ الطلب — تم إلغاء الطباعة'
      : 'Commande enregistrée — impression annulée';
  String get posOrderSaved => isAr
      ? 'تم حفظ الطلب'
      : 'Commande enregistrée';
  String get posPrintCancelled => isAr
      ? 'تم إلغاء الطباعة'
      : 'Impression annulée';
  String get posPaymentRecorded =>
      isAr ? 'تم تسجيل الدفع' : 'Paiement enregistré';
  String get posOutOfStock => isAr ? 'نفد' : 'RUPTURE';
  String get posLowStock => isAr ? 'مخزون منخفض' : 'Stock bas';
  String get posStockLabel => isAr ? 'مخزون' : 'Stock';

  String posService(String code) {
    if (!isAr) {
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

  String posStatus(String code) {
    if (!isAr) {
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

  String posPayment(String code) {
    if (!isAr) {
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

  String get posPaymentTitle => isAr ? 'الدفع' : 'Encaissement';
  String get posDueLabel => isAr ? 'المتبقي' : 'Reste à payer';
  String get posAmountFcfa => isAr ? 'المبلغ (فرنك)' : 'Montant (FCFA)';
  String get posPaymentMethod =>
      isAr ? 'طريقة الدفع' : 'Moyen de paiement';
  String get posOrderTitle => isAr ? 'طلب' : 'Commande';
  String get posArticles => isAr ? 'الأصناف' : 'Articles';
  String get posTotal => isAr ? 'الإجمالي' : 'Total';
  String get posPaid => isAr ? 'المدفوع' : 'Payé';
  String get posRemain => isAr ? 'الباقي' : 'Reste';
  String get posPayments => isAr ? 'المدفوعات' : 'Paiements';
  String get posClose => isAr ? 'إغلاق' : 'Fermer';
  String get posEditCart => isAr ? 'تعديل السلة' : 'Modifier le panier';
  String get posCollect => isAr ? 'تحصيل' : 'Encaisser';
  String get posUpdateStatus =>
      isAr ? 'تحديث الحالة' : 'Mettre à jour statut';
  String get posPrint => isAr ? 'طباعة' : 'Imprimer';
  String get posKitchenStatus =>
      isAr ? 'حالة المطبخ / الصالة' : 'Statut cuisine / salle';
  String get posNotePrefix => isAr ? 'ملاحظة' : 'Note';
  String get posTablePrefix => isAr ? 'طاولة' : 'Table';
  String get posUnknownArticle => isAr ? 'صنف' : 'Article';
  String get posHistoryHelp =>
      isAr ? 'تصفية السجل' : 'Filtrer l’historique';
  String get posHistoryFieldFrom => isAr ? 'من' : 'Du';
  String get posHistoryFieldTo => isAr ? 'إلى' : 'Au';
  String get posHistoryEmptyLong => isAr
      ? 'لا توجد طلبات في السجل لهذه الفترة (مدفوعة أو ملغاة؛ بدون تصفية، حتى ١٢ شهراً، بحد أقصى ٥٠٠).'
      : 'Aucune commande dans l’historique pour cette période '
          '(soldées ou annulées ; sans filtre, jusqu’à ~12 mois, max. 500).';
  String get posErrorGeneric => isAr ? 'خطأ' : 'Erreur';
  String get posCustomerPrefix => isAr ? 'العميل' : 'Client';
  String get posCreatedAtPrefix => isAr ? 'أُنشئت في' : 'Créée le';
  String get posUpdatedAtPrefix => isAr ? 'آخر تحديث' : 'Dernière maj';
  String get posEditCartTitlePrefix =>
      isAr ? 'السلة · طلب' : 'Panier · commande';
  String get posAddProductLine =>
      isAr ? 'إضافة صنف' : 'Ajouter un article';
  String get posCartEmptyDialog => isAr ? 'السلة فارغة' : 'Panier vide';
  String get posQuantityPrefix => isAr ? 'الكمية' : 'Quantité';
  String get posCartUpdatedDone =>
      isAr ? 'تم تحديث السلة' : 'Panier mis à jour';
  String get posAddAtLeastOneLine => isAr
      ? 'أضف سطراً واحداً على الأقل'
      : 'Ajoutez au moins une ligne';

  // ——— Fiche client ———
  String get customerKpiOrders => isAr ? 'الطلبات' : 'Commandes';
  String get customerKpiPaid => isAr ? 'المدفوعة' : 'Payées';
  String get customerKpiTotalSpent =>
      isAr ? 'الإجمالي المنفق' : 'Total dépensé';
  String get customerKpiAvgBasket =>
      isAr ? 'متوسط السلة' : 'Panier moyen';
  String get customerKpiLastVisit =>
      isAr ? 'آخر زيارة' : 'Dernière visite';
  String get customerNoOrders => isAr
      ? 'لا توجد طلبات لهذا الزبون.'
      : 'Aucune commande pour ce client.';
  String get customerPrintTooltip =>
      isAr ? 'طباعة الإيصال' : 'Imprimer le ticket';
  String customerOrderTitle(int number, String subtotalFcfa) => isAr
      ? 'طلب #$number · $subtotalFcfa FCFA'
      : 'Commande #$number · $subtotalFcfa FCFA';
}
