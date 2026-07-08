import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../l10n/app_strings.dart';
import 'menu_categories_tab.dart';
import 'menu_products_tab.dart';
import 'menu_ui.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(str.navMenu, style: Theme.of(context).textTheme.titleLarge),
        ),
        MenuUi.menuTabBar(
          context: context,
          controller: _tabs,
          tabs: [
            Tab(text: str.menuTabProducts, icon: const Icon(Icons.inventory_2_outlined)),
            Tab(text: str.menuTabCategories, icon: const Icon(Icons.category_outlined)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              MenuProductsTab(api: widget.api),
              MenuCategoriesTab(api: widget.api),
            ],
          ),
        ),
      ],
    );
  }
}
