//
//  KitoBiometricLockView.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/4/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Drop-in lock screen: shows a themed prompt, triggers Face ID/Touch ID on
/// appear, and calls `onUnlock` once authentication succeeds. Wrap sensitive
/// content in it — `KitoBiometricLockView { CardDetailsView() }`.
public struct KitoBiometricLockView<Content: View>: View {
    @Environment(\.kitoTheme) private var theme
    @State private var isUnlocked = false
    @State private var errorMessage: String?

    let reason: String
    @ViewBuilder let content: () -> Content
    private let authenticator = KitoBiometricAuthenticator()

    public init(reason: String = "Unlock to continue", @ViewBuilder content: @escaping () -> Content) {
        self.reason = reason
        self.content = content
    }

    public var body: some View {
        Group {
            if isUnlocked {
                content()
            } else {
                lockedView
            }
        }
        .task { await authenticate() }
    }

    private var lockedView: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: authenticator.availableBiometricType == .faceID ? "faceid" : "touchid")
                .font(.system(size: 48))
                .foregroundStyle(theme.colors.primary)
            Text("Locked")
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.onBackground)
            if let errorMessage {
                Text(errorMessage)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.danger)
            }
            Button("Try again") { Task { await authenticate() } }
                .font(theme.typography.button)
                .foregroundStyle(theme.colors.primary)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background)
    }

    private func authenticate() async {
        switch await authenticator.authenticate(reason: reason) {
        case .success:
            withAnimation { isUnlocked = true }
            errorMessage = nil
        case .failed(let reason):
            errorMessage = reason
        case .unavailable(let reason):
            // No biometrics enrolled/available — fail open rather than
            // permanently locking a user out with no fallback path.
            errorMessage = reason
            isUnlocked = true
        case .userCancelled:
            errorMessage = nil
        }
    }
}
