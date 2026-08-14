/// Örnek uygulama girişi.
/// Amaç: katmanların nasıl bağlandığını göstermek (manuel DI).
/// Gerçek projede Riverpod/Bloc ile aynı bağlama yapılır (bkz. ARCHITECTURE.md).
library;

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'firebase_options.dart';
import 'models/inr_entry.dart';
import 'models/patient_profile.dart';
import 'repositories/sqflite_repositories.dart';
import 'services/alert_service.dart';
import 'services/comorbidity_background_scheduler.dart';
import 'services/comorbidity_sync_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firestore_profile_sync_service.dart';
import 'services/health_background_observer.dart';
import 'services/health_package_metrics_gateway.dart';
import 'services/local_notification_gateway.dart';
import 'services/lock_screen_sync_service.dart';
import 'services/reminder_service.dart';
import 'services/sms_emergency_gateway.dart';
import 'services/trend_service.dart';
import 'ui/auth_screen.dart';
import 'ui/inr_ambient_hero.dart';
import 'ui/inr_scan_screen.dart';
import 'ui/inr_trend_chart.dart';
import 'ui/profile_screen.dart';
import 'ui/steady_touch.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const InrTakipApp());
}

class InrTakipApp extends StatelessWidget {
  const InrTakipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INR Takip',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF8E24AA),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Oturum durumuna göre [AuthScreen] veya [HomeScreen] gösterir. Firebase
/// Authentication (e-posta/parola) ile korunur -- bkz. firebase_auth_service.dart.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return AuthScreen(authService: authService);
        }
        return HomeScreen(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String uid;

  const HomeScreen({super.key, required this.uid});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Manuel DI (demo) ---
  final _inrRepo = SqfliteInrRepository();
  final _kRepo = SqfliteVitaminKRepository();
  final _profileRepo = SqfliteProfileRepository();
  late final _trendService = TrendService(_inrRepo, _kRepo);
  final _notificationGateway = LocalNotificationGateway();
  late final _alertService =
      AlertService(_notificationGateway, SmsEmergencyGateway());
  late final _lockScreenSync = LockScreenSyncService(
    _inrRepo,
    _profileRepo,
    HomeWidgetLockScreenGateway(),
  );
  late final _comorbiditySync = ComorbiditySyncService(
    HealthPackageMetricsGateway(),
    _notificationGateway,
  );
  late final _healthObserver = HealthBackgroundObserver(_comorbiditySync, _inrRepo);
  final _backgroundScheduler = ComorbidityBackgroundScheduler();
  final _authService = FirebaseAuthService();
  final _firestoreSync = FirestoreProfileSyncService();
  bool _checkingComorbidity = false;

  static const _defaultProfile = PatientProfile(
    name: 'Demo Hasta',
    emergencyContact: EmergencyContact(name: 'Yakını', phone: '+90XXXXXXXXXX'),
    schedule: MedicationSchedule(hour: 19, minute: 0),
  );

  final _uuid = const Uuid();
  InrTrendData? _trend;

  /// İlk yüklemeye kadar null -- kalıcı depodan (SqfliteProfileRepository)
  /// okunur, hiç kayıt yoksa (ilk açılış) [_defaultProfile] kaydedilip
  /// kullanılır.
  PatientProfile? _profile;

  /// _bootstrap() başarısız olursa (ör. sqflite native plugin bir sebeple
  /// yanıt vermezse) burada tutulur; UI sonsuz spinner yerine hatayı
  /// gösterir.
  Object? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _notificationGateway.initialize();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      var profile = await _profileRepo
          .getProfile()
          .timeout(const Duration(seconds: 10));
      final isFirstLaunch = profile == null;
      profile ??= _defaultProfile;

      if (isFirstLaunch) {
        await _profileRepo.saveProfile(profile);
        await _seedDemoData();
      }

      // Firestore senkronu: bulutta bu kullanıcı için kayıt varsa (başka
      // bir cihazdan kaydedilmiş olabilir) o kazanır ve yerel depoya
      // yazılır; yoksa yerel profil buluta gönderilir (bu cihaz
      // bulut kopyasını ilk kez oluşturur).
      try {
        final remoteProfile =
            await _firestoreSync.pull(widget.uid).timeout(const Duration(seconds: 10));
        if (remoteProfile != null) {
          profile = remoteProfile;
          await _profileRepo.saveProfile(profile);
        } else {
          await _firestoreSync.push(widget.uid, profile);
        }
      } catch (e) {
        // Firestore'a erişilemiyorsa (çevrimdışı vb.) yerel profille devam
        // et -- bulut senkronu isteğe bağlı bir katman, uygulamayı bloklamaz.
        debugPrint('[FIRESTORE SENKRON HATASI] $e');
      }

      if (!mounted) return;
      setState(() => _profile = profile);

      await _refreshTrend();
      _lockScreenSync.start();

      // Arka plan senkronizasyonu: Android'de WorkManager (periyodik),
      // iOS'ta HealthKit HKObserverQuery (olay bazlı) -- bkz. ilgili
      // dosyaların başındaki platform notları.
      if (Platform.isAndroid) {
        await _backgroundScheduler.initializeAndSchedule();
      } else if (Platform.isIOS) {
        _healthObserver.start();
      }
    } catch (e, stack) {
      debugPrint('[BOOTSTRAP HATASI] $e\n$stack');
      if (mounted) setState(() => _bootstrapError = e);
    }
  }

  @override
  void dispose() {
    _lockScreenSync.dispose();
    super.dispose();
  }

  Future<void> _seedDemoData() async {
    final now = DateTime.now();
    final demo = [2.4, 2.6, 2.2, 1.9, 2.8, 3.1, 2.5, 2.7];
    for (var i = 0; i < demo.length; i++) {
      await _inrRepo.upsert(InrEntry(
        id: _uuid.v4(),
        date: now.subtract(Duration(days: (demo.length - i) * 3)),
        inrValue: demo[i],
        doseMg: 5.0,
      ));
    }
  }

  Future<void> _refreshTrend() async {
    final trend = await _trendService.buildTrend(days: 30);
    if (mounted) setState(() => _trend = trend);
  }

  /// Profil ekranını açar; kaydedilirse yerel depo + Firestore + kilit
  /// ekranı widget'ı güncellenir.
  Future<void> _openProfile(BuildContext context) async {
    final current = _profile;
    if (current == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          initialProfile: current,
          onSave: (updated) async {
            await _profileRepo.saveProfile(updated);
            await _firestoreSync.push(widget.uid, updated);
            if (mounted) setState(() => _profile = updated);
          },
        ),
      ),
    );
  }

  /// Yeni ölçüm akışı: kaydet -> uyarı değerlendir -> grafiği tazele.
  /// Yalnızca profil yüklendikten sonra erişilebilen UI'dan çağrılır
  /// (bkz. build()), bu yüzden `_profile!` güvenli.
  Future<void> _addMeasurement(double inr, double doseMg) async {
    final profile = _profile!;
    final entry = InrEntry(
      id: _uuid.v4(),
      date: DateTime.now(),
      inrValue: inr,
      doseMg: doseMg,
      targetRange: profile.targetRange,
    );
    await _inrRepo.upsert(entry);
    final alert = await _alertService.processNewEntry(entry, profile);
    await _refreshTrend();

    if (alert != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: alert.severity == AlertSeverity.critical
              ? Colors.red.shade700
              : Colors.amber.shade800,
          content: Text('${alert.titleTr}\n${alert.messageTr}'),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  /// AppBar'daki "Şimdi kontrol et" ile manuel tetiklenir. Otomatik
  /// zamanlama da aktif: Android'de WorkManager (periyodik), iOS'ta
  /// HealthKit HKObserverQuery (olay bazlı) -- bkz. _bootstrap().
  Future<void> _checkComorbidityNow() async {
    setState(() => _checkingComorbidity = true);
    try {
      final latest = await _inrRepo.getLatest();
      final alert = await _comorbiditySync.checkNow(latest);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alert == null
                ? 'Ödem/kalp senkronizasyonu: risk bulunamadı.'
                : 'Risk tespit edildi: ${alert.weightDeltaKg.toStringAsFixed(1)} kg artış + hedef dışı INR.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingComorbidity = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      final error = _bootstrapError;
      if (error != null) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Uygulama başlatılamadı',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$error', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      setState(() => _bootstrapError = null);
                      _bootstrap();
                    },
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('INR Takip'),
        actions: [
          IconButton(
            tooltip: 'Ödem/kalp senkronizasyonunu şimdi kontrol et',
            icon: _checkingComorbidity
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.monitor_heart_outlined),
            onPressed: _checkingComorbidity ? null : _checkComorbidityNow,
          ),
          IconButton(
            tooltip: 'Profil',
            icon: const Icon(Icons.person_outline),
            onPressed: () => _openProfile(context),
          ),
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_trend != null && _trend!.points.isNotEmpty)
            AmbientInrHero(
              inrValue: _trend!.points.last.inr,
              zone: _trend!.points.last.zone,
            ),
          if (_trend != null && _trend!.points.isNotEmpty)
            const SizedBox(height: 16),
          DoseCountdownWidget(
            schedule: profile.schedule,
            onTakenPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Doz kaydedildi 💊')),
            ),
          ),
          const SizedBox(height: 16),
          Text('Son 30 Gün',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_trend != null) InrTrendChart(data: _trend!),
          if (_trend != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Hedef aralıkta kalma: %${_trend!.inRangePercent.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'scan',
            tooltip: 'Kamerayla Tara',
            onPressed: () => _openScanner(context),
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'manual',
            icon: const Icon(Icons.add),
            label: const Text('Ölçüm Ekle'),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
    );
  }

  /// Kamera ile INR tarama akışını açar; bir değer yakalanırsa
  /// doz girişi için ekleme diyaloğunu o değerle önceden doldurur.
  Future<void> _openScanner(BuildContext context) async {
    final value = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => const InrScanScreen()),
    );
    if (!mounted || value == null) return;
    _showAddDialog(context, prefillInr: value);
  }

  Future<void> _showAddDialog(BuildContext context, {double? prefillInr}) async {
    final inrCtrl = TextEditingController(
      text: prefillInr != null ? prefillInr.toStringAsFixed(1) : '',
    );
    final doseCtrl = TextEditingController(text: '5.0');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        void trySave() {
          final inr = double.tryParse(inrCtrl.text.replaceAll(',', '.'));
          final dose = double.tryParse(doseCtrl.text.replaceAll(',', '.'));
          if (inr != null && dose != null) {
            Navigator.pop(ctx);
            _addMeasurement(inr, dose);
          }
        }

        return SteadyTouchArea(
          child: AlertDialog(
            title: const Text('Yeni INR Ölçümü'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: inrCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'INR değeri'),
                ),
                TextField(
                  controller: doseCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Doz (mg/gün)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal')),
              SteadyTouchTarget(
                id: 'kaydet',
                onConfirm: trySave,
                child: FilledButton(
                  onPressed: trySave,
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
