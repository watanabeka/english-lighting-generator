//
//  AISessionHelper.swift
//  english-lighting-generator
//
//  Shared helpers for Apple Intelligence (FoundationModels) sessions.
//  Centralises translation and error-handling logic used by multiple ViewModels.
//

import Foundation
import FoundationModels

// MARK: - Translation

/// Translates an English text into the user's currently selected native language.
@available(macOS 26.0, *)
func translateToNative(_ text: String) async throws -> String {
    let nativeLang = LocalizationManager.shared.nativeLanguageName
    let session = LanguageModelSession(instructions: "Translate English to \(nativeLang).")
    let response = try await session.respond(to: text, generating: AITranslation.self)
    return response.content.translation
}

// MARK: - Error Handling

/// Converts a FoundationModels generation error into a localised message string.
/// Handles both `refusal` and generic errors uniformly.
@available(macOS 26.0, *)
func resolveGenerationError(_ error: Error) async -> String {
    if case LanguageModelSession.GenerationError.refusal(let refusal, _) = error {
        do {
            let content = try await Task.detached { try await refusal.explanation.content }.value
            return "[Refusal] \(content)"
        } catch {
            return "[Refusal] \(error.localizedDescription)"
        }
    }
    return error.localizedDescription
}
