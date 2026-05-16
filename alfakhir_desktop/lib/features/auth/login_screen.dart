import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/api/dio_error_message.dart';
import '../../core/auth/saved_login_credentials.dart';
import '../../l10n/app_strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.api,
    required this.onSuccess,
  });

  final ApiClient api;
  final void Function(Map<String, dynamic> user) onSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _rememberCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    await SavedLoginCredentials.consumeSkipNextAutoLogin();
    final saved = await SavedLoginCredentials.load();
    if (!mounted) return;
    setState(() {
      _rememberCredentials = saved.remember;
      if (saved.username != null && saved.username!.isNotEmpty) {
        _userCtrl.text = saved.username!;
      }
      if (saved.password != null && saved.password!.isNotEmpty) {
        _passCtrl.text = saved.password!;
      }
    });
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.api.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': _userCtrl.text.trim(),
          'password': _passCtrl.text,
        },
      );
      final data = res.data;
      if (data == null) {
        setState(() => _error = 'Réponse vide du serveur.');
        return;
      }
      final token = data['accessToken'] as String?;
      if (token == null || token.isEmpty) {
        setState(() => _error = 'Jeton d’accès manquant dans la réponse.');
        return;
      }
      widget.api.setAccessToken(token);
      if (_rememberCredentials) {
        await SavedLoginCredentials.save(
          _userCtrl.text.trim(),
          _passCtrl.text,
        );
      } else {
        await SavedLoginCredentials.clear();
      }
      final user = data['user'] as Map<String, dynamic>?;
      if (user == null) {
        setState(() => _error = 'Profil utilisateur manquant.');
        return;
      }
      widget.onSuccess(user);
    } on DioException catch (e) {
      if (!mounted) return;
      final labels = AppStrings.of(context);
      setState(() => _error = userFacingDioMessage(e, labels));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final str = AppStrings.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        str.appTitle,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        str.loginBrandSubtitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        str.loginContinue,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _userCtrl,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        decoration: InputDecoration(
                          labelText: str.loginUsername,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return str.loginFieldRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: str.loginPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: str.loginPasswordVisibilityTooltip(
                              !_obscurePassword,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return str.loginFieldRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _rememberCredentials,
                        onChanged: (v) {
                          setState(() => _rememberCredentials = v ?? false);
                        },
                        title: Text(
                          str.loginRememberCredentials,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(str.loginButton),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
