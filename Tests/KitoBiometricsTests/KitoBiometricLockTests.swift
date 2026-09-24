//
//  KitoBiometricLockTests.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoBiometrics

final class KitoBiometricLockTests: XCTestCase {
    func testSimulatedAuthenticatorReturnsItsResult() async {
        let yes = KitoSimulatedBiometricAuthenticator(type: .touchID, result: .success, delay: .zero)
        let yesResult = await yes.authenticate(reason: "Test")
        XCTAssertTrue(yesResult.isSuccess)
        XCTAssertEqual(yes.availableBiometricType, .touchID)

        let no = KitoSimulatedBiometricAuthenticator(result: .userCancelled, delay: .zero)
        let noResult = await no.authenticate(reason: "Test")
        XCTAssertFalse(noResult.isSuccess)
    }

    func testFlakyAuthenticatorFailsThenSucceeds() async {
        let flaky = KitoFlakyBiometricAuthenticator(failures: 2, delay: .zero)
        let first = await flaky.authenticate(reason: "")
        let second = await flaky.authenticate(reason: "")
        let third = await flaky.authenticate(reason: "")
        XCTAssertFalse(first.isSuccess)
        XCTAssertFalse(second.isSuccess)
        XCTAssertTrue(third.isSuccess)
    }

    func testTypeNamesAndSymbols() {
        XCTAssertEqual(KitoBiometricType.faceID.displayName, "Face ID")
        XCTAssertEqual(KitoBiometricType.touchID.systemImage, "touchid")
        XCTAssertEqual(KitoBiometricType.none.displayName, "Passcode")
    }

    func testEveryLockStyleIsListed() {
        XCTAssertEqual(KitoBiometricLockStyle.allCases, [.minimal, .glass, .passcode, .vault])
    }

    func testFaceFrameDrawsFourBrackets() {
        let path = KitoFaceFrameShape().path(in: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(path.boundingRect.integral, CGRect(x: 0, y: 0, width: 100, height: 100))
    }
}
