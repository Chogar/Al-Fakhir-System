import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import 'menu_categories_tab.dart';
import 'menu_products_tab.dart';

/// Onglets Produits et Catégories avec présentation soignée.
class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.restaurant_menu_rounded, color: cs.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        str.menuPageTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        str.menuPageSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              elevation: 0,
              color: cs.surface,
              surfaceTintColor:
                  cs.surfaceTint.withValues(alpha: 0.04),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: TabBar(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                tabs: [
                  Tab(text: str.menuTabProducts, height: 46),
                  Tab(text: str.menuTabCategories, height: 46),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
              ),
              child: TabBarView(
                children: [
                  MenuProductsTab(api: api),
                  MenuCategoriesTab(api: api),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
