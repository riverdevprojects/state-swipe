# Stateswipe 1.0 — release handoff

## Prepared in this repository

- Native iPhone app, iOS 16.0 deployment target (retains iPhone 8 compatibility).
- Version 1.0, build 2; existing bundle ID `com.riverdevprojects.stateswipe` and signing team `AGZ456A9MS` preserved.
- Complete opaque app icon set, including the 1024 × 1024 App Store icon.
- Guided seven-step practice tutorial with animated touch pointers, Back, Skip, Close, and Finish. Practice never writes to a game or personal best.
- Minimal gameplay labels; requested taglines removed.
- UserDefaults privacy manifest, in-app privacy information, and non-exempt-encryption flag set to NO (this build implements no encryption/networking).
- English listing text and reviewer instructions in this folder.
- Static support and privacy pages under `docs/` (not yet published).
- Shared Xcode scheme with simulator UI tests; optimized unsigned iPhone archive validated locally.

## Required before App Store submission

1. **Upgrade the build environment.** This Mac has Xcode 16.4. Apple's current upload requirement is Xcode 26 or later with the iOS 26 SDK. Retain the app's iOS 16 deployment target. Run `Scripts/check-release.sh` to verify the selected toolchain.
2. **Publish support pages.** The GitHub repository is public and has Issues enabled. Push the completed source, then enable GitHub Pages from the chosen branch's `/docs` folder, or publish those static files on an existing host. Do not enter the proposed URLs into App Store Connect until both are publicly reachable:
   - Support: `https://riverdevprojects.github.io/state-swipe/`
   - Privacy: `https://riverdevprojects.github.io/state-swipe/privacy.html`
   These are proposed Pages locations, not verified live URLs. The support contact is the repository's public GitHub issue form.
3. **Complete App Store Connect setup.** Select the correct Apple Developer membership and app record. Confirm the signing team and bundle ID are registered to that account. An Apple Development identity is present on this Mac; App Store distribution provisioning and upload have not been performed.
4. **Finish owner-specific listing fields.** Enter copyright owner, App Review contact information, price, territories, and the age-rating questionnaire. Suggested category: Games → Trivia (and Word or Education if appropriate). Do not select the Kids category unless you intend to meet its separate requirements. No pricing or availability decisions have been made.
5. **Privacy answers.** For the current build, select “No, we do not collect data from this app.” There are no ads, analytics SDKs, tracking, accounts, in-app purchases, or subscriptions. Publish the privacy-policy URL before submitting.
6. **Physical-device pass.** Test iPhone 8/iOS 16, a modern iPhone, VoiceOver, large text, Reduce Motion, keyboard entry, background/resume, and a full session. Simulator testing is not a substitute for this final hardware check.
7. **Archive, validate, and upload using current Xcode.** Select Any iOS Device, Product → Archive, then Validate App and Distribute App → App Store Connect. Use TestFlight for the final device pass before submitting for review. The locally validated archive in the task's `work/` folder is unsigned and built with Xcode 16.4; it is not an uploadable release.

## Supporting Apple references

- Upload SDK requirement: https://developer.apple.com/news/upcoming-requirements/?id=04282026a
- Screenshot sizes: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- Privacy declarations and required public policy URL: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/

Screenshots captured from the app for the 6.9-inch iPhone display are stored in `Screenshots/6.9-inch/` when generated. They show real app screens without promotional overlays. Use the same-size set for the listing; confirm it still represents the final uploaded build.
