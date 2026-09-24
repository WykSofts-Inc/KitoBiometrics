//
//  KitoBiometricAuthenticating.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Anything that can check it's really the owner. `KitoBiometricAuthenticator` is the real one;
/// `KitoSimulatedBiometricAuthenticator` answers on cue for previews, demos and tests (the
/// simulator usually has no enrolled face, so the real one reports `.unavailable` there).
public protocol KitoBiometricAuthenticating: Sendable {
    var availableBiometricType: KitoBiometricType { get }
    func authenticate(reason: String) async -> KitoBiometricResult
}

/// Answers every `authenticate` call with a fixed result after a short, realistic delay.
public struct KitoSimulatedBiometricAuthenticator: KitoBiometricAuthenticating {
    public var availableBiometricType: KitoBiometricType
    public var result: KitoBiometricResult
    public var delay: Duration

    public init(type: KitoBiometricType = .faceID, result: KitoBiometricResult = .success, delay: Duration = .milliseconds(1_100)) {
        self.availableBiometricType = type
        self.result = result
        self.delay = delay
    }

    public func authenticate(reason: String) async -> KitoBiometricResult {
        try? await Task.sleep(for: delay)
        return result
    }
}

/// Fails the first `failures` attempts, then succeeds — for showing retry and lockout paths.
public final class KitoFlakyBiometricAuthenticator: KitoBiometricAuthenticating, @unchecked Sendable {
    public let availableBiometricType: KitoBiometricType
    private let failures: Int
    private let delay: Duration
    private let lock = NSLock()
    private var attempts = 0

    public init(type: KitoBiometricType = .faceID, failures: Int = 1, delay: Duration = .milliseconds(1_000)) {
        self.availableBiometricType = type
        self.failures = failures
        self.delay = delay
    }

    public func authenticate(reason: String) async -> KitoBiometricResult {
        try? await Task.sleep(for: delay)
        let attempt: Int = lock.withLock {
            attempts += 1
            return attempts
        }
        return attempt <= failures ? .failed(reason: "Face not recognised") : .success
    }
}

public extension KitoBiometricType {
    /// "Face ID", "Touch ID", "Optic ID" or "Passcode".
    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "Passcode"
        }
    }

    /// The matching SF Symbol.
    var systemImage: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.fill"
        }
    }
}

public extension KitoBiometricResult {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
