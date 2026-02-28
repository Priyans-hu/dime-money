import WidgetKit
import SwiftUI

struct DimeWidgetEntry: TimelineEntry {
    let date: Date
    let currency: String
    let balance: String
    let todayExpense: String
    let todayIncome: String
    let weekExpense: String
    let monthExpense: String
}

struct DimeTimelineProvider: TimelineProvider {
    private let appGroupId = "group.com.priyanshu.dimeMoney"

    func placeholder(in context: Context) -> DimeWidgetEntry {
        DimeWidgetEntry(
            date: Date(),
            currency: "$",
            balance: "0.00",
            todayExpense: "0.00",
            todayIncome: "0.00",
            weekExpense: "0.00",
            monthExpense: "0.00"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DimeWidgetEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DimeWidgetEntry>) -> Void) {
        let entry = readEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readEntry() -> DimeWidgetEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        return DimeWidgetEntry(
            date: Date(),
            currency: defaults?.string(forKey: "currency") ?? "$",
            balance: defaults?.string(forKey: "balance") ?? "0.00",
            todayExpense: defaults?.string(forKey: "today_expense") ?? "0.00",
            todayIncome: defaults?.string(forKey: "today_income") ?? "0.00",
            weekExpense: defaults?.string(forKey: "week_expense") ?? "0.00",
            monthExpense: defaults?.string(forKey: "month_expense") ?? "0.00"
        )
    }
}
