//
//  KitoProtectedActionModifier.swift
//  KitoBiometrics
//
//  Created by Wycliff on 10/5/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI

struct KitoProtectedActionModifier: ViewModifier {
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
