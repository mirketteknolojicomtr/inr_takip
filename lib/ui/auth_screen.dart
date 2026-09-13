/// E-posta/parola ile giriş & kayıt ekranı.
/// Firebase Authentication başarıyla oturum açtığında
/// `FirebaseAuthService.authStateChanges` tetiklenir; main.dart bu akışı
/// dinleyip HomeScreen'e geçer (bkz. main.dart AuthGate).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';

import '../services/firebase_auth_service.dart';

class AuthScreen extends StatefulWidget {
  final FirebaseAuthService authService;

  const AuthScreen({super.key, required this.authService});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _errorTr;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Firebase hata kodunu kullanıcının dilindeki cümleye çevirir.
  /// Tanınmayan kod için genel mesaj verilir — ham SDK metni İngilizcedir
  /// ve kullanıcıya gösterilmez.
  String _describeError(Loc loc, FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => loc.l10n.authErrorInvalidEmail,
        'user-disabled' => loc.l10n.authErrorUserDisabled,
        'user-not-found' => loc.l10n.authErrorUserNotFound,
        'wrong-password' ||
        'invalid-credential' =>
          loc.l10n.authErrorWrongPassword,
        'email-already-in-use' => loc.l10n.authErrorEmailInUse,
        'weak-password' => loc.l10n.authErrorWeakPassword,
        'operation-not-allowed' => loc.l10n.authErrorNotEnabled,
        _ => loc.l10n.authErrorGeneric,
      };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorTr = null;
    });

    try {
      if (_isSignUp) {
        await widget.authService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await widget.authService.signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      }
      // Başarılıysa authStateChanges tetiklenir, main.dart yönlendirir.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorTr = _describeError(context.loc, e));
    } catch (e) {
      if (mounted) {
        setState(() => _errorTr = context.loc.l10n.authErrorGeneric);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      appBar: AppBar(title: const Text('INR Takip')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.favorite,
                      size: 48, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    _isSignUp ? loc.l10n.authSignUpTitle : loc.l10n.authSignInTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        InputDecoration(labelText: loc.l10n.emailLabel),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? loc.l10n.authEmailInvalid
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: loc.l10n.passwordLabel),
                    validator: (v) => (v == null || v.length < 6)
                        ? loc.l10n.authPasswordTooShort
                        : null,
                  ),
                  if (_errorTr != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorTr!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUp
                            ? loc.l10n.authSignUpAction
                            : loc.l10n.authSignInAction),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _errorTr = null;
                            }),
                    child: Text(_isSignUp
                        ? loc.l10n.authHaveAccount
                        : loc.l10n.authNoAccount),
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
