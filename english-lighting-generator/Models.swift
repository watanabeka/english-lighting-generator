import Foundation
import SwiftData

@Model
final class WordHistoryItem {
    var date: String = ""
    var englishWord: String = ""
    var timestamp: Date = Date()

    init(date: String, englishWord: String) {
        self.date = date
        self.englishWord = englishWord
        self.timestamp = Date()
    }
}

@Model
final class UsageRecord {
    var date: String = ""
    var aiSentenceCount: Int = 0
    var aiQuizCount: Int = 0

    init(date: String, aiSentenceCount: Int = 0, aiQuizCount: Int = 0) {
        self.date = date
        self.aiSentenceCount = aiSentenceCount
        self.aiQuizCount = aiQuizCount
    }
}

extension String {
    static var todayDateKey: String { dateKey(daysAgo: 0) }

    static func dateKey(daysAgo: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }
}

func recordUsage(sentence: Bool = false, quiz: Bool = false, modelContext: ModelContext) {
    let today = String.todayDateKey
    let descriptor = FetchDescriptor<UsageRecord>(predicate: #Predicate { $0.date == today })
    if let record = try? modelContext.fetch(descriptor).first {
        if sentence { record.aiSentenceCount += 1 }
        if quiz     { record.aiQuizCount     += 1 }
    } else {
        modelContext.insert(UsageRecord(
            date: today,
            aiSentenceCount: sentence ? 1 : 0,
            aiQuizCount:     quiz     ? 1 : 0
        ))
    }
    try? modelContext.save()
}

func saveWordHistory(_ word: String, modelContext: ModelContext) {
    modelContext.insert(WordHistoryItem(date: String.todayDateKey, englishWord: word))
    try? modelContext.save()
}
