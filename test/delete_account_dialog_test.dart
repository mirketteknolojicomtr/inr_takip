/// Hesap silme onayının parola zorunluluğunu ve hata/başarı akışını
/// doğrular.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/ui/delete_account_dialog.dart';

import 'l10n_helper.dart';

/// Pencereyi bir butonla açar; kapanınca dönen değeri [result]'a yazar.
Widget _host(
  Future<String?> Function(String) onConfirm,
  void Function(bool?) result,
) {
  return localizedApp(Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async => result(await showDialog<bool>(
            context: context,
            builder: (_) => DeleteAccountDialog(onConfirm: onConfirm),
          )),
          child: const Text('aç'),
        ),
      ),
    ),
  ));
}

void main() {
  Finder confirmButton() =>
      find.widgetWithText(FilledButton, 'Kalıcı olarak sil');

  testWidgets('parola girilmeden silme butonu pasiftir', (tester) async {
    await tester.pumpWidget(_host((_) async => null, (_) {}));
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(confirmButton()).onPressed, isNull);
  });

  testWidgets('başarılı silmede parola iletilir ve pencere kapanır',
      (tester) async {
    String? received;
    bool? closedWith;
    await tester.pumpWidget(_host((password) async {
      received = password;
      return null;
    }, (value) => closedWith = value));

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'gizli123');
    await tester.pump();
    await tester.tap(confirmButton());
    await tester.pumpAndSettle();

    expect(received, 'gizli123');
    expect(closedWith, isTrue);
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('hatada mesaj gösterilir ve pencere açık kalır', (tester) async {
    await tester.pumpWidget(
      _host((_) async => 'E-posta veya parola hatalı.', (_) {}),
    );

    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'yanlis');
    await tester.pump();
    await tester.tap(confirmButton());
    await tester.pumpAndSettle();

    expect(find.text('E-posta veya parola hatalı.'), findsOneWidget);
    expect(find.byType(DeleteAccountDialog), findsOneWidget);
  });
}
