//
//  KitoBiometricAppLockModifier.swift
//  KitoBiometrics
//
//  Created by Wycliff on 10/5/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

struct KitoBiometricAppLockModifier: ViewModifier {
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
    let lockedBinding: Binding<Bool>?

    @State private var storedLock = false
    @State private var didLaunch = false

    private var isLocked: Binding<Bool> { lockedBinding ?? $storedLock }

    private var lockState: KitoBiometricAppLockState {
        let launchLockPending = !didLaunch && isEnabled && locksOnLaunch
        return isLocked.wrappedValue || launchLockPending ? .locked : .unlocked
    }

    func body(content: Content) -> some View {
        content
            .environment(\.kitoBiometricAppLockState, lockState)
            .blur(radius: isEnabled && (scenePhase != .active || isLocked.wrappedValue) ? 18 : 0)
            .overlay {
                if isLocked.wrappedValue {
                    KitoBiometricLockScreen(style: style, title: title, reason: reason, userName: userName, passcode: passcode, authenticator: authenticator) {
                        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.85)) { isLocked.wrappedValue = false }
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                guard !didLaunch else { return }
                didLaunch = true
                isLocked.wrappedValue = isEnabled && locksOnLaunch
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background && isEnabled { isLocked.wrappedValue = true }
            }
            .onChange(of: isEnabled) { _, enabled in
                if !enabled { isLocked.wrappedValue = false }
            }
            .onChange(of: isLocked.wrappedValue) { _, locked in
                if locked && !isEnabled { isLocked.wrappedValue = false }
            }
    }
}
