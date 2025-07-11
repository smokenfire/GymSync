# GitHub Workflows for GymSync

This directory contains the GitHub Actions workflow files that automatically run tests and builds for each app in the GymSync project.

## Workflows

### CI (`ci.yml`)
- Runs tests for all apps (Backend, Mobile App, Presence App)
- Triggered when changes are made to files in any of the `apps/backend`, `apps/mobile_app`, or `apps/presence` directories
- Contains three jobs:
  - **Backend Tests:** Uses Node.js 18 and Jest for testing the backend Express API
  - **Mobile App Tests:** Uses Flutter and the built-in Flutter testing framework
  - **Presence App Tests:** Uses Node.js 18 and Jest for testing the Electron presence app

### Build Desktop Presence Windows (`build-desktop-windows.yml`)
- Builds the Presence desktop app for Windows
- Triggered on push to `main` and on pull requests
- Steps:
  - Sets up Flutter and Node.js environments
  - Installs dependencies and builds the app
  - Zips the Windows build output
  - Uploads the zipped artifact

### Build Desktop Presence MacOS (`build-desktop-macos.yml`)
- Builds the Presence desktop app for MacOS
- Triggered on push to `main` and on pull requests
- Steps:
  - Sets up Flutter and Node.js environments
  - Installs dependencies and builds the app
  - Zips the MacOS build output
  - Uploads the zipped artifact

### Build Desktop Presence Linux (`build-desktop-linux.yml`)
- Builds the Presence desktop app for Linux
- Triggered on push to `main` and on pull requests
- Steps:
  - Sets up Flutter and Node.js environments
  - Installs dependencies and builds the app
  - Zips the Linux build output
  - Uploads the zipped artifact

### Build APK with Makefile (`build-apk-makefile.yml`)
- Builds the mobile app APK using a Makefile
- Triggered on push to `main` and on pull requests
- Steps:
  - Sets up Flutter and Node.js environments
  - Installs `make`
  - Runs the Makefile to build the APK
  - Uploads the APK artifact

### Test Ninja Build (`test-ninja.yml`)
- Runs a test build using Ninja
- Triggered on push and pull requests
- Steps:
  - Sets up Flutter and Node.js environments
  - Installs Ninja
  - Runs the Ninja build command

## Manual Triggering

The main CI workflow can be manually triggered using the "workflow_dispatch" event in the GitHub Actions UI.

## Adding New Tests

When adding new tests:

1. Place test files in the appropriate test directory:
   - Backend: `apps/backend/__tests__/`
   - Mobile App: `apps/mobile_app/test/`
   - Presence App: `apps/presence/__tests__/`

2. Make sure the tests follow the conventions of the testing framework being used:
   - Backend & Presence: Jest
   - Mobile App: Flutter Test

## Troubleshooting

If tests are failing in the CI environment but passing locally:

1. Check for environment-specific issues (file paths, environment variables, etc.)
2. Ensure all dependencies are properly declared in the package.json or pubspec.yaml files
3. Check the GitHub Actions logs for detailed error messages