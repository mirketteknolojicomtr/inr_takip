/// "Hesabımı sil" onayı (App Store kuralı 5.1.1(v)).
///
/// Firebase hesabı silmeden önce yakın zamanlı giriş istediği için parola
/// burada alınır. Silme bitene kadar pencere açık kalır; yanlış parola veya
/// bağlantı hatasında mesaj gösterilir ve kullanıcı tekrar deneyebilir.
library;

import 'package:flutter/material.dart';

import '../l10n/domain_labels.dart';

class DeleteAccountDialog extends StatefulWidget {
  /// Parolayla yeniden doğrulayıp hesabı ve tüm verileri siler.
  /// Başarıda `null`, hatada kullanıcıya gösterilecek mesajı döner.
  final Future<String?> Function(String password) onConfirm;

  const DeleteAccountDialog({super.key, required this.onConfirm});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onConfirm(_passwordCtrl.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);
    final canConfirm = !_busy && _passwordCtrl.text.isNotEmpty;

    return AlertDialog(
      title: Text(loc.l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.l10n.deleteAccountWarning),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              enabled: !_busy,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: loc.l10n.deleteAccountPasswordLabel,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(loc.l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: canConfirm ? _confirm : null,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(loc.l10n.deleteAccountConfirm),
        ),
      ],
    );
  }
}
