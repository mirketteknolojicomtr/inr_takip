/// E-posta/parola ile giriş & kayıt ekranı.
/// Firebase Authentication başarıyla oturum açtığında
/// `FirebaseAuthService.authStateChanges` tetiklenir; main.dart bu akışı
/// dinleyip HomeScreen'e geçer (bkz. main.dart AuthGate).
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  String _describeError(FirebaseAuthException e) => switch (e.code) {
        'invalid-email' => 'Geçersiz e-posta adresi.',
        'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
        'user-not-found' => 'Bu e-posta ile kayıtlı bir hesap bulunamadı.',
        'wrong-password' || 'invalid-credential' => 'E-posta veya parola hatalı.',
        'email-already-in-use' => 'Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin.',
        'weak-password' => 'Parola çok zayıf (en az 6 karakter).',
        'operation-not-allowed' =>
          'E-posta/parola girişi Firebase Console\'da henüz etkinleştirilmemiş.',
        _ => 'Bir hata oluştu: ${e.message ?? e.code}',
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
      if (mounted) setState(() => _errorTr = _describeError(e));
    } catch (e) {
      if (mounted) setState(() => _errorTr = 'Beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    _isSignUp ? 'Hesap Oluştur' : 'Giriş Yap',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Geçerli bir e-posta girin'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Parola'),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'En az 6 karakter olmalı'
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
                        : Text(_isSignUp ? 'Kayıt Ol' : 'Giriş Yap'),
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
                        ? 'Zaten hesabım var, giriş yap'
                        : 'Hesabım yok, kayıt ol'),
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
