# Stateswipe

Native SwiftUI trivia for iPhone, with all 50 U.S. states. **iOS 16.0 minimum**, including iPhone 8 and iPhone 8 Plus. Offline, without accounts, ads, purchases, or external packages.

## Open and run

Open `StateSwipe.xcodeproj`, select the **StateSwipe** scheme and an iPhone simulator, and Run. The existing development team and bundle identifier have been preserved. For hardware, select the appropriate signing account in Xcode.

## Gameplay

Five ordered hints per state. The first is free; later costs are 90, 160, 250, and 350 points. Start with 1,000 points; a correct final guess earns the remainder, an incorrect guess earns zero. State names, abbreviations, and unambiguous minor typos are accepted. Invalid text does not use the guess.

After each state guess, a one-attempt postal abbreviation bonus doubles earned points for a correct code. Wrong codes and skips retain the original points. Wrong state guesses earn zero, with the bonus offered as practice.

The offline bank contains 1,364 rated clues, with at least five variations for every state at every hint level. Choices rotate through unused alternatives and remain fixed when a saved game resumes. See `docs/hint-bank.md` for coverage, sources, and difficulty guidelines.

Sessions have 1–50 unique states (default five). Current games and separate personal bests for each session length are saved locally. The question mark opens an isolated seven-step tutorial with animated touch pointers, practice input and submission, scoring, abbreviation bonus, and session-length selection. Back, Skip, Close, and Finish never change the active game.

Larger text uses a single-column hint layout, and Reduce Motion disables card flips and repeating touch animations. VoiceOver labels describe hints, costs, score, and tutorial controls.

## Verification

Run the UI tests with Product → Test in Xcode. They cover the guided flow, Back/Skip/reopening, game isolation, invalid guesses, correct scoring, relaunch persistence, and the tutorial with accessibility text sizes.

Portable model checks:

```sh
swiftc StateSwipe/Game.swift Tests/main.swift -o /tmp/stateswipe-tests
/tmp/stateswipe-tests StateSwipe/states.json
```

Device-local persistence and hint-cycle checks (macOS):

```sh
swiftc -parse-as-library StateSwipe/Game.swift StateSwipe/GameStore.swift Tests/store.swift -o /tmp/stateswipe-store-tests
/tmp/stateswipe-store-tests StateSwipe/states.json
```

## App Store preparation

See `AppStore/ReleaseChecklist.md` for the exact remaining steps. App icons, privacy manifest, export settings, listing text, reviewer notes, screenshots, and support/privacy page sources are included. No App Store upload or public website deployment has occurred.

**The current Mac has Xcode 16.4. Apple's current upload requirement is Xcode 26+ with the iOS 26 SDK.** Keep the minimum deployment target at iOS 16 to retain iPhone 8 support. `Scripts/check-release.sh` checks the toolchain before a submission build.

`docs/` contains static support and privacy pages suitable for GitHub Pages. The repository's Issues are enabled and used as the support contact; publish and verify the pages before entering their URLs in App Store Connect.

## Content

Floral emblems reference: https://www.usbg.gov/visit/exhibits/americas-state-flowers-america250-celebration . State facts and the complete hint bank are in `StateSwipe/states.json`; selection and scoring are in `Game.swift`.
