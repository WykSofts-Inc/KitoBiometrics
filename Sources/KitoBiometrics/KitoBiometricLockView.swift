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
/// appear, and reveals `content` once authentication succeeds. Wrap sensitive
/// content in it — `KitoBiometricLockView { CardDetailsView() }` — and pick a
/// look with `style:` (see `KitoBiometricLockStyle`).
public struct KitoBiometricLockView<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isUnlocked = false

    let reason: String
    let style: KitoBiometricLockStyle
    let authenticator: any KitoBiometricAuthenticating
    @ViewBuilder let content: () -> Content

    public init(
        reason: String = "Unlock to continue",
        style: KitoBiometricLockStyle = .minimal,
        authenticator: any KitoBiometricAuthenticating = KitoBiometricAuthenticator(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.reason = reason
        self.style = style
        self.authenticator = authenticator
        self.content = content
    }

    public var body: some View {
        ZStack {
            if isUnlocked {
                content().transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                // No biometrics enrolled/available fails open (the lock screen's own rule)
                // rather than permanently locking someone out with no fallback path.
                KitoBiometricLockScreen(style: style, reason: reason, authenticator: authenticator) {
                    withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.85)) { isUnlocked = true }
                }
                .transition(.opacity)
            }
        }
    }
}
