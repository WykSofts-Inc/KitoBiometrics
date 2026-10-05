# KitoBiometrics

**[Documentation](https://wyksofts-inc.github.io/KitoBiometrics/documentation/kitobiometrics/)**

Face ID / Touch ID behind a small async API, four lock-screen styles, an
animated biometric glyph, a "protect this action" modifier and an app lock.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoBiometrics.git", from: "1.1.0"),
```

Add `NSFaceIDUsageDescription` to your `Info.plist` (Touch ID needs no plist entry).

## Lock screens

```swift
KitoBiometricLockScreen(style: .glass, userName: "Wycliff N", reason: "Unlock your wallet") { unlock() }
```

Styles: `.minimal`, `.glass` (frosted card over a drifting colour field), `.passcode`
(glyph plus a six-digit keypad — pass `passcode:`), `.vault` (dark with a rotating dial).
Failures shake and explain; after three the passcode keypad takes over.

`KitoBiometricLockView(reason:style:) { … }` wraps content in any of them.

## Protect one action

```swift
Text(showsBalance ? "KSh 48,250" : "KSh ••••••")
    .kitoProtectedAction(reason: "Show your balance") { showsBalance = true }
```

## Lock the app when it goes to the background

```swift
RootView()
    .kitoBiometricAppLock(isEnabled: settings.appLock, style: .glass, userName: "Wycliff N")
```

It also blurs your content in the app switcher.

### Know when the app is locked (1.2.0+)

Pass `isLocked:` to keep your own flag in sync with the lock screen. Set it to `true` to lock right away.

```swift
RootView()
    .kitoBiometricAppLock(isEnabled: settings.appLock, style: .glass, isLocked: $viewModel.isAppLocked)
```

Views inside the lock can read the same state from the environment, for example to hold a deep link
or a notification tap until the owner unlocks. It reads `.locked` from the first frame when the app
will lock on launch, so a link that cold-launches the app waits too.

```swift
@Environment(\.kitoBiometricAppLockState) private var appLockState

TabsView()
    .onOpenURL { url in
        if appLockState == .locked { viewModel.pendingURL = url } else { viewModel.open(url) }
    }
    .onChange(of: appLockState) { _, state in
        if state == .unlocked { viewModel.openPendingURL() }
    }
```

## The glyph on its own

```swift
KitoBiometricGlyph(type: .faceID, state: .scanning)   // .idle, .scanning, .success, .failure
```

## Previews and demos

The simulator usually has no enrolled face, so pass
`authenticator: KitoSimulatedBiometricAuthenticator(result: .success)` (or
`KitoFlakyBiometricAuthenticator(failures: 2)`) to any view above.

## Right-to-left

Lock screens and buttons mirror automatically in right-to-left layouts. The passcode keypad and its
dots stay left to right (1-2-3 on top, like the system keypad, since numbers read left to right in
every script), and the drawn Face ID mark stays unmirrored like the system glyph. Copy is English;
localise the titles you pass in.

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
