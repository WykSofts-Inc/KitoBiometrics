//
//  KitoBiometricGlyph.swift
//  KitoBiometrics
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// Where a biometric check is.
public enum KitoBiometricGlyphState: Equatable, Sendable {
    case idle, scanning, success, failure
}

/// An animated Face ID / Touch ID mark: corner brackets and a face that a scan line sweeps
/// while checking, a check on success and a shake on failure. Still under Reduce Motion.
public struct KitoBiometricGlyph: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let type: KitoBiometricType
    let state: KitoBiometricGlyphState
    let size: CGFloat
    let tint: Color?

    @State private var sweep = false
    @State private var shake: CGFloat = 0

    public init(type: KitoBiometricType = .faceID, state: KitoBiometricGlyphState = .idle, size: CGFloat = 72, tint: Color? = nil) {
        self.type = type
        self.state = state
        self.size = size
        self.tint = tint
    }

    private var color: Color {
        switch state {
        case .success: return theme.colors.success
        case .failure: return theme.colors.danger
        case .idle, .scanning: return tint ?? theme.colors.primary
        }
    }

    public var body: some View {
        ZStack {
            if type == .touchID {
                touchMark
            } else {
                faceMark
            }
        }
        .frame(width: size, height: size)
        .modifier(KitoShakeEffect(travel: shake))
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7), value: state)
        .onChange(of: state) { _, new in
            if new == .failure && !reduceMotion {
                withAnimation(.linear(duration: 0.45)) { shake += 1 }
            }
            sweep = new == .scanning && !reduceMotion
        }
        .onAppear { sweep = state == .scanning && !reduceMotion }
        .accessibilityElement()
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        switch state {
        case .idle: return type.displayName
        case .scanning: return "Checking \(type.displayName)"
        case .success: return "Verified"
        case .failure: return "Not recognised"
        }
    }

    private var faceMark: some View {
        ZStack {
            KitoFaceFrameShape()
                .stroke(color, style: StrokeStyle(lineWidth: max(size * 0.05, 2), lineCap: .round, lineJoin: .round))
                .scaleEffect(state == .scanning ? 0.9 : 1)
                .animation(state == .scanning && !reduceMotion ? .easeInOut(duration: 0.7).repeatForever(autoreverses: true) : .default, value: state)

            Group {
                switch state {
                case .success:
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.4, weight: .bold))
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                case .failure:
                    Image(systemName: "xmark")
                        .font(.system(size: size * 0.36, weight: .bold))
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                case .idle, .scanning:
                    KitoFaceFeaturesShape()
                        .stroke(color, style: StrokeStyle(lineWidth: max(size * 0.045, 1.8), lineCap: .round, lineJoin: .round))
                        .frame(width: size * 0.5, height: size * 0.5)
                        // Matches the system Face ID mark, which does not mirror in right-to-left layouts.
                        .environment(\.layoutDirection, .leftToRight)
                        .transition(.opacity)
                }
            }
            .foregroundStyle(color)

            if state == .scanning {
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0), color, color.opacity(0)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: size * 0.78, height: max(size * 0.03, 1.5))
                    .shadow(color: color, radius: 6)
                    .offset(y: sweep ? size * 0.34 : -size * 0.34)
                    .animation(sweep ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default, value: sweep)
                    .transition(.opacity)
            }
        }
    }

    private var touchMark: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.25), lineWidth: max(size * 0.04, 1.5))
                .scaleEffect(sweep ? 1.18 : 1)
                .opacity(sweep ? 0 : 1)
                .animation(sweep ? .easeOut(duration: 1.1).repeatForever(autoreverses: false) : .default, value: sweep)
            Image(systemName: state == .success ? "checkmark.circle.fill" : state == .failure ? "xmark.circle.fill" : "touchid")
                .font(.system(size: size * 0.72, weight: .regular))
                .foregroundStyle(color)
                .contentTransition(.symbolEffect(.replace))
        }
    }
}

/// Four rounded corner brackets, like the Face ID frame.
struct KitoFaceFrameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let arm = rect.width * 0.3
        let radius = rect.width * 0.2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + arm))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + arm, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - arm, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + arm))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - arm))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - arm, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + arm, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - arm))
        return path
    }
}

/// Eyes, a nose and a smile.
struct KitoFaceFeaturesShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        // Eyes
        path.move(to: CGPoint(x: rect.minX + w * 0.2, y: rect.minY + h * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.2, y: rect.minY + h * 0.3))
        path.move(to: CGPoint(x: rect.minX + w * 0.8, y: rect.minY + h * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.8, y: rect.minY + h * 0.3))
        // Nose
        path.move(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.12))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.52, y: rect.minY + h * 0.55))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.55))
        // Smile
        path.move(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.76))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.82, y: rect.minY + h * 0.76), control: CGPoint(x: rect.midX, y: rect.maxY + h * 0.08))
        return path
    }
}

/// A horizontal wobble; bump `travel` by one to play one shake.
struct KitoShakeEffect: GeometryEffect {
    var travel: CGFloat
    var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 9 * sin(travel * .pi * 6), y: 0))
    }
}
