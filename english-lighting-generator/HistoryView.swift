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
        VStack(spacing: 0) {
            statsSection
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

            Divider()

            List {
                Section {
                    if allItems.isEmpty {
                        emptyState
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(visibleItems) { item in
                            HistoryItemRow(item: item, onGenerate: { onSelectWord(item.englishWord) })
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        modelContext.delete(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        if hasMore {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onAppear { daysShown += 7 }
                        }
                    }
                } header: {
                    Text(L["analytics.historyLabel"])
                        .font(.footnote).fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L["analytics.historyTitle"])
                .font(.footnote).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            VStack(spacing: 10) {
                StatRow(
                    title: L["analytics.today"],
                    count: totalUsage(daysAgo: 0, count: 1),
                    comparison: pctChange(
                        current: totalUsage(daysAgo: 0, count: 1),
                        previous: totalUsage(daysAgo: 1, count: 1)
                    ),
                    compLabel: L["analytics.vsYesterday"],
                    usageFormat: L["analytics.usageFormat"]
                )
                Divider()
                StatRow(
                    title: L["analytics.week7"],
                    count: totalUsage(daysAgo: 0, count: 7),
                    comparison: pctChange(
                        current: totalUsage(daysAgo: 0, count: 7),
                        previous: totalUsage(daysAgo: 7, count: 7)
                    ),
                    compLabel: L["analytics.vsPrevious"],
                    usageFormat: L["analytics.usageFormat"]
                )
                Divider()
                StatRow(
                    title: L["analytics.month28"],
                    count: totalUsage(daysAgo: 0, count: 28),
                    comparison: pctChange(
                        current: totalUsage(daysAgo: 0, count: 28),
                        previous: totalUsage(daysAgo: 28, count: 28)
                    ),
                    compLabel: L["analytics.vsPrevious"],
                    usageFormat: L["analytics.usageFormat"]
                )
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text(L["history.empty"])
                .font(.headline).foregroundStyle(.secondary)
            Text(L["history.emptyDetail"])
                .font(.subheadline).foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button(action: { onSelectWord("") }) {
                Label(L["history.generateButton"], systemImage: "wand.and.sparkles")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

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

// MARK: - Stat Row

private struct StatRow: View {
    let title: String
    let count: Int
    let comparison: String
    let compLabel: String
    let usageFormat: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: usageFormat, count))
                    .font(.body).fontWeight(.semibold)
                Text("\(compLabel) \(comparison)")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.englishWord)
                    .font(.body).fontWeight(.medium)
                    .lineLimit(2)
                Text(Self.relFormatter.localizedString(for: item.timestamp, relativeTo: Date()))
                    .font(.caption).foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: onGenerate) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.title3).foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    AnalyticsView(onSelectWord: { _ in })
        .environment(LocalizationManager.shared)
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
