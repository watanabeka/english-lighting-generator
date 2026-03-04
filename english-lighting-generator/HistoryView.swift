//
//  HistoryView.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI
import SwiftData

// MARK: - History View

struct HistoryView: View {
    @Environment(LocalizationManager.self) private var L
    @Environment(\.modelContext) private var modelContext

    // Sorted newest-first by date string (yyyy-MM-dd), then by generationCount desc
    @Query(sort: [
        SortDescriptor(\WordHistoryItem.date, order: .reverse),
        SortDescriptor(\WordHistoryItem.generationCount, order: .reverse)
    ])
    private var items: [WordHistoryItem]

    // Callback: user tapped "Generate" in History → pre-fill the AI Sentence tab
    var onSelectWord: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
            .navigationTitle(L["tab.history"])
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text(L["history.empty"])
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(L["history.emptyDetail"])
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            ForEach(groupedByDate, id: \.date) { group in
                Section(header: Text(formattedDate(group.date))) {
                    ForEach(group.items) { item in
                        HistoryRow(item: item, L: L, onGenerate: {
                            onSelectWord(item.englishWord)
                        })
                    }
                    .onDelete { offsets in
                        deleteItems(at: offsets, in: group.items)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Grouping

    private struct DateGroup {
        let date: String
        var items: [WordHistoryItem]
    }

    private var groupedByDate: [DateGroup] {
        var groups: [String: [WordHistoryItem]] = [:]
        for item in items {
            groups[item.date, default: []].append(item)
        }
        return groups
            .sorted { $0.key > $1.key }
            .map { DateGroup(date: $0.key, items: $0.value) }
    }

    // MARK: - Delete

    private func deleteItems(at offsets: IndexSet, in group: [WordHistoryItem]) {
        for index in offsets {
            modelContext.delete(group[index])
        }
    }

    // MARK: - Date Formatting

    private func formattedDate(_ key: String) -> String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: key) else { return key }

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    let item: WordHistoryItem
    let L: LocalizationManager
    let onGenerate: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.englishWord)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Label {
                    Text("\(item.generationCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "wand.and.sparkles")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: onGenerate) {
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
            .help(L["history.generateButton"])
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView(onSelectWord: { _ in })
        .environment(LocalizationManager.shared)
        .modelContainer(for: [WordHistoryItem.self, UsageRecord.self], inMemory: true)
}
