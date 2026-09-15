/// Uygulama girişi ve manuel DI.
///
/// Katmanlar: UI -> Services -> Repositories -> Models (bkz. ARCHITECTURE.md).
/// Burada yalnızca bağlama (wiring) yapılır; iş mantığı servislerdedir.
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';

import 'config/revenuecat_config.dart';
import 'l10n/app_localizations.dart';
import 'l10n/domain_labels.dart';
import 'firebase_options.dart';
import 'models/inr_entry.dart';
import 'models/medication.dart';
import 'models/patient_profile.dart';
import 'repositories/sqflite_repositories.dart';
import 'services/alert_service.dart';
import 'services/app_settings.dart';
import 'services/caregiver_share_service.dart';
import 'services/comorbidity_background_scheduler.dart';
import 'services/comorbidity_sync_service.dart';
import 'services/entitlement_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/firestore_cloud_gateway.dart';
import 'services/health_background_observer.dart';
import 'services/health_package_metrics_gateway.dart';
import 'services/local_notification_gateway.dart';
import 'services/local_reminder_scheduler.dart';
import 'services/lock_screen_sync_service.dart';
import 'services/medication_service.dart';
import 'services/nfc_emergency_service.dart';
import 'services/pdf_report_service.dart';
import 'services/reminder_service.dart';
import 'services/revenuecat_entitlement_gateway.dart';
import 'services/sms_emergency_gateway.dart';
import 'services/trend_service.dart';
import 'ui/add_measurement_dialog.dart';
import 'ui/auth_screen.dart';
import 'ui/history_screen.dart';
import 'ui/inr_scan_screen.dart';
import 'ui/medications_screen.dart';
import 'ui/premium_gate.dart';
import 'ui/profile_screen.dart';
import 'ui/theme.dart';
import 'ui/today_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Mağaza anahtarı tanımlıysa RevenueCat, değilse herkesin ücretsiz
  // katmanda olduğu yedek gateway -- uygulama paywall yüzünden hiçbir
  // koşulda açılmamazlık etmez (bkz. config/revenuecat_config.dart).
  final EntitlementGateway gateway = RevenueCatConfig.isConfigured
      ? RevenueCatEntitlementGateway()
      : FakeEntitlementGateway(premium: RevenueCatConfig.debugPremium);

  // `intl` tarih/gün adlarını CLDR verisinden üretir; desteklenen tüm
  // diller için bu veri önceden yüklenmelidir, aksi hâlde ilk `DateFormat`
  // çağrısı LocaleDataException ile patlar.
  initializeDateFormatting();

  // Kayıtlı dil tercihi açılışta okunur: uygulama ilk karesinden itibaren
  // doğru dilde açılır, sonradan "zıplama" olmaz.
  final localeController = AppLocaleController(await AppSettings().locale());

  runApp(InrTakipApp(
    entitlements: EntitlementService(gateway),
    localeController: localeController,
  ));
}

/// Seçili dili ağaca yayar. `null` = cihaz dilini kullan.
///
/// Dil değişince yalnızca [MaterialApp] yeniden kurulur; ekranların
/// state'i korunur (kullanıcı formun ortasında dil değiştirebilir).
class AppLocaleController extends ValueNotifier<Locale?> {
  AppLocaleController(super.value);

  Future<void> select(Locale? locale) async {
    if (locale == value) return;
    value = locale;
    await AppSettings().setLocale(locale);
  }
}

class InrTakipApp extends StatelessWidget {
  final EntitlementService entitlements;
  final AppLocaleController localeController;

  const InrTakipApp({
    super.key,
    required this.entitlements,
    required this.localeController,
  });

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: localeController,
      child: PremiumScope(
        service: entitlements,
        child: ValueListenableBuilder<Locale?>(
          valueListenable: localeController,
          builder: (context, locale, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            // Cihaz dili desteklenmiyorsa Flutter'ın varsayılanı listenin
            // ilkine düşer; hangi dile düşüleceğini biz seçiyoruz.
            localeResolutionCallback: (device, supported) =>
                resolveSupportedLocale(locale ?? device),
            // Yaşlı kullanıcı sistem yazı boyutunu büyütebilsin, ama kartlar
            // taşmasın (bkz. ui/theme.dart).
            builder: (context, child) =>
                clampTextScale(context, child ?? const SizedBox.shrink()),
            home: AuthGate(entitlements: entitlements),
          ),
        ),
      ),
    );
  }
}

