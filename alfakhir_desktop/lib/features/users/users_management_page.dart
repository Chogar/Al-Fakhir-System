import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/permissions.dart';
import '../../data/models/permission_registry_entry.dart';
import '../../data/models/staff_user_model.dart';

import '../../core/notifications/top_notifier.dart';
import '../../l10n/app_strings.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

enum _PermKind { inherited, explicit, extra, removed }

class _UsersManagementPageState extends State<UsersManagementPage> {
  List<StaffUserDto> _users = [];
  List<StaffRoleDto> _roles = [];
  List<PermissionRegistryEntry>? _permissionRegistry;
  String? _error;
  bool _loading = true;

  /// API `GET /auth/permissions`, sinon repli sur les constantes locales.
  List<PermissionRegistryEntry> get _permissionRows => _permissionRegistry ??
      [
        for (final k in kAppPermissionKeys)
          PermissionRegistryEntry(
            key: k,
            label: kPermissionLabelsFr[k] ?? k,
          ),
      ];

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ur = await Future.wait([
        widget.api.dio.get<List<dynamic>>('/users'),
        widget.api.dio.get<List<dynamic>>('/users/roles'),
      ]);
      final uData = ur[0];
      final rData = ur[1];

      _users = (uData.data ?? [])
          .map((e) => StaffUserDto.fromJson(e as Map<String, dynamic>))
          .toList();
      _roles = (rData.data ?? [])
          .map((e) => StaffRoleDto.fromJson(e as Map<String, dynamic>))
          .toList();

