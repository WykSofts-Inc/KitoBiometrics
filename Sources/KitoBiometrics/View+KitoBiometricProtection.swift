//
//  View+KitoBiometricProtection.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

public extension View {
    func kitoProtectedAction(
        reason: String,
        authenticator: any KitoBiometricAuthenticating = KitoBiometricAuthenticator(),
        onFailure: ((KitoBiometricResult) -> Void)? = nil,
        perform action: @escaping () -> Void
    ) -> some View {
        modifier(KitoProtectedActionModifier(reason: reason, authenticator: authenticator, onFailure: onFailure, action: action))
    }

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
        modifier(KitoBiometricAppLockModifier(isEnabled: isEnabled, style: style, title: title, reason: reason, userName: userName, passcode: passcode, authenticator: authenticator, locksOnLaunch: locksOnLaunch, lockedBinding: nil))
    }

    func kitoBiometricAppLock(
        isEnabled: Bool = true,
        style: KitoBiometricLockStyle = .glass,
        title: String = "Locked",
        reason: String = "Unlock to continue",
        userName: String? = nil,
        passcode: String? = nil,
        authenticator: any KitoBiometricAuthenticating = KitoBiometricAuthenticator(),
        locksOnLaunch: Bool = true,
        isLocked: Binding<Bool>
    ) -> some View {
        modifier(KitoBiometricAppLockModifier(isEnabled: isEnabled, style: style, title: title, reason: reason, userName: userName, passcode: passcode, authenticator: authenticator, locksOnLaunch: locksOnLaunch, lockedBinding: isLocked))
    }
}
