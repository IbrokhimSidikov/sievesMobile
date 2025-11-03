# Force Update Setup Guide

This guide explains how to configure Firebase Remote Config for the force update feature.

## Overview

The force update system compares the app's current version with values stored in Firebase Remote Config and determines whether:
- **Force Update Required**: User must update to continue using the app
- **Update Available**: User is notified but can skip the update

## Firebase Remote Config Parameters

Set up the following parameters in Firebase Console:

### 1. Go to Firebase Console
- Navigate to: https://console.firebase.google.com
- Select your project
- Go to **Remote Config** in the left sidebar

### 2. Add Parameters

Create the following parameters:

#### `minimum_required_version` (String)
- **Description**: Minimum version users must have to use the app
- **Default value**: `1.0.0`
- **Example**: `1.6.0` - Users with version < 1.6.0 will be forced to update

#### `latest_version` (String)
- **Description**: Latest available version in the store
- **Default value**: `1.0.0`
- **Example**: `1.7.0` - Users will see "update available" notification

#### `force_update_enabled` (Boolean)
- **Description**: Enable/disable force update feature
- **Default value**: `false`
- **Example**: `true` - Enable force update checks

#### `update_message` (String)
- **Description**: Message shown to users in the update dialog
- **Default value**: `A new version is available. Please update to continue.`
- **Example**: `We've added exciting new features! Update now to enjoy them.`

#### `android_store_url` (String)
- **Description**: Google Play Store URL for your app
- **Default value**: `https://play.google.com/store/apps/details?id=com.sieves.v1.sieves_mob`
- **Example**: Update with your actual Play Store URL

#### `ios_store_url` (String)
- **Description**: Apple App Store URL for your app
- **Default value**: `https://apps.apple.com/app/your-app-id`
- **Example**: `https://apps.apple.com/app/id1234567890`

## How It Works

### Version Comparison Logic

The system compares versions using semantic versioning (e.g., `1.2.3`):
- Major.Minor.Patch format
- Compares each segment left to right
- Example: `1.5.9` < `1.6.0` < `2.0.0`

### Update Flow

1. **App Launch**: 
   - Shows "Checking for updates..." screen
   - Fetches Remote Config values
   - Compares current version with remote versions

2. **Force Update Required** (`current < minimum_required_version` AND `force_update_enabled = true`):
   - Shows non-dismissible dialog
   - User must tap "Update Now" to go to store
   - App cannot be used until updated

3. **Update Available** (`current < latest_version`):
   - Shows dismissible dialog
   - User can tap "Later" to skip
   - User can tap "Update Now" to go to store

4. **No Update Needed**:
   - App launches normally

## Testing the Feature

### Test Scenario 1: Force Update
1. Set in Firebase Remote Config:
   ```
   minimum_required_version: "2.0.0"
   latest_version: "2.0.0"
   force_update_enabled: true
   ```
2. Your app version is `1.6.0` (from pubspec.yaml)
3. Result: Force update dialog appears, cannot be dismissed

### Test Scenario 2: Optional Update
1. Set in Firebase Remote Config:
   ```
   minimum_required_version: "1.6.0"
   latest_version: "1.7.0"
   force_update_enabled: true
   ```
2. Your app version is `1.6.0`
3. Result: Update available dialog appears, can be dismissed

### Test Scenario 3: No Update
1. Set in Firebase Remote Config:
   ```
   minimum_required_version: "1.6.0"
   latest_version: "1.6.0"
   force_update_enabled: true
   ```
2. Your app version is `1.6.0`
3. Result: App launches normally

### Test Scenario 4: Feature Disabled
1. Set in Firebase Remote Config:
   ```
   force_update_enabled: false
   ```
2. Result: No update checks performed, app launches normally

## Deployment Workflow

### When Releasing a New Version

1. **Before Release**:
   - Update `version` in `pubspec.yaml` (e.g., `1.7.0+8`)
   - Build and test the app
   - Submit to stores (Google Play / App Store)

2. **After Store Approval**:
   - Update Firebase Remote Config:
     - Set `latest_version` to new version (e.g., `1.7.0`)
     - Keep `minimum_required_version` at current or older version
     - Set `force_update_enabled` to `true` if needed

3. **For Critical Updates** (security fixes, breaking changes):
   - Set `minimum_required_version` to the new version
   - Set `force_update_enabled` to `true`
   - Users will be forced to update

## Troubleshooting

### Update Dialog Not Showing
- Check Firebase Remote Config is properly initialized
- Verify `force_update_enabled` is `true`
- Check version format is correct (e.g., `1.6.0`, not `v1.6.0`)
- Look for errors in console logs

### Store Link Not Working
- Verify `android_store_url` and `ios_store_url` are correct
- Ensure app is published on the stores
- Test URLs in a browser first

### Remote Config Not Updating
- Default fetch interval is 1 hour
- For testing, reduce `minimumFetchInterval` in `version_service.dart`
- Clear app data and restart

## Next Steps

1. Run `flutter pub get` to install new dependencies
2. Set up Firebase Remote Config parameters in Firebase Console
3. Test the feature with different version scenarios
4. Update store URLs before production release
