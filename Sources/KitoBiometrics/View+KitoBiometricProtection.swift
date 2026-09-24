//
//  View+KitoBiometricProtection.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

private struct KitoProtectedActionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let reason: String
    let authenticator: any KitoBiometricAuthenticating
    let onFailure: ((KitoBiometricResult) -> Void)?
    let action: () -> Void

    @State private var state: KitoBiometricGlyphState = .idle
    @State private var shake: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if state != .idle {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.ultraThinMaterial)
                        KitoBiometricGlyph(type: displayType, state: state, size: 30)
                    }
                    .transition(.opacity)
                    .accessibilityHidden(true)
                }
            }
            .modifier(KitoShakeEffect(travel: shake))
            .contentShape(Rectangle())
            .onTapGesture { run() }
            .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: state)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Requires \(displayType.displayName)")
            .accessibilityAction { run() }
    }

    private var displayType: KitoBiometricType {
        let type = authenticator.availableBiometricType
        return type == .none ? .faceID : type
    }

    private func run() {
        guard state == .idle else { return }
        state = .scanning
        Task {
            let result = await authenticator.authenticate(reason: reason)
            switch result {
            case .success:
                state = .success
                try? await Task.sleep(for: .milliseconds(450))
                state = .idle
                action()
            case .userCancelled:
                state = .idle
                onFailure?(result)
            case .failed, .unavailable:
                state = .failure
                if !reduceMotion { withAnimation(.linear(duration: 0.45)) { shake += 1 } }
                try? await Task.sleep(for: .milliseconds(700))
                state = .idle
                onFailure?(result)
            }
        }
    }
}

private struct KitoBiometricAppLockModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isEnabled: Bool
    let style: KitoBiometricLockStyle
    let title: String
    let reason: String
    let userName: String?
    let passcode: String?
    let authenticator: any KitoBiometricAuthenticating
    let locksOnLaunch: Bool

    @State private var isLocked = false
    @State private var didLaunch = false

    func body(content: Content) -> some View {
        content
            .blur(radius: isEnabled && (scenePhase != .active || isLocked) ? 18 : 0)
            .overlay {
                if isLocked {
                    KitoBiometricLockScreen(style: style, title: title, reason: reason, userName: userName, passcode: passcode, authenticator: authenticator) {
                        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.85)) { isLocked = false }
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                guard !didLaunch else { return }
                didLaunch = true
                isLocked = isEnabled && locksOnLaunch
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background && isEnabled { isLocked = true }
            }
            .onChange(of: isEnabled) { _, enabled in
                if !enabled { isLocked = false }
            }
    }
}

public extension View {
    /// Runs `action` on tap only after Face ID / Touch ID confirms it's the owner — for "show
    /// balance", "send money", "reveal card number". While checking, the view frosts over with
    /// an animated glyph; a failure shakes it. Attach to a plain label, not a `Button`.
    func kitoProtectedAction(
        reason: String,
        authenticator: any KitoBiometricAuthenticating = KitoBiometricAuthenticator(),
        onFailure: ((KitoBiometricResult) -> Void)? = nil,
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(KitoProtectedActionModifier(reason: reason, authenticator: authenticator, onFailure: onFailure, action: action))
    }

    /// Locks the whole view behind a biometric lock screen when the app goes to the background
    /// (and on launch, unless `locksOnLaunch` is false), and blurs it in the app switcher.
    func kitoBiometricAppLock(
        isEnabled: Bool = true,
        style: KitoBiometricLockStyle = .glass,
        title: String = "Locked",
        reason: String = "Unlock to continue",
        userName: String? = nil,
        passcode: String? = nil,
        authenticator: any KitoBiometricAuthenticating = KitoBiometricAuthenticator(),
        locksOnLaunch: Bool = true
    ) -> some View {
        modifier(KitoBiometricAppLockModifier(isEnabled: isEnabled, style: style, title: title, reason: reason, userName: userName, passcode: passcode, authenticator: authenticator, locksOnLaunch: locksOnLaunch))
    }
}
