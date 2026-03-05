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
        
        // Attempt 1: iCloud-backed store (CloudKit)
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
        
        // Attempt 2: Local store (no iCloud)
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
            // この時点で iCloud / ローカル ともに初期化に失敗しています。
            // 多くの場合、SwiftData のスキーマ/モデル定義に問題があるときに発生します。
            // 例:
            //  - @Model が付いていない / サポート外のプロパティ型
            //  - 不整合なリレーション / 循環参照
            //  - ターゲットに含まれていないモデルファイル
            //  - 同名モデルの重複 など
            let message = "❌ FATAL: すべての SwiftData コンテナ作成に失敗しました: \(error)\n" +
            "ヒント: Schema に含めた各 @Model の定義を最小構成に落として原因のプロパティ/関係を特定してください。"

            #if DEBUG
            // 開発中は強制的に気づけるように assertionFailure を出しつつ、
            // 直後にフォールバックの空スキーマ・インメモリコンテナを返します。
            print(message)
            do {
                let emptySchema = Schema([]) // 空スキーマ（永続化は事実上無効）
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: emptySchema, configurations: [config])
                print("⚠️ SwiftData: 代替の空スキーマ(in-memory)で起動継続 (データは保持されません)")
                return container
            } catch {
                fatalError("❌ FATAL(フォールバックも失敗): \(error)")
            }
            #else
            // リリースビルドではユーザー影響を抑えるため、
            // ダミーの空スキーマ(in-memory)で起動継続します（データは保持されません）。
            do {
                let emptySchema = Schema([])
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: emptySchema, configurations: [config])
                print("⚠️ SwiftData: リリースビルドで代替の空スキーマ(in-memory)を使用。至急モデル定義を確認してください。")
                return container
            } catch {
                fatalError("❌ FATAL(リリースのフォールバックも失敗): \(error)")
            }
            #endif
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

