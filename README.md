# english-lighting-generator

AI-powered English learning app for iOS/macOS. Uses Apple Intelligence (FoundationModels) to generate English example sentences and word-ordering quizzes.

---

## Directory Structure

```
english-lighting-generator/
├── App/
│   ├── ContentView.swift               # Root view: tab bar + feature tab switching
│   └── english_lighting_generatorApp.swift  # @main entry point, SwiftData container setup
│
├── Features/
│   ├── Generator/
│   │   ├── GeneratorView.swift         # English sentence generation UI
│   │   └── GeneratorViewModel.swift    # Generation logic, AI session calls
│   ├── Quiz/
│   │   ├── QuizView.swift              # Word-order quiz UI (all sub-views)
│   │   └── QuizViewModel.swift         # Quiz generation, answer checking logic
│   ├── Analytics/
│   │   └── AnalyticsView.swift         # Usage stats + word history list
│   └── Settings/
│       └── SettingsView.swift          # Disclaimer, subscription, language, review
│
├── Models/
│   ├── AppTypes.swift                  # Enums (EnglishLevel, SentenceLength), AI output structs,
│   │                                   # AppConstants (App Store URLs, Google search URL template)
│   └── DataModels.swift                # SwiftData @Model classes (WordHistoryItem, UsageRecord),
│                                       # usage-tracking helpers (saveWordHistory, recordUsage, etc.)
│
├── Services/
│   ├── LocalizationManager.swift       # @Observable JSON-based localization; L["key"] subscript
│   └── StoreManager.swift              # StoreKit 2 subscription management (isPremium, purchase, restore)
│
├── Shared/
│   ├── AISessionHelper.swift           # translateToNative(), resolveGenerationError() — used by both ViewModels
│   ├── DesignSystem.swift              # Color extension (skyTop/Mid/Bottom, cardText, cardSub, btnBlue, btnBlueDark)
│   ├── Components/
│   │   ├── AppBackground.swift         # Sky-gradient ZStack background view
│   │   ├── BlueSegmentedPicker.swift   # Generic segmented control with blue gradient active state
│   │   ├── CustomTabBar.swift          # Bottom tab bar (4 tabs: Generator, Quiz, Analytics, Settings)
│   │   ├── DailyLimitLabel.swift       # "X generations remaining today" — auto-hidden for premium users
│   │   ├── ErrorBannerView.swift       # Red-tinted error message banner
│   │   ├── GlowLoadingBar.swift        # Animated sweep loading bar (shown during AI generation)
│   │   └── UnavailableView.swift       # Shown when Apple Intelligence or OS is unavailable
│   └── Dialogs/
│       ├── DisclaimerDialog.swift      # First-launch disclaimer modal
│       ├── ReviewPromptDialog.swift    # App Store review prompt (shown after 3rd quiz)
│       └── SubscriptionDialog.swift    # Premium subscription upsell modal
│
└── Localization/
    ├── ja.json      # 日本語
    ├── pt-BR.json   # Português (Brasil)
    ├── es-419.json  # Español (Latinoamérica)
    ├── id.json      # Bahasa Indonesia
    ├── vi.json      # Tiếng Việt
    ├── ar.json      # العربية
    └── fr.json      # Français
```

---

## Architecture

**Pattern:** MVVM with SwiftUI

- **Views** are pure UI — no business logic, no direct AI calls.
- **ViewModels** (`@Observable` classes) own state and call AI/data functions.
- **Models** define data structures, SwiftData models, enums, and app-wide constants.
- **Services** are singletons (`StoreManager.shared`, `LocalizationManager.shared`) accessed via computed properties in views/VMs to avoid init complications.
- **Shared helpers** eliminate duplication: `translateToNative()` and `resolveGenerationError()` in `AISessionHelper.swift` are used by both `GeneratorViewModel` and `QuizViewModel`.

---

## Key Design Decisions

### Localization
- All user-facing strings live in `Localization/*.json`.
- Access via `L["key"]` where `L` is a `LocalizationManager` from `@Environment`.
- **Never hardcode user-facing strings** in Swift files.
- To add a new string: add the key/value to all 7 JSON files, then use `L["your.key"]` in code.

### Daily Limit & Subscription
- `dailyFreeLimit` constant (defined in `DataModels.swift`) controls the free tier cap (currently 10).
- `DailyLimitLabel` component reads `@Query` usage records reactively — updates instantly after each generation.
- `StoreManager.isPremium` gates all limit checks. Premium users skip the limit entirely.
- When the limit is reached, `SubscriptionDialog` is presented.

### Apple Intelligence Availability
- All AI-dependent code is wrapped in `@available(macOS 26.0, *)`.
- `AvailabilityGateView` (in `ContentView.swift`) checks `SystemLanguageModel.default.availability` at runtime and shows `UnavailableView` if AI is not available on the device.

### URL Opening
- Use `@Environment(\.openURL)` everywhere instead of `UIApplication.shared.open()` or `NSWorkspace.shared.open()`. This is cross-platform and testable.
- All URL strings are defined in `AppConstants` (`Models/AppTypes.swift`). Do not hardcode URLs inline.

### SwiftData
- Two models: `WordHistoryItem` (search history) and `UsageRecord` (daily generation count by date).
- CloudKit sync is attempted first; falls back to local store, then in-memory. See `english_lighting_generatorApp.swift` for details.
- `@Query` in views (not ViewModels) ensures reactive UI updates when data changes.

### Naming Conventions
- **camelCase** everywhere: variables, functions, parameters, file names (except JSON locale files which use kebab-case locale IDs).
- No snake_case.
- ViewModels named after their feature: `GeneratorViewModel`, `QuizViewModel`.
- Shared components named by what they render: `ErrorBannerView`, `DailyLimitLabel`, etc.

---

## Adding a New Feature

1. Create `Features/YourFeature/YourFeatureView.swift` and `YourFeatureViewModel.swift`.
2. Add a tab entry to `CustomTabBar` items in `Shared/Components/CustomTabBar.swift`.
3. Add the tab case to the `switch selectedTab` in `App/ContentView.swift`.
4. Add localization keys to all 7 JSON files under `Localization/`.
5. If the feature needs AI, use `AISessionHelper.swift` helpers and wrap in `@available(macOS 26.0, *)`.
6. If the feature records usage, call `recordUsage(sentence:modelContext:)` or `recordUsage(quiz:modelContext:)` from `DataModels.swift`.

---

## CloudKit Setup (for iCloud sync)

1. In Xcode → **Signing & Capabilities**, add **iCloud** and enable **CloudKit**.
2. Create/select a container: `iCloud.com.yourteam.english-lighting-generator`.
3. Ensure the entitlement file lists the container ID under `com.apple.developer.icloud-container-identifiers`.

Until this is configured, the app runs with a local SwiftData store (no crash).

---

## App Store / Review URL

Update `AppConstants.appStoreID` in `Models/AppTypes.swift` with the real App Store ID before release. The review URL and macOS review URL are derived from it automatically.
