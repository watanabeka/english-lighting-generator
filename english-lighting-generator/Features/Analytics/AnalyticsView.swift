//
//  AnalyticsView.swift
//  english-lighting-generator
//
//  Displays usage statistics and word-history for the learning analytics tab.
//

import SwiftData
import SwiftUI

// MARK: - Analytics View

struct AnalyticsView: View {
    @Environment(LocalizationManager.self) private var L
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \UsageRecord.date, order: .reverse) private var usageRecords: [UsageRecord]
    @Query(sort: \WordHistoryItem.timestamp, order: .reverse) private var allItems: [WordHistoryItem]

    @State private var daysShown = 7

    var onSelectWord: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsCard.padding(.horizontal, 16)
                historySection.padding(.horizontal, 16)
            }
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Label(L["analytics.historyTitle"], systemImage: "chart.bar.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.btnBlue)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 14)

            statRow(
                title: L["analytics.today"],
                count: totalUsage(daysAgo: 0, count: 1),
                comparison: pctChange(current: totalUsage(daysAgo: 0, count: 1),
                                      previous: totalUsage(daysAgo: 1, count: 1)),
                compLabel: L["analytics.vsYesterday"],
                isLast: false
            )
            statRow(
                title: L["analytics.week7"],
                count: totalUsage(daysAgo: 0, count: 7),
                comparison: pctChange(current: totalUsage(daysAgo: 0, count: 7),
                                      previous: totalUsage(daysAgo: 7, count: 7)),
                compLabel: L["analytics.vsPrevious"],
                isLast: false
            )
            statRow(
                title: L["analytics.month28"],
                count: totalUsage(daysAgo: 0, count: 28),
                comparison: pctChange(current: totalUsage(daysAgo: 0, count: 28),
                                      previous: totalUsage(daysAgo: 28, count: 28)),
                compLabel: L["analytics.vsPrevious"],
                isLast: true
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white.opacity(0.82))
                .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.18), radius: 18, x: 0, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }

    private func statRow(title: String, count: Int, comparison: String, compLabel: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline).foregroundStyle(Color.cardSub)
                    Text(String(format: L["analytics.usageFormat"], count))
                        .font(.system(size: 22, weight: .bold)).foregroundStyle(Color.cardText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(comparison)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(comparisonColor(comparison))
                    Text(compLabel).font(.caption2).foregroundStyle(Color.cardSub)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            if !isLast { Divider().padding(.horizontal, 14) }
        }
    }

    private func comparisonColor(_ text: String) -> Color {
        if text.hasPrefix("+") && text != "+∞%" { return Color(red: 0.12, green: 0.62, blue: 0.38) }
        if text.hasPrefix("-") { return Color(red: 0.82, green: 0.22, blue: 0.22) }
        return Color.cardSub
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L["analytics.historyLabel"])
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color.cardSub)
                .padding(.horizontal, 4)

            if allItems.isEmpty {
                emptyState
            } else {
                ForEach(visibleItems) { item in
                    HistoryItemRow(item: item) { onSelectWord(item.englishWord) }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                            } label: {
                                Label(L["history.delete"], systemImage: "trash")
                            }
                        }
                }
                if hasMore {
                    HStack {
                        Spacer()
                        ProgressView().tint(Color.btnBlue).padding(.vertical, 12)
                        Spacer()
                    }
                    .onAppear { daysShown += 7 }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Color.white.opacity(0.65)).frame(width: 72, height: 72)
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 30)).foregroundStyle(Color.btnBlue.opacity(0.65))
            }
            VStack(spacing: 6) {
                Text(L["history.empty"]).font(.headline).fontWeight(.bold).foregroundStyle(Color.cardText)
                Text(L["history.emptyDetail"]).font(.subheadline).foregroundStyle(Color.cardSub)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            Button(action: { onSelectWord("") }) {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.sparkles").font(.system(size: 13))
                    Text(L["history.generateButton"]).font(.subheadline).fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [.btnBlue, .btnBlueDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: Color.btnBlue.opacity(0.35), radius: 10, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }

    // MARK: - Helpers

    private var cutoffDate: String { String.dateKey(daysAgo: daysShown - 1) }
    private var visibleItems: [WordHistoryItem] { allItems.filter { $0.date >= cutoffDate } }
    private var hasMore: Bool { allItems.count > visibleItems.count }

    private func totalUsage(daysAgo start: Int, count: Int) -> Int {
        let dates = Set((start..<(start + count)).map { String.dateKey(daysAgo: $0) })
        return usageRecords.filter { dates.contains($0.date) }
            .reduce(0) { $0 + $1.aiSentenceCount + $1.aiQuizCount }
    }

    private func pctChange(current: Int, previous: Int) -> String {
        guard previous > 0 else { return current > 0 ? "+∞%" : "–" }
        return String(format: "%+.0f%%", Double(current - previous) / Double(previous) * 100)
    }
}

// MARK: - History Item Row

private struct HistoryItemRow: View {
    let item: WordHistoryItem
    let onGenerate: () -> Void

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.englishWord)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.cardText)
                    .lineLimit(2)
                Text(Self.relativeFormatter.localizedString(for: item.timestamp, relativeTo: Date()))
                    .font(.caption)
                    .foregroundStyle(Color.cardSub)
            }
            Spacer()
            Button(action: onGenerate) {
                ZStack {
                    Circle().fill(Color.btnBlue.opacity(0.12)).frame(width: 34, height: 34)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.btnBlue)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14).padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.75))
                .shadow(color: Color(red: 0.30, green: 0.50, blue: 0.75).opacity(0.10), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        AppBackground()
        AnalyticsView(onSelectWord: { _ in })
            .environment(LocalizationManager.shared)
    }
    .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
