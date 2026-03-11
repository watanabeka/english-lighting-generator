//
//  english_lighting_generatorApp.swift
//  english-lighting-generator
//
//  App entry point. Configures the SwiftData model container with CloudKit sync
//  and presents the root ContentView.
//
//  CloudKit setup (required for iCloud sync):
//    1. In Xcode → Signing & Capabilities, add "iCloud" capability and enable CloudKit.
//    2. Create/select a CloudKit container matching your bundle ID:
//       e.g. "iCloud.com.yourteam.english-lighting-generator"
//    3. Ensure the entitlement file includes the container ID under
//       com.apple.developer.icloud-container-identifiers.
//  Until those steps are done the app compiles and runs using a local-only
//  SwiftData store (no crash — CloudKit simply won't sync).
//

import SwiftData
import SwiftUI

@main
struct english_lighting_generatorApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([WordHistoryItem.self, UsageRecord.self])

        // Attempt 1: iCloud-backed store (CloudKit)
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(cloudKitDatabase: .automatic)]
        ) {
            print("✅ SwiftData: Using iCloud-backed store")
            return container
        }
        print("⚠️ SwiftData: iCloud store unavailable, falling back to local store")

        // Attempt 2: Local store (no iCloud)
        if let container = try? ModelContainer(for: schema) {
            print("✅ SwiftData: Using local store (no iCloud)")
            return container
        }
        print("⚠️ SwiftData: Local store failed, falling back to in-memory store")

        // Attempt 3: In-memory store (last resort — data will not persist)
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            print("⚠️ SwiftData: Using in-memory store (data will not persist)")
            return container
        } catch {
            // All three strategies failed — the model schema itself is likely broken.
            // Check: @Model classes, property types, relations, and target membership.
            fatalError("❌ SwiftData: All container strategies failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