/// Dil denetleyicisini ağaçtan erişilebilir kılar (Profil ekranındaki
/// dil seçici bunu kullanır).
class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope?.notifier != null, 'AppLocaleScope üst ağaçta bulunamadı');
    return scope!.notifier!;
  }
}

/// Oturum durumuna göre [AuthScreen] veya [HomeShell] gösterir.
class AuthGate extends StatefulWidget {
  final EntitlementService entitlements;

  const AuthGate({super.key, required this.entitlements});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = FirebaseAuthService();
  String? _identifiedUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        // Aboneliği Firebase kullanıcısıyla eşle: telefon değişse de
        // abonelik hesapla birlikte gelir.
        if (user?.uid != _identifiedUid) {
          _identifiedUid = user?.uid;
          if (user == null) {
            widget.entitlements.signOut();
          } else {
            widget.entitlements.start(appUserId: user.uid);
          }
        }

        if (user == null) return AuthScreen(authService: _authService);
        return HomeShell(
          key: ValueKey(user.uid),
          uid: user.uid,
          authService: _authService,
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  final String uid;
  final FirebaseAuthService authService;

  /// Açılışta gösterilecek sekme (0=Bugün, 1=İlaçlarım, 2=Geçmiş, 3=Profil).
  /// Bildirimden gelen derin bağlantılar ve UI doğrulaması için.
  final int initialTab;

  const HomeShell({
    super.key,
    required this.uid,
    required this.authService,
    this.initialTab = 0,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // --- Manuel DI ---
  final _inrRepo = SqfliteInrRepository();
  final _kRepo = SqfliteVitaminKRepository();
  final _profileRepo = SqfliteProfileRepository();
  final _medicationRepo = SqfliteMedicationRepository();
  final _intakeRepo = SqfliteDoseIntakeRepository();

  late final _trendService = TrendService(_inrRepo, _kRepo);
  late final _pdfService = PdfReportService(_inrRepo);
  late final _medicationService =
      MedicationService(_medicationRepo, _intakeRepo);
  final _notificationGateway = LocalNotificationGateway(resolveLoc);
  final _reminderScheduler = LocalReminderScheduler(resolveLoc);
  // Dil sağlayıcısı olarak `resolveLoc` verilir: hem uygulama içinde hem
  // arka plan izolatında aynı kaynağı (sqflite'taki cihaz tercihi) okur,
  // böylece bildirim metni her zaman kullanıcının seçtiği dilde olur.
  late final _reminderService =
      MedicationReminderService(_reminderScheduler, resolveLoc);
  late final _alertService =
      AlertService(_notificationGateway, SmsEmergencyGateway(), resolveLoc);
  final _caregiverShare = const CaregiverShareService(SmsCaregiverShareGateway());
  /// Acil durum yüzeyleri. NFC kartı **ücretsiz** katmanda da yayınlanır
  /// (acil durum kartı `kAlwaysFreeFeatures` içinde); ana ekran widget'ı
  /// premium olduğu için abonelik doğrulanınca eklenir
  /// (bkz. _startPremiumServices).
  late final _lockScreenSync = LockScreenSyncService(
    _inrRepo,
    _profileRepo,
    [
      // iOS'ta üçüncü parti HCE yoktur; gateway orada UnsupportedError
      // fırlatacağı için hiç kaydedilmez (bkz. nfc_emergency_service.dart).
      if (Platform.isAndroid) NfcEmergencyService(PlatformChannelNfcGateway()),
    ],
    resolveLoc,
  );
  late final _comorbiditySync = ComorbiditySyncService(
    HealthPackageMetricsGateway(),
    _notificationGateway,
    resolveLoc,
  );
  late final _healthObserver =
      HealthBackgroundObserver(_comorbiditySync, _inrRepo);
  final _backgroundScheduler = ComorbidityBackgroundScheduler();
  final _deletionLog = SqfliteDeletionLog();
  late final _cloudSync = CloudSyncService(
    FirestoreCloudGateway(),
    _inrRepo,
    _medicationRepo,
    _profileRepo,
    _deletionLog,
  );
  final _uuid = const Uuid();

  static const _defaultProfile = PatientProfile(
    name: 'Hasta',
    emergencyContact: null,
    schedule: MedicationSchedule(hour: 19, minute: 0),
  );

  late int _tab = widget.initialTab;
  bool _premiumStartupDone = false;
  EntitlementService? _watchedEntitlements;
  PatientProfile? _profile;
  InrTrendData? _trend;
  MedicationDay? _medicationDay;
  Medication? _anticoagulant;
  Object? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _notificationGateway.initialize();
    _reminderScheduler.initialize();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Abonelik durumu SDK'dan asenkron gelir; premium açıldığında
    // (veya kullanıcı uygulama açıkken satın aldığında) bulut senkronu
    // ve sağlık taraması gibi ücretli katmanlar burada devreye girer.
    final entitlements = PremiumScope.of(context);
    if (identical(entitlements, _watchedEntitlements)) return;
    _watchedEntitlements?.removeListener(_onEntitlementChanged);
    _watchedEntitlements = entitlements..addListener(_onEntitlementChanged);
    _onEntitlementChanged();
  }

  void _onEntitlementChanged() {
    if (!mounted || _premiumStartupDone) return;
    final entitlements = _watchedEntitlements;
    if (entitlements == null || !entitlements.isReady) return;
    if (!entitlements.isPremium) return;
    _premiumStartupDone = true;
    _startPremiumServices();
  }

  /// Yalnızca premium kullanıcılar için çalışan arka plan katmanları.
  /// Ücretsiz kullanıcı tamamen yerel çalışır ve bulut maliyeti üretmez.
  Future<void> _startPremiumServices() async {
    final entitlements = _watchedEntitlements;
    if (entitlements == null) return;

    if (entitlements.has(PremiumFeature.cloudSync)) {
      await _syncWithCloud();
    }
    if (entitlements.has(PremiumFeature.lockScreenWidget)) {
      await _lockScreenSync.addGateway(HomeWidgetLockScreenGateway());
    }
    if (entitlements.has(PremiumFeature.healthSync)) {
      if (Platform.isAndroid) {
        await _backgroundScheduler.initializeAndSchedule();
      } else if (Platform.isIOS) {
        _healthObserver.start();
      }
    }
  }

  @override
  void dispose() {
    _watchedEntitlements?.removeListener(_onEntitlementChanged);
    _lockScreenSync.dispose();
    super.dispose();
  }

  EntitlementService get _entitlements => PremiumScope.read(context);

  Future<void> _bootstrap() async {
    try {
      var profile =
          await _profileRepo.getProfile().timeout(const Duration(seconds: 10));
      final isFirstLaunch = profile == null;
      profile ??= _defaultProfile;
      if (isFirstLaunch) await _profileRepo.saveProfile(profile);

      if (!mounted) return;
      setState(() => _profile = profile);

      await Future.wait([_refreshTrend(), _refreshMedications()]);

      // Acil durum yüzeyi (Android NFC kartı) ücretsizdir; abonelik
      // beklemeden başlar. Premium widget aynı akışa sonradan eklenir.
      unawaited(_lockScreenSync.start());

      // Premium katmanlar (bulut senkronu, sağlık taraması, widget)
      // abonelik durumu belli olunca devreye girer
      // -- bkz. _onEntitlementChanged().
      _onEntitlementChanged();
    } catch (e, stack) {
      debugPrint('[BOOTSTRAP HATASI] $e\n$stack');
      if (mounted) setState(() => _bootstrapError = e);
    }
  }

  /// Profil + ölçümler + ilaç planı için tam senkron döngüsü
  /// (bkz. cloud_sync_service.dart birleştirme kuralı). Bulut
  /// erişilemezse uygulama yerel veriyle çalışmaya devam eder.
  Future<void> _syncWithCloud() async {
    try {
      final result =
          await _cloudSync.syncAll(widget.uid).timeout(const Duration(
                seconds: 30,
              ));
      if (!result.changedLocalData) return;

      // Yeni cihazda geri yüklenen veri ekranlara yansımalı.
      final profile = await _profileRepo.getProfile();
      if (mounted && profile != null) setState(() => _profile = profile);
      await Future.wait([_refreshTrend(), _refreshMedications()]);
    } catch (e) {
      debugPrint('[BULUT SENKRON HATASI] $e');
    }
  }

  Future<void> _refreshTrend() async {
    final profile = _profile ?? _defaultProfile;
    final trend = await _trendService.buildTrend(
      days: 30,
      range: profile.targetRange,
      criticalLow: profile.criticalLow,
      criticalHigh: profile.criticalHigh,
    );
    if (mounted) setState(() => _trend = trend);
  }

  /// İlaç planı değiştiğinde: bugünün tablosunu ve bildirimleri tazeler.
  Future<void> _refreshMedications() async {
    final day = await _medicationService.buildDay(DateTime.now());
    final anticoagulant = await _medicationService.primaryAnticoagulant();
    final meds = await _medicationRepo.getAll();
    await _reminderService.syncAll(meds);
    if (mounted) {
      setState(() {
        _medicationDay = day;
        _anticoagulant = anticoagulant;
      });
    }
  }

  Future<void> _markDose(ScheduledDose dose, IntakeStatus status) async {
    final existing = dose.intake;
    if (existing != null && existing.status == status) {
      // Aynı işaret tekrar seçildiyse geri al (yanlış dokunuş düzeltmesi).
      await _intakeRepo.delete(existing.id);
    } else {
      await _intakeRepo.upsert(DoseIntake(
        id: existing?.id ?? _uuid.v4(),
        medicationId: dose.medication.id,
        scheduledAt: dose.scheduledAt,
        recordedAt: DateTime.now(),
        amountMg: dose.amountMg,
        status: status,
      ));
    }
    final day = await _medicationService.buildDay(DateTime.now());
    if (mounted) setState(() => _medicationDay = day);
  }

  Future<void> _saveProfile(PatientProfile updated) async {
    await _profileRepo.saveProfile(updated);
    if (_entitlements.has(PremiumFeature.cloudSync)) {
      try {
        await _cloudSync.pushProfile(widget.uid, updated);
      } catch (e) {
        // Yerel kayıt zaten yapıldı; bulut sonraki senkronda yakalar.
        debugPrint('[BULUT PROFİL GÖNDERİM HATASI] $e');
      }
    }
    if (mounted) setState(() => _profile = updated);
    await _refreshTrend();
  }

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

    // Kritik uyarı ücretsiz katmanda da çalışır — güvenlik paywall'ın
    // arkasına konmaz (bkz. entitlement_service.dart).
    final alert = await _alertService.processNewEntry(entry, profile);
    await _refreshTrend();

    if (alert != null && mounted) {
      final critical = alert.severity == AlertSeverity.critical;
      final loc = context.loc;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: critical
              ? Theme.of(context).colorScheme.error
              : Colors.amber.shade800,
          content: Text(
            '${alertTitle(loc, alert)}\n${alertMessage(loc, alert)}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _openScanner() async {
    if (!await ensurePremium(context, PremiumFeature.ocrScan)) return;
    if (!mounted) return;
    final value = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => const InrScanScreen()),
    );
    if (!mounted || value == null) return;
    _showAddDialog(prefillInr: value);
  }

  Future<void> _showAddDialog({double? prefillInr}) async {
    // Doz alanı ilaç planından önceden doldurulur; kullanıcı her seferinde
    // elle yazmak zorunda kalmaz (bkz. MedicationService.suggestedDose).
    final suggestion = await _medicationService.suggestedDose(DateTime.now());
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AddMeasurementDialog(
        prefillInr: prefillInr,
        suggestion: suggestion,
        onSave: _addMeasurement,
      ),
    );
  }

