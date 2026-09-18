import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