      _permissionRegistry = null;
      try {
        final pData =
            await widget.api.dio.get<List<dynamic>>('/auth/permissions');
        final raw = pData.data;
        if (raw != null && raw.isNotEmpty) {
          _permissionRegistry = raw
              .map(
                (e) => PermissionRegistryEntry.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList();
        }
      } catch (_) {
        _permissionRegistry = null;
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 403) {
        if (!mounted) return;
        final str = AppStrings.of(context);
        setState(() => _error = str.users403);
      } else {
        setState(() => _error = e.response?.data?.toString() ?? e.message);
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _openEditor({StaffUserDto? existing}) async {
    final str = AppStrings.of(context);
    final userCtrl = TextEditingController(text: existing?.username ?? '');
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final fullCtrl = TextEditingController(text: existing?.fullName ?? '');
    String roleName =
        existing?.role.name ?? (_roles.isNotEmpty ? _roles.first.name : '');
    var active = existing?.isActive ?? true;
    var obscurePassword = true;
    var obscureConfirmPassword = true;
    var inheritPerms = existing?.permissions == null;
    final explicitSelected = <String>{
      if (existing?.permissions != null) ...existing!.permissions!,
    };

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(
            existing == null ? str.usersNewTitle : str.usersEditTitle,
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: userCtrl,
                    enabled: existing == null,
                    decoration: InputDecoration(
                      labelText: str.loginUsername,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: existing == null
                          ? str.usersPasswordNew
                          : str.usersPasswordOptional,
                      suffixIcon: IconButton(
                        tooltip: str.loginPasswordVisibilityTooltip(
                          !obscurePassword,
                        ),
                        onPressed: () {
                          setLocal(() => obscurePassword = !obscurePassword);
                        },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirmPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: str.usersPasswordConfirm,
                      suffixIcon: IconButton(
                        tooltip: str.loginPasswordVisibilityTooltip(
                          !obscureConfirmPassword,
                        ),
                        onPressed: () {
                          setLocal(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: fullCtrl,
                    decoration: InputDecoration(
                      labelText: str.usersFullNameField,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownMenu<String>(
                    initialSelection:
                        roleName.isEmpty ? null : roleName,
                    label: Text(str.usersRoleField),
                    dropdownMenuEntries: [
                      for (final r in _roles)
                        DropdownMenuEntry(
                          value: r.name,
                          label: str.userRole(r.name),
                        ),
                    ],
                    onSelected: (v) {
                      if (v != null) setLocal(() => roleName = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(str.usersActiveSwitch),
                    value: active,
                    onChanged: (v) => setLocal(() => active = v),
                  ),
                  const Divider(height: 24),
                  SwitchListTile(
                    title: Text(str.usersInheritTitle),
                    subtitle: Text(str.usersInheritSubtitle),
                    value: inheritPerms,
                    onChanged: (v) {
                      setLocal(() {
                        inheritPerms = v;
                        if (!inheritPerms && explicitSelected.isEmpty) {
                          if (existing != null) {
                            explicitSelected.addAll(existing.effectivePermissions);
                          } else {
                            explicitSelected.addAll(
                              kRoleDefaultPermissions[roleName] ?? const [],
                            );
                          }
                        }
                      });
                    },
                  ),
                  if (!inheritPerms) ...[
                    const SizedBox(height: 8),
                    Text(
                      str.usersPrivileges,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    ..._permissionRows.map((row) {
                      final key = row.key;
                      final label =
                          str.isAr ? str.permissionLabel(key) : row.label;
                      final checked = explicitSelected.contains(key);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(label),
                        subtitle:
                            Text(key, style: const TextStyle(fontSize: 11)),
                        value: checked,
                        onChanged: (on) {
                          setLocal(() {
                            if (on == true) {
                              explicitSelected.add(key);
                            } else {
                              explicitSelected.remove(key);
                            }
                          });
                        },
                      );
                    }),
                  ],
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
              child: Text(str.save),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;

    final password = passCtrl.text;
    final confirmPassword = confirmPassCtrl.text;

    if (existing == null) {
      if (password.trim().length < 8) {
        TopNotifier.error(context, str.usersPwdMin8);
        return;
      }
      if (password != confirmPassword) {
        TopNotifier.error(context, str.usersPasswordMismatch);
        return;
      }
    } else if (password.isNotEmpty || confirmPassword.isNotEmpty) {
      if (password.trim().length < 8) {
        TopNotifier.error(context, str.usersPwdMin8);
        return;
      }
      if (password != confirmPassword) {
        TopNotifier.error(context, str.usersPasswordMismatch);
        return;
      }
    }

    if (roleName.isEmpty) {
      TopNotifier.error(context, str.usersPickRole);
      return;
    }

    try {
      if (existing == null) {
        await widget.api.dio.post('/users', data: {
          'username': userCtrl.text.trim(),
          'password': password,
          'fullName': fullCtrl.text.trim().isEmpty
              ? null
              : fullCtrl.text.trim(),
          'role': roleName,
          'isActive': active,
          'permissions': inheritPerms ? null : explicitSelected.toList(),
        });
      } else {
        final body = <String, dynamic>{
          'fullName': fullCtrl.text.trim().isEmpty
              ? null
              : fullCtrl.text.trim(),
          'role': roleName,
          'isActive': active,
          'permissions': inheritPerms ? null : explicitSelected.toList(),
        };
        if (password.trim().length >= 8) {
          body['password'] = password.trim();
        }
        await widget.api.dio.patch('/users/${existing.id}', data: body);
      }
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.usersSaved);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.posErrorGeneric,
      );
    }
  }

  Future<void> _deactivate(StaffUserDto u) async {
    final str = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(str.usersDeactivateTitle),
        content: Text(u.username),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(str.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(str.yes),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await widget.api.dio.delete('/users/${u.id}');
      await _refresh();
      if (mounted) {
        TopNotifier.success(context, str.usersDeactivatedOk);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(
        context,
        e.response?.data?.toString() ?? e.message ?? str.posErrorGeneric,
      );
    }
  }

  String _labelForPermissionKey(String key) {
    final str = AppStrings.of(context);
    if (str.isAr) return str.permissionLabel(key);
    for (final r in _permissionRows) {
      if (r.key == key) return r.label;
    }
    return kPermissionLabelsFr[key] ?? key;
  }

  /// Carte utilisateur avec un panneau extensible affichant les permissions
  /// effectives. Les permissions héritées du rôle sont distinguées des
  /// permissions explicitement attribuées à l'utilisateur.
  Widget _buildUserCard(StaffUserDto u) {
    final str = AppStrings.of(context);
    final theme = Theme.of(context);
    final roleDefault =
        kRoleDefaultPermissions[u.role.name] ?? const <String>[];
    final inheritedSet = roleDefault.toSet();
    final effective = u.effectivePermissions;
    final stored = u.permissions;
    final usesRole = u.usesRoleDefaultPermissions;
    final extras = !usesRole && stored != null
        ? stored.where((k) => !inheritedSet.contains(k)).toList()
        : const <String>[];
    final missing = !usesRole && stored != null
        ? inheritedSet.where((k) => !stored.contains(k)).toList()
        : const <String>[];

    Color customColor =
        usesRole ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            Expanded(
              child: Text(
                u.username,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!u.isActive)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  str.usersInactive,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: customColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                usesRole ? str.usersRightsRole : str.usersRightsCustom,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: customColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${str.userRole(u.role.name)}'
            '${u.fullName != null && u.fullName!.trim().isNotEmpty ? ' · ${u.fullName}' : ''}'
            ' · ${str.usersPermCount(effective.length)}',
            style: theme.textTheme.bodySmall,
          ),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: str.usersTooltipEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEditor(existing: u),
            ),
            if (u.isActive)
              IconButton(
                tooltip: str.usersTooltipDeactivate,
                icon: const Icon(Icons.person_off_outlined),
                onPressed: () => _deactivate(u),
              ),
          ],
        ),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              str.usersPermEffectiveHeader,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 6),
          if (effective.isEmpty)
            Text(
              str.usersNoPerms,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in effective)
                  _buildPermChip(
                    label: _labelForPermissionKey(p),
                    key_: p,
                    kind: usesRole || inheritedSet.contains(p)
                        ? _PermKind.inherited
                        : _PermKind.explicit,
                  ),
              ],
            ),
          if (extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                str.usersExtrasTitle,
                style: theme.textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in extras)
                  _buildPermChip(
                    label: _labelForPermissionKey(p),
                    key_: p,
                    kind: _PermKind.extra,
                  ),
              ],
            ),
          ],
          if (missing.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                str.usersMissingTitle,
                style: theme.textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in missing)
                  _buildPermChip(
                    label: _labelForPermissionKey(p),
                    key_: p,
                    kind: _PermKind.removed,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermChip({
    required String label,
    required String key_,
    required _PermKind kind,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg, IconData icon) = switch (kind) {
      _PermKind.inherited => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.shield_outlined,
      ),
      _PermKind.explicit => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        Icons.tune,
      ),
      _PermKind.extra => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.add_circle_outline,
      ),
      _PermKind.removed => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.block,
      ),
    };
    return Tooltip(
      message: key_,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: fg, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    if (_loading && _users.isEmpty && _roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_error!, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _refresh, child: Text(str.retry)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Text(
                    str.usersPageTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _refresh,
                    tooltip: str.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                str.usersPageSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ..._users.map(_buildUserCard),
            ],
          ),
        ),
        Positioned(
          right: 32,
          bottom: 32,
          child: FloatingActionButton.extended(
            heroTag: 'fab_users_mgmt',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(str.usersFab),
          ),
        ),
      ],
    );
  }
}
