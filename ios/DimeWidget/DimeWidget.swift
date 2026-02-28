import WidgetKit
import SwiftUI

@main
struct DimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        DimeWidget()
    }
}

struct DimeWidget: Widget {
    let kind: String = "DimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DimeTimelineProvider()) { entry in
            DimeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dime Money")
        .description("Track your balance and spending at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
