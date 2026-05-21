import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/session/auth_session_store.dart';
import '../../l10n/app_strings.dart';
import '../auth/login_screen.dart';
import '../dashboard/dashboard_page.dart';
import '../finance/finance_page.dart';
import '../menu/menu_page.dart';
import '../pos/pos_page.dart';
import '../statistics/statistics_page.dart';
import '../users/users_page.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, required this.api, required this.user});

  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;
  final _posKey = GlobalKey();

  String _sectionTitle(AppStrings str) {
    switch (_index) {
      case 0:
        return str.navHome;
      case 1:
        return str.navPos;
      case 2:
        return str.navMenu;
      case 3:
        return str.navFinance;
      case 4:
        return str.navStats;
      case 5:
        return str.navUsers;
      default:
        return str.appTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final username = widget.user['username']?.toString() ?? '';
    final role = widget.user['role']?.toString() ?? '';

    final pages = <Widget>[
      DashboardPage(api: widget.api, user: widget.user),
      PosPage(key: _posKey, api: widget.api, user: widget.user),
      MenuPage(api: widget.api),
      FinancePage(api: widget.api, user: widget.user),
      StatisticsPage(api: widget.api),
      UsersPage(api: widget.api, user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_sectionTitle(str)} · $username ${role.toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: str.cancel,
            onPressed: () async {
              await AuthSessionStore.clear();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                label: Text(str.navHome),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.point_of_sale_outlined),
                label: Text(str.navPos),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(str.navMenu),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.payments_outlined),
                label: Text(str.navFinance),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                label: Text(str.navStats),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                label: Text(str.navUsers),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: pages[_index]),
        ],
      ),
    );
  }
}
