//
//  DailyLimitLabel.swift
//  english-lighting-generator
//
//  Displays the remaining free generations for today.
//  Hidden automatically when the user has a premium subscription.
//

import SwiftData
import SwiftUI

struct DailyLimitLabel: View {
    @Environment(LocalizationManager.self) private var L
    @Query private var allUsageRecords: [UsageRecord]
    private var store: StoreManager { StoreManager.shared }

    private var remainingGenerations: Int {
        let today = String.todayDateKey
        let used = allUsageRecords
            .filter { $0.date == today }
            .reduce(0) { $0 + $1.aiSentenceCount + $1.aiQuizCount }
        return max(0, dailyFreeLimit - used)
    }

    var body: some View {
        if !store.isPremium {
            Text(String(format: L["dailyLimit.remaining"], remainingGenerations))
                .font(.system(size: 12))
                .foregroundStyle(Color.cardSub)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
