import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/branding/app_branding.dart';
import '../../core/permissions.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_strings.dart';
import '../dashboard/dashboard_page.dart';
import '../finance/finance_page.dart';
import '../statistics/statistics_page.dart';
import '../menu/menu_page.dart';
import '../pos/pos_page.dart';
import '../tables/tables_page.dart';
import '../users/users_management_page.dart';

class _ShellDestination {
  const _ShellDestination({
    required this.labelBuilder,
    required this.icon,
    required this.selectedIcon,
    required this.permission,
    required this.builder,
  });

  final String Function(AppStrings s) labelBuilder;
  final Icon icon;
  final Icon selectedIcon;
  final String permission;
  final Widget Function() builder;

  NavigationRailDestination toDestination(AppStrings s) =>
      NavigationRailDestination(
        icon: icon,
        selectedIcon: selectedIcon,
        label: Text(labelBuilder(s)),
      );
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    super.key,
    required this.api,
    required this.user,
    required this.onLogout,
    required this.onLocaleChanged,
  });

  final ApiClient api;
  final Map<String, dynamic>? user;
  final VoidCallback onLogout;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final GlobalKey<PosPageState> _posPageKey = GlobalKey<PosPageState>();
  int _index = 0;

  List<_ShellDestination> get _allDestinations => [
        _ShellDestination(
          labelBuilder: (s) => s.shellHome(s.isAr),
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard_rounded),
          permission: 'dashboard.view',
          builder: () => DashboardPage(api: widget.api),
        ),
        _ShellDestination(
          labelBuilder: (s) => s.shellTables(s.isAr),
          icon: const Icon(Icons.table_restaurant_outlined),
          selectedIcon: const Icon(Icons.table_restaurant_rounded),
          permission: 'tables.manage',
          builder: () => TablesPage(api: widget.api),
        ),
        _ShellDestination(
          labelBuilder: (s) => s.shellPos(s.isAr),
          icon: const Icon(Icons.point_of_sale_outlined),
          selectedIcon: const Icon(Icons.point_of_sale_rounded),
          permission: 'pos.access',
          builder: () => PosPage(
            key: _posPageKey,
            api: widget.api,
            user: widget.user,
          ),
        ),
        _ShellDestination(
          labelBuilder: (s) => s.shellMenu(s.isAr),
          icon: const Icon(Icons.restaurant_menu_outlined),
          selectedIcon: const Icon(Icons.restaurant_menu_rounded),
          permission: 'menu.manage',
          builder: () => MenuPage(api: widget.api),
        ),
        _ShellDestination(
          labelBuilder: (s) => s.shellFinance(s.isAr),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
          permission: 'finance.view',
          builder: () => FinancePage(api: widget.api),
        ),
        _ShellDestination(
          labelBuilder: (s) => s.shellStatistics(s.isAr),
          icon: const Icon(Icons.bar_chart_outlined),
          selectedIcon: const Icon(Icons.bar_chart_rounded),
          permission: 'finance.view',
          builder: () => StatisticsPage(api: widget.api),
        ),
        _ShellDestination(
          labelBuilder: (s) => s.shellUsers(s.isAr),
          icon: const Icon(Icons.manage_accounts_outlined),
          selectedIcon: const Icon(Icons.manage_accounts_rounded),
          permission: 'users.manage',
          builder: () => UsersManagementPage(api: widget.api),
        ),
      ];

  List<_ShellDestination> get _visible =>
      _allDestinations
          .where((d) => userHasPermission(widget.user, d.permission))
          .toList();

  @override
  void didUpdateWidget(MainShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxIdx = _visible.isEmpty ? 0 : _visible.length - 1;
    if (_index > maxIdx) {
      setState(() => _index = maxIdx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = AppStrings.of(context);
    final username = widget.user?['username'] as String? ?? '';
    final role = widget.user?['role'] as String? ?? '';
    final visible = _visible;
    final safeIndex = visible.isEmpty ? 0 : _index.clamp(0, visible.length - 1);
    final extended = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsetsDirectional.only(start: 8),
          child: Row(
            children: [
              Material(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AppLogoAsset(
                    size: 36,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.appTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      visible.isEmpty
                          ? s.shellConnectedSpace
                          : visible[safeIndex].labelBuilder(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (username.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: Material(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  onTap: () => _showUserSheet(context, username, role),
                  borderRadius: BorderRadius.circular(999),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.primaryContainer,
                          foregroundColor: cs.onPrimaryContainer,
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall,
                              ),
                              if (role.isNotEmpty)
                                Text(
                                  role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Icon(Icons.expand_more_rounded, color: cs.onSurfaceVariant, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Tooltip(
              message: s.isAr ? 'اللغة' : 'Langue',
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: 'fr',
                    label: Text(s.langFr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  ButtonSegment(
                    value: 'ar',
                    label: Text(s.langAr, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
                selected: {s.isAr ? 'ar' : 'fr'},
                onSelectionChanged: (sel) {
                  if (sel.isEmpty) return;
                  widget.onLocaleChanged(Locale(sel.first));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Tooltip(
              message: s.shellLogoutTooltip,
              child: IconButton.filledTonal(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded),
              ),
            ),
          ),
        ],
      ),
      body: visible.isEmpty
          ? _NoAccessBody(theme: theme, cs: cs)
          : Row(
              children: [
                NavigationRail(
                  extended: extended,
                  minExtendedWidth: 232,
                  backgroundColor: cs.surface,
                  selectedIndex: safeIndex,
                  onDestinationSelected: (i) {
                    setState(() => _index = i);
                    final dest = visible[i];
                    if (dest.permission == 'pos.access') {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _posPageKey.currentState?.reloadCatalogAndOrders();
                      });
                    }
                  },
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  leading: extended ? _RailBrandHeader(cs: cs) : null,
                  trailing: extended
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            s.shellRailFooter,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.outline,
                              height: 1.3,
                            ),
                          ),
                        )
                      : null,
                  destinations:
                      visible.map((d) => d.toDestination(s)).toList(),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.background,
                    child: IndexedStack(
                      index: safeIndex,
                      children: visible.map((d) => d.builder()).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showUserSheet(BuildContext context, String username, String role) {
    final cs = Theme.of(context).colorScheme;
    final s = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(username, style: Theme.of(ctx).textTheme.titleMedium),
              subtitle: role.isNotEmpty ? Text(role) : null,
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(s.shellLogoutSheet),
            ),
          ],
        ),
      ),
    );
  }
}

class _RailBrandHeader extends StatelessWidget {
  const _RailBrandHeader({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: AppLogoAsset(
              size: 72,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            s.shellNavTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAccessBody extends StatelessWidget {
  const _NoAccessBody({required this.theme, required this.cs});

  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_person_outlined, size: 56, color: cs.outline),
                  const SizedBox(height: 20),
                  Text(
                    s.shellNoAccessTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.shellNoAccessBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
