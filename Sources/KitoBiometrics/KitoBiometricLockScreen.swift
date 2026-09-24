//
//  KitoBiometricLockScreen.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How a lock screen looks.
public enum KitoBiometricLockStyle: String, CaseIterable, Sendable {
    /// Clean and quiet: the glyph, a title and one button.
    case minimal
    /// A frosted card with the person's initials over a drifting colour field.
    case glass
    /// The glyph above a six-digit passcode keypad, for when biometrics won't do.
    case passcode
    /// Dark, with a rotating dial of ticks around the glyph — for money and secrets.
    case vault
}

/// A full-screen lock that checks Face ID / Touch ID on appear and calls `onUnlock` once it's
/// really the owner. Failures shake and explain; after three the passcode style offers the
/// keypad. With no biometrics on the device it falls back to the passcode when you supply one,
/// otherwise it unlocks (never strand someone behind a lock they can't open).
public struct KitoBiometricLockScreen: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let style: KitoBiometricLockStyle
    let title: String
    let message: String?
    let reason: String
    let userName: String?
    let passcode: String?
    let authenticator: any KitoBiometricAuthenticating
    let autoPrompt: Bool
    let onUnlock: () -> Void

    @State private var glyph: KitoBiometricGlyphState = .idle
    @State private var status: String?
    @State private var failures = 0
    @State private var entered = ""
    @State private var dotsShake: CGFloat = 0
    @State private var showsKeypad = false
    @State private var drift = false
    @State private var dialTurn = 0.0

    public init(
        style: KitoBiometricLockStyle = .minimal,
        title: String = "Locked",
        message: String? = nil,
        reason: String = "Unlock to continue",
        userName: String? = nil,
        passcode: String? = nil,
        authenticator: any KitoBiometricAuthenticating = KitoBiometricAuthenticator(),
        autoPrompt: Bool = true,
        onUnlock: @escaping () -> Void
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.reason = reason
        self.userName = userName
        self.passcode = passcode
        self.authenticator = authenticator
        self.autoPrompt = autoPrompt
        self.onUnlock = onUnlock
    }

    private var type: KitoBiometricType {
        let available = authenticator.availableBiometricType
        return available == .none ? .faceID : available
    }

    public var body: some View {
        Group {
            switch style {
            case .minimal: minimal
            case .glass: glass
            case .passcode: passcodeLayout
            case .vault: vault
            }
        }
        .task { if autoPrompt && style != .passcode { await authenticate() } }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: glyph)
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: showsKeypad)
    }

    // MARK: Authentication

    private func authenticate() async {
        guard glyph != .scanning else { return }
        status = nil
        glyph = .scanning
        switch await authenticator.authenticate(reason: reason) {
        case .success:
            succeed()
        case .failed:
            failures += 1
            glyph = .failure
            status = failures >= 3 && passcode != nil ? "Too many attempts. Use your passcode." : "Not recognised. Try again."
            if failures >= 3 && passcode != nil { showsKeypad = true }
            try? await Task.sleep(for: .milliseconds(900))
            if glyph == .failure { glyph = .idle }
        case .unavailable(let reason):
            glyph = .idle
            if passcode != nil {
                status = "\(type.displayName) isn't set up. Use your passcode."
                showsKeypad = true
            } else {
                status = reason
                onUnlock()
            }
        case .userCancelled:
            glyph = .idle
        }
    }

    private func succeed() {
        glyph = .success
        status = nil
        Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 150 : 550))
            onUnlock()
        }
    }

    private func press(_ digit: String) {
        guard entered.count < 6, glyph != .success else { return }
        entered.append(digit)
        guard entered.count == 6 else { return }
        if entered == passcode {
            succeed()
        } else {
            status = "Wrong passcode"
            if !reduceMotion { withAnimation(.linear(duration: 0.45)) { dotsShake += 1 } }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                entered = ""
            }
        }
    }

    private var unlockTitle: String { "Unlock with \(type.displayName)" }

    private var greeting: String {
        guard let userName, let first = userName.split(separator: " ").first else { return title }
        return "Welcome back, \(first)"
    }

    private var initials: String {
        guard let userName else { return "" }
        return userName.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined()
    }

    // MARK: Minimal

    private var minimal: some View {
        VStack(spacing: theme.spacing.lg) {
            Spacer()
            Image(systemName: glyph == .success ? "lock.open.fill" : "lock.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(theme.colors.onBackground.opacity(0.5))
                .contentTransition(.symbolEffect(.replace))
            KitoBiometricGlyph(type: type, state: glyph, size: 84)
                .onTapGesture { Task { await authenticate() } }
            VStack(spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.titleLarge.weight(.bold))
                    .foregroundStyle(theme.colors.onBackground)
                Text(status ?? message ?? reason)
                    .font(theme.typography.body)
                    .foregroundStyle(status == nil ? theme.colors.onBackground.opacity(0.6) : theme.colors.danger)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
            }
            Spacer()
            Button { Task { await authenticate() } } label: {
                Label(unlockTitle, systemImage: type.systemImage).frame(maxWidth: .infinity)
            }
            .buttonStyle(KitoBiometricCapsuleStyle(fill: theme.colors.onBackground, label: theme.colors.background))
            .disabled(glyph == .scanning)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
    }

    // MARK: Glass

    private var glass: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.10, green: 0.07, blue: 0.25), Color(red: 0.02, green: 0.10, blue: 0.20)], startPoint: .top, endPoint: .bottom)
            Circle().fill(Color(red: 0.55, green: 0.30, blue: 1.0)).frame(width: 320).blur(radius: 90)
                .offset(x: drift ? -90 : 80, y: drift ? -220 : -140)
            Circle().fill(Color(red: 0.0, green: 0.75, blue: 0.85)).frame(width: 280).blur(radius: 90)
                .offset(x: drift ? 110 : -60, y: drift ? 200 : 120)
            Circle().fill(Color(red: 1.0, green: 0.40, blue: 0.55)).frame(width: 200).blur(radius: 80)
                .offset(x: drift ? 40 : 120, y: drift ? 30 : -20)

            VStack(spacing: theme.spacing.lg) {
                if !initials.isEmpty {
                    Text(initials)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .background(Circle().fill(LinearGradient(colors: [.white.opacity(0.35), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom)))
                        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
                        .accessibilityHidden(true)
                }
                VStack(spacing: 4) {
                    Text(greeting).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                    Text(status ?? message ?? reason)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(status == nil ? 0.7 : 0.95))
                        .multilineTextAlignment(.center)
                }
                KitoBiometricGlyph(type: type, state: glyph, size: 64, tint: .white)
                    .padding(.vertical, theme.spacing.sm)
                    .onTapGesture { Task { await authenticate() } }
                Button { Task { await authenticate() } } label: {
                    Text(glyph == .scanning ? "Looking for you…" : unlockTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(KitoBiometricCapsuleStyle(fill: .white, label: .black))
                .disabled(glyph == .scanning)
            }
            .padding(28)
            .kitoGlassCard(cornerRadius: 32)
            .padding(.horizontal, 28)
        }
        .ignoresSafeArea()
        .environment(\.colorScheme, .dark)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { drift = true }
        }
    }

    // MARK: Passcode

    private var passcodeLayout: some View {
        VStack(spacing: theme.spacing.lg) {
            Spacer(minLength: theme.spacing.md)
            KitoBiometricGlyph(type: type, state: glyph, size: 52)
            VStack(spacing: 4) {
                Text(passcode == nil ? title : "Enter passcode")
                    .font(theme.typography.titleMedium)
                    .foregroundStyle(theme.colors.onBackground)
                Text(status ?? "Or use \(type.displayName)")
                    .font(theme.typography.caption)
                    .foregroundStyle(status == nil ? theme.colors.onBackground.opacity(0.55) : theme.colors.danger)
            }
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(index < entered.count ? theme.colors.onBackground : .clear)
                        .overlay(Circle().stroke(theme.colors.onBackground.opacity(0.6), lineWidth: 1.5))
                        .frame(width: 13, height: 13)
                        .scaleEffect(index == entered.count - 1 ? 1.15 : 1)
                }
            }
            .modifier(KitoShakeEffect(travel: dotsShake))
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.6), value: entered)
            .accessibilityElement()
            .accessibilityLabel("\(entered.count) of 6 digits entered")
            Spacer(minLength: theme.spacing.md)
            keypad
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
    }

    private var keypad: some View {
        let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
        return VStack(spacing: 14) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 22) { ForEach(row, id: \.self) { key($0) } }
            }
            HStack(spacing: 22) {
                Button { Task { await authenticate() } } label: {
                    Image(systemName: type.systemImage).font(.system(size: 26)).frame(width: 74, height: 74)
                }
                .accessibilityLabel(unlockTitle)
                key("0")
                Button { if !entered.isEmpty { entered.removeLast() } } label: {
                    Image(systemName: "delete.left").font(.system(size: 22)).frame(width: 74, height: 74)
                }
                .accessibilityLabel("Delete")
            }
            .foregroundStyle(theme.colors.onBackground)
            .buttonStyle(.plain)
        }
    }

    private func key(_ digit: String) -> some View {
        Button { press(digit) } label: {
            Text(digit)
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .foregroundStyle(theme.colors.onBackground)
                .frame(width: 74, height: 74)
                .background(Circle().fill(theme.colors.onBackground.opacity(0.07)))
        }
        .buttonStyle(KitoBiometricKeyStyle())
    }

    // MARK: Vault

    private var vault: some View {
        let gold = Color(red: 0.93, green: 0.76, blue: 0.42)
        return ZStack {
            RadialGradient(colors: [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.03, green: 0.03, blue: 0.04)], center: .center, startRadius: 20, endRadius: 420)
            VStack(spacing: theme.spacing.xl) {
                Spacer()
                ZStack {
                    ForEach(0..<60, id: \.self) { tick in
                        Capsule()
                            .fill(tick % 5 == 0 ? gold : gold.opacity(0.3))
                            .frame(width: 2, height: tick % 5 == 0 ? 14 : 7)
                            .offset(y: -104)
                            .rotationEffect(.degrees(Double(tick) * 6))
                    }
                    .rotationEffect(.degrees(dialTurn))
                    Circle()
                        .stroke(LinearGradient(colors: [gold.opacity(0.9), gold.opacity(0.15)], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                        .frame(width: 170, height: 170)
                    Circle().fill(Color.white.opacity(0.04)).frame(width: 150, height: 150)
                    KitoBiometricGlyph(type: type, state: glyph, size: 70, tint: gold)
                }
                .frame(width: 240, height: 240)
                .onTapGesture { Task { await authenticate() } }
                VStack(spacing: 6) {
                    Text(title.uppercased())
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .kerning(3)
                        .foregroundStyle(gold)
                    Text(status ?? message ?? reason)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }
                Spacer()
                Button { Task { await authenticate() } } label: {
                    Label(unlockTitle, systemImage: type.systemImage).frame(maxWidth: .infinity)
                }
                .buttonStyle(KitoBiometricCapsuleStyle(fill: gold, label: .black))
                .disabled(glyph == .scanning)
            }
            .padding(theme.spacing.xl)
        }
        .ignoresSafeArea(edges: .top)
        .environment(\.colorScheme, .dark)
        .onChange(of: glyph) { _, new in
            guard !reduceMotion else { return }
            withAnimation(new == .scanning ? .linear(duration: 1.2).repeatForever(autoreverses: false) : .spring(response: 0.8, dampingFraction: 0.6)) {
                dialTurn = new == .scanning ? dialTurn + 360 : (new == .success ? dialTurn + 90 : dialTurn)
            }
        }
    }
}

/// A full-width capsule button.
struct KitoBiometricCapsuleStyle: ButtonStyle {
    let fill: Color
    let label: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(label)
            .padding(.horizontal, 20)
            .frame(minHeight: 52)
            .background(Capsule().fill(fill))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A keypad key that dips when pressed.
struct KitoBiometricKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
