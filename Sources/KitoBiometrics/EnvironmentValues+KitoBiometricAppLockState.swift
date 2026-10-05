//
//  EnvironmentValues+KitoBiometricAppLockState.swift
//  KitoBiometrics
//
//  Created by Wycliff on 10/5/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

public extension EnvironmentValues {
    var kitoBiometricAppLockState: KitoBiometricAppLockState {
        get { self[KitoBiometricAppLockStateKey.self] }
        set { self[KitoBiometricAppLockStateKey.self] = newValue }
    }
}
