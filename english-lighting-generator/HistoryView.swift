//
//  HistoryView.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI
import SwiftData

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
            VStack(alignment: .leading, spacing: 24) {

                // Screen title
                VStack(alignment: .leading, spacing: 6) {
                    Text(L["tab.history"])
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text(L["analytics.historyTitle"])
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.58))
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                // Stats cards
                statsSection
                    .padding(.horizontal, 16)

                // History list
                historySection
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Stats Section

    private var statsSection: some View {
        VStack(spacing: 0) {
            statRow(
                title: L["analytics.today"],
                count: totalUsage(daysAgo: 0, count: 1),
                comparison: pctChange(
                    current: totalUsage(daysAgo: 0, count: 1),
                    previous: totalUsage(daysAgo: 1, count: 1)
                ),
                compLabel: L["analytics.vsYesterday"],
                isLast: false
            )
            statRow(
                title: L["analytics.week7"],
                count: totalUsage(daysAgo: 0, count: 7),
                comparison: pctChange(
                    current: totalUsage(daysAgo: 0, count: 7),
                    previous: totalUsage(daysAgo: 7, count: 7)
                ),
                compLabel: L["analytics.vsPrevious"],
                isLast: false
            )
            statRow(
                title: L["analytics.month28"],
                count: totalUsage(daysAgo: 0, count: 28),
                comparison: pctChange(
                    current: totalUsage(daysAgo: 0, count: 28),
                    previous: totalUsage(daysAgo: 28, count: 28)
                ),
                compLabel: L["analytics.vsPrevious"],
                isLast: true
            )
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
    }

    private func statRow(title: String, count: Int, comparison: String, compLabel: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(Color.appCardSub)
                    Text(String(format: L["analytics.usageFormat"], count))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.appCardText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(comparison)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(comparisonColor(comparison))
                    Text(compLabel)
                        .font(.caption2)
                        .foregroundStyle(Color.appCardSub)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            if !isLast {
                Rectangle()
                    .fill(Color.appCardSub.opacity(0.12))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16)
            }
        }
    }

    private func comparisonColor(_ text: String) -> Color {
        if text.hasPrefix("+") && text != "+∞%" { return Color(red: 0.15, green: 0.65, blue: 0.40) }
        if text.hasPrefix("-") { return Color(red: 0.85, green: 0.25, blue: 0.25) }
        return Color.appCardSub
    }

    // MARK: History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L["analytics.historyLabel"])
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(Color.white.opacity(0.60))
                .padding(.horizontal, 4)

            if allItems.isEmpty {
                emptyState
            } else {
                ForEach(visibleItems) { item in
                    HistoryItemRow(item: item, onGenerate: { onSelectWord(item.englishWord) })
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(item)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                        }
                }
                if hasMore {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(Color.white.opacity(0.6))
                            .padding(.vertical, 12)
                            .onAppear { daysShown += 7 }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.10))
                    .frame(width: 80, height: 80)
                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            VStack(spacing: 8) {
                Text(L["history.empty"])
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(L["history.emptyDetail"])
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button(action: { onSelectWord("") }) {
                HStack(spacing: 6) {
                    Image(systemName: "wand.and.sparkles")
                        .font(.system(size: 14))
                    Text(L["history.generateButton"])
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.appBlue, Color.appBlueDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: Helpers

    private var cutoffDate: String { String.dateKey(daysAgo: daysShown - 1) }
    private var visibleItems: [WordHistoryItem] { allItems.filter { $0.date >= cutoffDate } }
    private var hasMore: Bool { allItems.count > visibleItems.count }

    private func totalUsage(daysAgo start: Int, count: Int) -> Int {
        let dates = Set((start..<(start + count)).map { String.dateKey(daysAgo: $0) })
        return usageRecords
            .filter { dates.contains($0.date) }
            .reduce(0) { $0 + $1.aiSentenceCount + $1.aiQuizCount }
    }

    private func pctChange(current: Int, previous: Int) -> String {
        guard previous > 0 else { return current > 0 ? "+∞%" : "–" }
        let pct = Double(current - previous) / Double(previous) * 100
        return String(format: "%+.0f%%", pct)
    }
}

// MARK: - History Item Row

private struct HistoryItemRow: View {
    let item: WordHistoryItem
    let onGenerate: () -> Void

    private static let relFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            // Word info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.englishWord)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(Self.relFormatter.localizedString(for: item.timestamp, relativeTo: Date()))
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.50))
            }

            Spacer()

            // Arrow button
            Button(action: onGenerate) {
                ZStack {
                    Circle()
                        .fill(Color.appBlue.opacity(0.22))
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.appBlue)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(Color.white.opacity(0.10))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
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
