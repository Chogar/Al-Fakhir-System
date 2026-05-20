import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/notifications/top_notifier.dart';
import '../../core/permissions.dart';
import '../../l10n/app_strings.dart';

/// Rôles autorisés dans l'application (Admin + Gérant uniquement).
const _allowedRoleNames = {'ADMIN', 'MANAGER'};

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.api, required this.user});

  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!userCanManageUsers(widget.user)) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.api.dio.get<List<dynamic>>('/users'),
        widget.api.dio.get<List<dynamic>>('/users/roles'),
      ]);
      if (!mounted) return;
      setState(() {
        _staff = results[0].data!
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where(_staffHasAllowedRole)
            .toList();
        _roles = results[1].data!
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((r) => _allowedRoleNames.contains(r['name']?.toString()))
            .toList()
          ..sort((a, b) {
            const order = ['ADMIN', 'MANAGER'];
            final ai = order.indexOf(a['name']?.toString() ?? '');
            final bi = order.indexOf(b['name']?.toString() ?? '');
            return ai.compareTo(bi);
          });
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final str = AppStrings.of(context);
      setState(() {
        _error = userFacingDioMessage(e, str);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _openCreateDialog() async {
    final str = AppStrings.of(context);
    if (_roles.isEmpty) {
      TopNotifier.warning(context, str.usersSelectRole);
      return;
    }

    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    var obscurePassword = true;
    var isActive = true;
    final roleNames = _roles
        .map((r) => r['name']?.toString())
        .whereType<String>()
        .toList();
    String? selectedRole =
        roleNames.contains('ADMIN') ? 'ADMIN' : roleNames.firstOrNull;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return AlertDialog(
            title: Text(str.usersCreateTitle),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(
                        labelText: str.usersUsername,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: str.usersPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setModal(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fullNameCtrl,
                      decoration: InputDecoration(
                        labelText: str.usersFullName,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: str.usersRole,
                        prefixIcon: const Icon(Icons.shield_outlined),
                      ),
                      items: [
                        for (final r in _roles)
                          DropdownMenuItem(
                            value: r['name']?.toString(),
                            child: Text(
                              str.usersRoleLabel(
                                r['name']?.toString() ?? '',
                              ),
                            ),
                          ),
                      ],
                      onChanged: (v) => setModal(() => selectedRole = v),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(str.usersActiveAccount),
                      value: isActive,
                      onChanged: (v) => setModal(() => isActive = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(str.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(str.usersSave),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) return;

    final username = usernameCtrl.text.trim();
    final password = passwordCtrl.text;
    final role = selectedRole?.trim();

    if (username.length < 2) {
      TopNotifier.warning(context, str.usersValidationUsername);
      return;
    }
    if (password.length < 8) {
      TopNotifier.warning(context, str.usersValidationPassword);
      return;
    }
    if (role == null || role.isEmpty) {
      TopNotifier.warning(context, str.usersSelectRole);
      return;
    }

    try {
      await widget.api.dio.post<Map<String, dynamic>>(
        '/users',
        data: {
          'username': username,
          'password': password,
          'role': role,
          'isActive': isActive,
          if (fullNameCtrl.text.trim().isNotEmpty)
            'fullName': fullNameCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      TopNotifier.success(context, str.usersCreatedSuccess);
      await _load();
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, '$e');
    }
  }

  bool _staffHasAllowedRole(Map<String, dynamic> u) {
    final role = u['role'];
    if (role is! Map) return false;
    return _allowedRoleNames.contains(role['name']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!userCanManageUsers(widget.user)) {
      return Center(child: Text(str.usersNoAccess));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          str.usersPageTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          str.usersPageSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _openCreateDialog,
                    icon: const Icon(Icons.person_add_outlined),
                    label: Text(str.usersAddUser),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: Text(str.refresh),
                    ),
                  ],
                ),
              ),
            )
          else if (_staff.isEmpty)
            SliverFillRemaining(child: Center(child: Text(str.usersEmpty)))
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final u = _staff[i];
                  final username = u['username']?.toString() ?? '—';
                  final fullName = u['fullName']?.toString();
                  final role = u['role'];
                  final roleName = role is Map
                      ? role['name']?.toString() ?? ''
                      : '';
                  final active = u['isActive'] == true;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        username.isNotEmpty
                            ? username[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      fullName != null && fullName.isNotEmpty
                          ? fullName
                          : username,
                    ),
                    subtitle: Text(
                      '@$username · ${str.usersRoleLabel(roleName)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        active ? str.usersActive : str.usersInactive,
                        style: TextStyle(
                          color: active ? cs.primary : cs.error,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: active
                          ? cs.primaryContainer
                          : cs.errorContainer,
                    ),
                  );
                },
                childCount: _staff.length,
              ),
            ),
        ],
      ),
    );
  }
}
