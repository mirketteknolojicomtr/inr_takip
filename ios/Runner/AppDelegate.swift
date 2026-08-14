import Flutter
import HealthKit
import UIKit

/// Kilo verisi için OLAY BAZLI (polling değil) arka plan senkronizasyonu.
/// `HKObserverQuery` + `enableBackgroundDelivery` HealthKit'in kendi
/// mekanizmasıdır: yeni bir kilo örneği yazıldığında iOS uygulamayı arka
/// planda uyandırır, Dart tarafına `onNewWeightSample` metoduyla haber
/// verilir (services/health_background_observer.dart bu channel'ı dinler).
/// Gerekli: Runner.entitlements'ta `com.apple.developer.healthkit` ve
/// `com.apple.developer.healthkit.background-delivery`, Info.plist'te
/// `NSHealthShareUsageDescription`.
private let healthObserverChannelName = "inr_takip/health_observer"

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let healthStore = HKHealthStore()
  private var healthChannel: FlutterMethodChannel?

  // Klasik, garanti-çalışan Flutter iOS bootstrap sırası: plugin'ler
  // GeneratedPluginRegistrant ile senkron olarak, Dart tarafı (main())
  // çalışmaya başlamadan ÖNCE kaydedilir. Projenin Storyboard tabanlı
  // (Main.storyboard) FlutterViewController kurulumu, daha yeni
  // `FlutterImplicitEngineDelegate`/`didInitializeImplicitFlutterEngine`
  // callback'ini hiç tetiklemiyordu -- bu yüzden hiçbir plugin (sqflite
  // dahil) kayıt olamıyor, ilk platform channel çağrısı
  // `MissingPluginException` ile patlıyordu.
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      healthChannel = FlutterMethodChannel(
        name: healthObserverChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      setUpWeightObserver()
    }

    return result
  }

  private func setUpWeightObserver() {
    guard HKHealthStore.isHealthDataAvailable() else { return }
    let weightType = HKQuantityType(.bodyMass)

    healthStore.requestAuthorization(toShare: nil, read: [weightType]) { [weak self] success, error in
      guard success, let self = self else { return }

      let query = HKObserverQuery(sampleType: weightType, predicate: nil) {
        [weak self] _, completionHandler, _ in
        DispatchQueue.main.async {
          self?.healthChannel?.invokeMethod("onNewWeightSample", arguments: nil)
        }
        completionHandler()
      }
      self.healthStore.execute(query)

      self.healthStore.enableBackgroundDelivery(for: weightType, frequency: .immediate) { _, _ in
        // Sessizce yok say -- kullanıcı Sağlık iznini reddetmiş olabilir;
        // bu durumda ComorbiditySyncService zaten boş veri görüp
        // değerlendirme yapmayacak (bkz. EdemaRiskEvaluator).
      }
    }
  }
}
