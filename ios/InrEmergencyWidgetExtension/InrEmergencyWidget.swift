import WidgetKit
import SwiftUI

/// `HomeWidgetLockScreenGateway` (Dart) ile birebir aynı olmalı —
/// `HomeWidget.setAppGroupId()` çağrısındaki değer.
private let appGroupId = "group.com.example.inrTakip"

struct InrEmergencyEntry: TimelineEntry {
    let date: Date
    let headline: String
    let patientName: String
    let medication: String
}

struct InrEmergencyProvider: TimelineProvider {
    func placeholder(in context: Context) -> InrEmergencyEntry {
        InrEmergencyEntry(
            date: Date(),
            headline: "SON INR: 2.5 (STABİL)",
            patientName: "Hasta Adı",
            medication: "Warfarin"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (InrEmergencyEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<InrEmergencyEntry>) -> Void) {
        // policy: .never -> widget kendi başına periyodik yenileme yapmaz
        // (batarya dostu). Flutter tarafı (LockScreenSyncService) her yeni
        // INR kaydında `home_widget` paketi üzerinden
        // WidgetCenter.shared.reloadTimelines(ofKind:) çağırıp olay bazlı
        // yeniler.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }

    private func currentEntry() -> InrEmergencyEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return InrEmergencyEntry(
            date: Date(),
            headline: defaults?.string(forKey: "headline") ?? "INR kaydı yok",
            patientName: defaults?.string(forKey: "patientName") ?? "",
            medication: defaults?.string(forKey: "medication") ?? ""
        )
    }
}

struct InrEmergencyWidgetView: View {
    var entry: InrEmergencyEntry

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "cross.case.fill")
                .foregroundColor(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.headline)
                    .font(.headline)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if !entry.patientName.isEmpty {
                    Text(entry.patientName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct InrEmergencyWidget: Widget {
    // `HomeWidgetLockScreenGateway._iosWidgetKind` (Dart) ile birebir
    // eşleşmeli — `HomeWidget.updateWidget(iOSName:)` bu kind'i kullanarak
    // `WidgetCenter.shared.reloadTimelines(ofKind:)` çağırır.
    let kind: String = "InrEmergencyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: InrEmergencyProvider()) { entry in
            InrEmergencyWidgetView(entry: entry)
        }
        .configurationDisplayName("INR Acil Durum")
        .description("Son INR değerinizi ve acil durum bilgisini kilit ekranında gösterir.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .systemSmall])
    }
}
