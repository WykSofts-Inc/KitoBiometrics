# KitoBiometrics

Face ID / Touch ID behind a small async API, plus a drop-in themed lock
screen.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoBiometrics.git", from: "1.0.0"),
```

Add `NSFaceIDUsageDescription` to your `Info.plist` (Touch ID needs no plist entry).

## Samples

**Direct check:**
```swift
let result = await KitoBiometricAuthenticator().authenticate(reason: "Unlock your wallet")
switch result {
case .success: unlock()
case .failed(let reason): showError(reason)
case .unavailable: fallBackToPasscode()
case .userCancelled: break
}
```

**Wrap sensitive content directly:**
```swift
KitoBiometricLockView(reason: "Unlock to view your card") {
    CardDetailsView(card: card)
}
```

**Which biometry is available (for icon/copy):**
```swift
switch KitoBiometricAuthenticator().availableBiometricType {
case .faceID: Text("Sign in with Face ID")
case .touchID: Text("Sign in with Touch ID")
case .opticID: Text("Sign in with Optic ID")
case .none: Text("Sign in with passcode")
}
```

**Gate a checkout confirmation:**
```swift
func confirmPurchase() async {
    let result = await authenticator.authenticate(reason: "Confirm your $42.00 purchase")
    guard case .success = result else { return }
    await viewModel.completePurchase()
}
```

## License

MIT
