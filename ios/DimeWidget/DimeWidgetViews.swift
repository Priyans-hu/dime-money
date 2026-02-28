import SwiftUI
import WidgetKit

struct DimeWidgetEntryView: View {
    var entry: DimeWidgetEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    private var textPrimary: Color {
        colorScheme == .dark ? Color(red: 0.9, green: 0.88, blue: 0.9) : Color(red: 0.11, green: 0.11, blue: 0.12)
    }

    private var textSecondary: Color {
        colorScheme == .dark ? Color(red: 0.79, green: 0.77, blue: 0.82) : Color(red: 0.4, green: 0.4, blue: 0.4)
    }

    private var textMuted: Color {
        colorScheme == .dark ? Color(red: 0.58, green: 0.56, blue: 0.6) : Color(red: 0.53, green: 0.53, blue: 0.53)
    }

    private var bgColor: Color {
        colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.96, green: 0.96, blue: 0.96)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            default:
                mediumView
            }
        }
        .containerBackground(bgColor, for: .widget)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Balance")
                .font(.caption)
                .foregroundColor(textMuted)
            Text("\(entry.currency)\(entry.balance)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dime Money")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(textSecondary)
            Text("\(entry.currency)\(entry.balance)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("Today: ↗\(entry.currency)\(entry.todayIncome)  ↙\(entry.currency)\(entry.todayExpense)")
                .font(.caption)
                .foregroundColor(textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dime Money")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(textSecondary)
            Text("\(entry.currency)\(entry.balance)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(textPrimary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text("Today: ↗\(entry.currency)\(entry.todayIncome)  ↙\(entry.currency)\(entry.todayExpense)")
                .font(.caption)
                .foregroundColor(textMuted)

            Divider()
                .padding(.vertical, 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Week")
                        .font(.caption2)
                        .foregroundColor(textMuted)
                    Text("\(entry.currency)\(entry.weekExpense)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(textSecondary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Month")
                        .font(.caption2)
                        .foregroundColor(textMuted)
                    Text("\(entry.currency)\(entry.monthExpense)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(textSecondary)
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}
