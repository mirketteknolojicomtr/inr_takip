/// Yakınla paylaşım: özet metni ve kişi yokken davranış.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:inr_takip/models/inr_entry.dart';
import 'package:inr_takip/models/patient_profile.dart';
import 'package:inr_takip/l10n/domain_labels.dart';
import 'package:inr_takip/services/caregiver_share_service.dart';
import 'package:inr_takip/services/medication_service.dart';

import 'l10n_helper.dart';

class FakeShareGateway implements CaregiverShareGateway {
  String? phone;
  String? text;
  bool available = true;

  @override
  Future<bool> share({required String phone, required String text}) async {
    this.phone = phone;
    this.text = text;
    return available;
  }
}

const _contact = EmergencyContact(name: 'Kızı Ayşe', phone: '+905551112233');

const _profile = PatientProfile(
  name: 'Mehmet Yılmaz',
  emergencyContact: _contact,
);

InrEntry _entry(double inr) => InrEntry(
      id: 'e1',
      date: DateTime(2026, 8, 28),
      inrValue: inr,
      doseMg: 5,
      targetRange: TargetRange.standard,
    );

void main() {
  late FakeShareGateway gateway;
  late CaregiverShareService service;
  late Loc loc;

  setUp(() async {
    gateway = FakeShareGateway();
    service = CaregiverShareService(gateway);
    loc = await testLoc();
  });

  test('özet son INR, hedef aralık ve uyum oranını içerir', () {
    final summary = service.buildSummary(
      loc,
      profile: _profile,
      latestInr: _entry(2.4),
      adherence: const AdherenceSummary(
        scheduled: 7,
        taken: 6,
        skipped: 1,
        missed: 0,
      ),
      now: DateTime(2026, 8, 30),
    );

    expect(summary, contains('Mehmet Yılmaz'));
    expect(summary, contains('2,4'));
    expect(summary, contains('Hedefte'));
    expect(summary, contains('2,0–3,0'));
    expect(summary, contains('86'));
    expect(summary, contains('30.08.2026'));
  });

  test('kritik değer özet metninde açıkça belirtilir', () {
    final summary = service.buildSummary(
      loc,
      profile: _profile,
      latestInr: _entry(5.2),
      now: DateTime(2026, 8, 30),
    );

    expect(summary, contains('Kritik yüksek'));
  });

  test('veri yoksa o satırlar hiç yazılmaz', () {
    final summary = service.buildSummary(
      loc,
      profile: _profile,
      now: DateTime(2026, 8, 30),
    );

    expect(summary, contains('Henüz INR ölçümü kaydedilmedi'));
    expect(summary, isNot(contains('uyumu')));
    expect(summary, isNot(contains('Bugünkü doz')));
  });

  test('acil durum kişisi yoksa gönderim denenmez', () async {
    final result = await service.shareWithContact(
      loc,
      profile: const PatientProfile(name: 'Yalnız'),
    );

    expect(result, CaregiverShareResult.noContact);
    expect(gateway.text, isNull);
  });

  test('kişi varsa özet o numaraya gider', () async {
    final result = await service.shareWithContact(
      loc,
      profile: _profile,
      latestInr: _entry(2.4),
      now: DateTime(2026, 8, 30),
    );

    expect(result, CaregiverShareResult.opened);
    expect(gateway.phone, '+905551112233');
    expect(gateway.text, contains('2,4'));
  });

  test('cihazda mesaj uygulaması yoksa açıkça bildirilir', () async {
    gateway.available = false;

    final result = await service.shareWithContact(loc, profile: _profile);

    expect(result, CaregiverShareResult.unavailable);
  });
}
