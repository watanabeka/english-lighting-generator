//
//  english_lighting_generatorApp.swift
//  english-lighting-generator
//
//  Created by 渡辺 海星 on 2026/02/24.
//

import SwiftUI
import SwiftData

@main
struct english_lighting_generatorApp: App {

    // MARK: - SwiftData + iCloud (CloudKit) container
    //
    // `cloudKitDatabase: .automatic` enables iCloud sync via CloudKit.
    // This requires the following Xcode project configuration (TODO for maintainer):
    //
    //   1. Sign in to an Apple Developer account in Xcode → Signing & Capabilities.
    //   2. Add capability: "iCloud" → check "CloudKit".
    //   3. Create (or select) a CloudKit container named
    //      "iCloud.com.yourteam.english-lighting-generator" (match your bundle ID).
    //   4. Ensure the app's entitlement file includes the container ID under
    //      com.apple.developer.icloud-container-identifiers.
    //
    // Note: "Background Modes → Remote notifications" is NOT required.
    // Sync happens when the app is in the foreground, which is sufficient.
    //
    // Until those steps are done the app compiles and runs using a local-only
    // SwiftData store (no crash — CloudKit simply won't sync).

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WordHistoryItem.self,
            UsageRecord.self,
        ])
        
        // Attempt 1: iCloud-backed store
        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(cloudKitDatabase: .automatic)]
            )
            print("✅ SwiftData: Using iCloud-backed store")
            return container
        } catch {
            print("⚠️ SwiftData: iCloud store failed - \(error.localizedDescription)")
        }
        
        // Attempt 2: Local store with default configuration
        do {
            let container = try ModelContainer(for: schema)
            print("✅ SwiftData: Using local store (no iCloud)")
            return container
        } catch {
            print("❌ SwiftData: Default local store failed - \(error.localizedDescription)")
        }
        
        // Attempt 3: In-memory store (last resort)
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            print("⚠️ SwiftData: Using in-memory store (data will not persist)")
            return container
        } catch {
            // This should never happen, but if it does, crash with a clear message
            fatalError("❌ FATAL: Could not create any SwiftData container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
