import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/auth/saved_login_credentials.dart';
import '../../core/notifications/top_notifier.dart';
import '../../core/session/auth_session_store.dart';
import '../../l10n/app_strings.dart';
import '../shell/main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final saved = await SavedLoginCredentials.load();
    if (!mounted) return;
    setState(() {
      _rememberMe = saved.remember;
      if (saved.remember) {
        if (saved.username != null) _userCtrl.text = saved.username!;
        if (saved.password != null) _passCtrl.text = saved.password!;
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _persistCredentials() async {
    final username = _userCtrl.text.trim();
    final password = _passCtrl.text;
    if (_rememberMe) {
      await SavedLoginCredentials.save(username, password);
    } else {
      await SavedLoginCredentials.clear();
    }
  }

  Future<void> _login() async {
    final str = AppStrings.of(context);
    setState(() => _loading = true);
    final api = ApiClient();
    try {
      final res = await api.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': _userCtrl.text.trim(), 'password': _passCtrl.text},
      );
      final data = res.data;
      final token = data?['accessToken'] as String?;
      final user = data?['user'] as Map<String, dynamic>?;
      if (token == null || user == null) {
        throw StateError('Réponse login invalide');
      }
      await _persistCredentials();
      await AuthSessionStore.save(token, user);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShellScreen(api: api, user: user),
        ),
      );
    } on DioException catch (e) {
      if (mounted) TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (e) {
      if (mounted) TopNotifier.error(context, '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openResetPasswordDialog() async {
    final str = AppStrings.of(context);
    final username = _userCtrl.text.trim();
    if (username.isEmpty) {
      TopNotifier.warning(context, str.loginUsername);
      return;
    }

    final currentCtrl = TextEditingController(text: _passCtrl.text);
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return AlertDialog(
            title: Text(str.loginResetTitle),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: str.loginUsername,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      child: Text(username),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: currentCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: str.loginCurrentPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setModal(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: str.loginNewPassword,
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setModal(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: str.loginConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setModal(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
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
                child: Text(str.loginApplyReset),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true || !mounted) return;

    if (newCtrl.text.length < 8) {
      TopNotifier.warning(context, str.usersValidationPassword);
      return;
    }
    if (newCtrl.text != confirmCtrl.text) {
      TopNotifier.warning(context, str.loginPasswordMismatch);
      return;
    }

    final api = ApiClient();
    try {
      await api.dio.post(
        '/auth/change-password',
        data: {
          'username': username,
          'currentPassword': currentCtrl.text,
          'newPassword': newCtrl.text,
        },
      );
      if (!mounted) return;
      setState(() => _passCtrl.text = newCtrl.text);
      if (_rememberMe) {
        await SavedLoginCredentials.save(username, newCtrl.text);
      }
      TopNotifier.success(context, str.loginPasswordChanged);
    } on DioException catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, userFacingDioMessage(e, str));
    } catch (e) {
      if (!mounted) return;
      TopNotifier.error(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final str = AppStrings.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/restaurant_logo.jpg',
                    height: 72,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.restaurant, size: 72),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    str.loginTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userCtrl,
                    decoration: InputDecoration(
                      labelText: str.loginUsername,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: str.loginPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: _obscurePassword ? 'Afficher' : 'Masquer',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _rememberMe = v ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _loading
                              ? null
                              : () => setState(() => _rememberMe = !_rememberMe),
                          child: Text(str.loginRemember),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _openResetPasswordDialog,
                      child: Text(str.loginResetPassword),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(str.loginSubmit),
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
