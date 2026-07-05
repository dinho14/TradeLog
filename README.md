# trading_journal_app

A Flutter trading journal app with analytics, trade logging, and overview dashboards.

## CI/CD

This repository includes a GitHub Actions workflow for continuous integration and Android builds.

### What it does
- runs Flutter analysis on every pull request and push to main
- runs tests
- builds a release APK
- builds a release App Bundle (AAB)
- uploads both artifacts for download from GitHub Actions

### Setup notes
1. Push this repository to GitHub.
2. Ensure the default branch is named `main`.
3. Trigger the workflow manually or push a commit to main.
4. Download the generated APK or AAB from the Actions run artifacts.
5. To enable Play Store publishing, add these GitHub repository secrets:
   - `ANDROID_KEYSTORE_BASE64`
   - `ANDROID_KEYSTORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
