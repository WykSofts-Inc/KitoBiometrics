//
//  KitoBiometricsTests.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/5/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoBiometrics

final class KitoBiometricsTests: XCTestCase {
    func testAuthenticatorReportsAvailability() {
        // Simulator/CI hosts typically have no enrolled biometrics, so this
        // asserts the call doesn't crash and returns a defined type rather
        // than asserting a specific case (which is environment-dependent).
        let authenticator = KitoBiometricAuthenticator()
        let type = authenticator.availableBiometricType
        XCTAssertNotNil(type)
    }
}
