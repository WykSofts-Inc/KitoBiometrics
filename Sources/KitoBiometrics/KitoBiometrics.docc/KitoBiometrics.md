# ``KitoBiometrics``

Face ID and Touch ID behind a small async API, with themed lock screens and an animated biometric glyph.

## Overview

KitoBiometrics wraps `LAContext` in ``KitoBiometricAuthenticator``, whose
``KitoBiometricResult`` distinguishes a successful match, a failed attempt, an
unavailable device, and a user cancellation, so each case can get its own UI
treatment.

On top of that it provides ready-made screens. ``KitoBiometricLockScreen`` is a
full-screen lock in one of four ``KitoBiometricLockStyle`` looks — minimal,
glass, passcode and vault — and ``KitoBiometricLockView`` reveals its content
only after the owner is confirmed. Failures shake and explain; after three the
passcode keypad takes over when you supply a passcode.

```swift
KitoBiometricLockView(reason: "Unlock to view your card", style: .glass) {
    CardDetailsView(card: card)
}
```

Two view modifiers cover the other common cases: `kitoProtectedAction(reason:perform:)`
runs an action only after a biometric check, and `kitoBiometricAppLock(isEnabled:style:userName:)`
locks the whole app when it goes to the background and blurs it in the app
switcher. Add `NSFaceIDUsageDescription` to your `Info.plist` before using Face ID.

The simulator usually has no enrolled face, so pass a
``KitoSimulatedBiometricAuthenticator`` or ``KitoFlakyBiometricAuthenticator`` to
any view for previews and demos.

## Topics

### Authentication

- ``KitoBiometricAuthenticator``
- ``KitoBiometricAuthenticating``
- ``KitoBiometricResult``
- ``KitoBiometricType``

### Lock Screens

- ``KitoBiometricLockScreen``
- ``KitoBiometricLockView``
- ``KitoBiometricLockStyle``

### Glyph

- ``KitoBiometricGlyph``
- ``KitoBiometricGlyphState``

### Previews and Testing

- ``KitoSimulatedBiometricAuthenticator``
- ``KitoFlakyBiometricAuthenticator``
