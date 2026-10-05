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

public struct KitoBiometricAuthenticator: KitoBiometricAuthenticating {
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

    public func authenticate(reason: String) async -> KitoBiometricResult {
        let context = LAContext()
        var policyError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &policyError) else {
            if policyError?.domain == LAErrorDomain && policyError?.code == LAError.Code.biometryLockout.rawValue {
                return await evaluate(.deviceOwnerAuthentication, in: context, reason: reason)
            }
            return .unavailable(reason: policyError?.localizedDescription ?? "Biometric authentication is unavailable")
        }

        return await evaluate(.deviceOwnerAuthenticationWithBiometrics, in: context, reason: reason)
    }

    private func evaluate(_ policy: LAPolicy, in context: LAContext, reason: String) async -> KitoBiometricResult {
        do {
            let success = try await context.evaluatePolicy(policy, localizedReason: reason)
            return success ? .success : .failed(reason: "Authentication failed")
        } catch let error as LAError where error.code == .userCancel || error.code == .appCancel {
            return .userCancelled
        } catch {
            return .failed(reason: error.localizedDescription)
        }
    }
}