  /// Güncel durumu (son INR + bugünkü doz + 7 günlük uyum) acil durum
  /// kişisine gönderir. Özet servis tarafında saf fonksiyonla üretilir;
  /// burada yalnızca veri toplanır ve sonuç kullanıcıya bildirilir.
  Future<void> _shareWithCaregiver() async {
    if (!await ensurePremium(context, PremiumFeature.caregiverSharing)) return;
    final profile = _profile;
    if (profile == null) return;

    final latest = await _inrRepo.getLatest();
    final adherence = await _medicationService.adherence();
    if (!mounted) return;
    final result = await _caregiverShare.shareWithContact(
      context.loc,
      profile: profile,
      latestInr: latest,
      adherence: adherence,
      today: _medicationDay,
    );

    if (!mounted) return;
    final l10n = context.loc.l10n;
    final message = switch (result) {
      CaregiverShareResult.opened => l10n.shareDraftReady,
      CaregiverShareResult.noContact => l10n.shareNoContact,
      CaregiverShareResult.unavailable => l10n.shareUnavailable,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Hesap silme (App Store kuralı 5.1.1(v)). Sıra önemlidir: önce parolayla
  /// yeniden doğrulama, sonra bulut ve yerel veri, en son Firebase hesabı.
  /// Hesap silinince oturum kapanır ve AuthGate giriş ekranına döner. Bulut
  /// verisi silinemezse hesaba dokunulmaz — kullanıcı, verisi yarım silinmiş
  /// ama hâlâ var olan bir hesapla kalmaz.
  Future<String?> _deleteAccount(String password) async {
    final l10n = context.loc.l10n;
    try {
      await widget.authService.reauthenticate(password);
      await _cloudSync.deleteAllRemote(widget.uid);
      await _reminderScheduler.cancelAllReminders();
      await _lockScreenSync.clearAll();
      if (Platform.isAndroid) await _backgroundScheduler.cancel();
      await AppDatabase.clearUserData();
      await widget.authService.deleteCurrentUser();
      return null;
    } on FirebaseAuthException catch (e) {
      return switch (e.code) {
        'wrong-password' || 'invalid-credential' => l10n.authErrorWrongPassword,
        'network-request-failed' => l10n.deleteAccountNetworkError,
        _ => l10n.authErrorGeneric,
      };
    } catch (e) {
      debugPrint('[HESAP SİLME HATASI] $e');
      return l10n.deleteAccountNetworkError;
    }
  }

  Future<void> _checkComorbidityNow() async {
    if (!await ensurePremium(context, PremiumFeature.healthSync)) return;
    final latest = await _inrRepo.getLatest();
    final alert = await _comorbiditySync.checkNow(latest);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alert == null
              ? context.loc.l10n.edemaScanNoRisk
              : context.loc.l10n.edemaScanRisk(
                  context.loc.formats.weightKg(alert.weightDeltaKg),
                ),
        ),
      ),
    );
  }

  /// Sekme başlıkları çeviriden gelir; sıra bu listeyle aynı olmalıdır.
  List<String> _titles(Loc loc) => [
        loc.l10n.tabToday,
        loc.l10n.tabMedications,
        loc.l10n.tabHistory,
        loc.l10n.tabProfile,
      ];

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final profile = _profile;
    if (profile == null) {
      return _LoadingOrError(
        error: _bootstrapError,
        onRetry: () {
          setState(() => _bootstrapError = null);
          _bootstrap();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles(loc)[_tab]),
        actions: [
          if (_tab == 0)
            IconButton(
              tooltip: loc.l10n.edemaScanTooltip,
              icon: const Icon(Icons.monitor_heart_outlined),
              onPressed: _checkComorbidityNow,
            ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          TodayScreen(
            profile: profile,
            trend: _trend,
            medicationDay: _medicationDay,
            anticoagulant: _anticoagulant,
            onMark: _markDose,
            onAddMeasurement: () => _showAddDialog(),
            onOpenMedications: () => setState(() => _tab = 1),
          ),
          MedicationsScreen(
            repository: _medicationRepo,
            service: _medicationService,
            onChanged: _refreshMedications,
          ),
          HistoryScreen(
            profile: profile,
            inrRepo: _inrRepo,
            vitaminKRepo: _kRepo,
            trendService: _trendService,
            pdfService: _pdfService,
          ),
          ProfileScreen(
            initialProfile: profile,
            onSave: _saveProfile,
            onSignOut: widget.authService.signOut,
            onDeleteAccount: _deleteAccount,
            onShareWithCaregiver: _shareWithCaregiver,
          ),
        ],
      ),
      // FAB yalnızca "Bugün" sekmesinde: diğer sekmelerde formların ve
      // butonların üstüne binip dokunulamaz hâle getiriyordu.
      floatingActionButton: _tab != 0
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'scan',
                  tooltip: loc.l10n.scanInrTooltip,
                  onPressed: _openScanner,
                  child: const Icon(Icons.camera_alt_outlined),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'manual',
                  icon: const Icon(Icons.add),
                  label: Text(loc.l10n.todayAddMeasurement),
                  onPressed: () => _showAddDialog(),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: loc.l10n.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication),
            label: loc.l10n.tabMedications,
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart_outlined),
            selectedIcon: const Icon(Icons.show_chart),
            label: loc.l10n.tabHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: loc.l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}

class _LoadingOrError extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _LoadingOrError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.error_outline,
            title: context.loc.l10n.bootstrapFailed,
            message: '$error',
            actionLabel: context.loc.l10n.retry,
            onAction: onRetry,
          ),
        ),
      ),
    );
  }
}
