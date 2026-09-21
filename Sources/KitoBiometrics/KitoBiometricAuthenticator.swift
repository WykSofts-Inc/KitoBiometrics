//
//  KitoBiometricAuthenticator.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/3/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import LocalAuthentication

public enum KitoBiometricType: Sendable {
    case none, touchID, faceID, opticID
}

public enum KitoBiometricResult: Sendable {
    case success
    case failed(reason: String)
    case unavailable(reason: String)
    case userCancelled
}

/// Wraps `LAContext` behind a small async API with a result type that
/// distinguishes "the user cancelled" from "this device can't do this" from
/// "wrong face" — three UI treatments that shouldn't share one error string.
public struct KitoBiometricAuthenticator {
    public init() {}

    public var availableBiometricType: KitoBiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .touchID: return .touchID
        case .faceID: return .faceID
        case .opticID: return .opticID
        default: return .none
        }
    }

    /// `reason` is shown in the system prompt — keep it short and specific
    /// ("Unlock your account", not "Authenticate").
    public func authenticate(reason: String) async -> KitoBiometricResult {
        let context = LAContext()
        var policyError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &policyError) else {
            return .unavailable(reason: policyError?.localizedDescription ?? "Biometric authentication is unavailable")
        }

        do {
            let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
            return success ? .success : .failed(reason: "Authentication failed")
        } catch let error as LAError where error.code == .userCancel || error.code == .appCancel {
            return .userCancelled
        } catch {
            return .failed(reason: error.localizedDescription)
        }
    }
}
