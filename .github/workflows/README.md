# GitHub Workflows for GymSync

This directory contains GitHub Actions workflow files that automatically run tests for each app in the GymSync project.

## Workflows

### Backend Tests (`backend-tests.yml`)
- Runs tests for the backend Express API
- Triggered when changes are made to files in the `apps/backend` directory
- Uses Node.js 18 and Jest for testing

### Mobile App Tests (`mobile-app-tests.yml`)
- Runs tests for the Flutter mobile app
- Triggered when changes are made to files in the `apps/mobile_app` directory
- Uses Flutter and the built-in Flutter testing framework

### Presence App Tests (`presence-tests.yml`)
- Runs tests for the Electron presence app
- Triggered when changes are made to files in the `apps/presence` directory
- Uses Node.js 18 and Jest for testing

## Manual Triggering

All workflows can be manually triggered using the "workflow_dispatch" event in the GitHub Actions UI.

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