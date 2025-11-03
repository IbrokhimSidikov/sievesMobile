import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionService {
  final FirebaseRemoteConfig _remoteConfig;

  VersionService(this._remoteConfig);

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 0), // For testing, set to 0
      ),
    );

    // Set default values (used if fetch fails or no remote values set)
    await _remoteConfig.setDefaults({
      'minimum_required_version': '2.0.0', // FOR TESTING - Change back to 1.0.0 for production
      'latest_version': '2.0.0',
      'force_update_enabled': true,
      'update_message': 'A new version is available. Please update to continue.',
      'android_store_url': 'https://play.google.com/apps/testing/com.sieves.v1.sieves_mob',
      'ios_store_url': 'https://apps.apple.com/app/sieves/id6753124737',
    });

    // Fetch and activate from Firebase Console
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      print('🔥 Firebase Remote Config fetch result: $activated');
      print('   minimum_required_version: ${_remoteConfig.getString('minimum_required_version')}');
      print('   latest_version: ${_remoteConfig.getString('latest_version')}');
      print('   force_update_enabled: ${_remoteConfig.getBool('force_update_enabled')}');
    } catch (e) {
      print('⚠️ Failed to fetch Remote Config, using defaults: $e');
    }
  }

  /// Check if force update is required
  Future<UpdateStatus> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final minimumRequiredVersion = _remoteConfig.getString('minimum_required_version');
      final latestVersion = _remoteConfig.getString('latest_version');
      final forceUpdateEnabled = _remoteConfig.getBool('force_update_enabled');

      // Compare versions
      final isUpdateRequired = forceUpdateEnabled && 
          _isVersionLower(currentVersion, minimumRequiredVersion);
      final isUpdateAvailable = _isVersionLower(currentVersion, latestVersion);

      return UpdateStatus(
        isUpdateRequired: isUpdateRequired,
        isUpdateAvailable: isUpdateAvailable,
        currentVersion: currentVersion,
        minimumRequiredVersion: minimumRequiredVersion,
        latestVersion: latestVersion,
        updateMessage: _remoteConfig.getString('update_message'),
        androidStoreUrl: _remoteConfig.getString('android_store_url'),
        iosStoreUrl: _remoteConfig.getString('ios_store_url'),
      );
    } catch (e) {
      print('Error checking for update: $e');
      return UpdateStatus.noUpdate();
    }
  }

  /// Compare two version strings (e.g., "1.2.3" vs "1.3.0")
  /// Returns true if version1 < version2
  bool _isVersionLower(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part < v2Part) return true;
      if (v1Part > v2Part) return false;
    }

    return false; // Versions are equal
  }
}

class UpdateStatus {
  final bool isUpdateRequired;
  final bool isUpdateAvailable;
  final String currentVersion;
  final String minimumRequiredVersion;
  final String latestVersion;
  final String updateMessage;
  final String androidStoreUrl;
  final String iosStoreUrl;

  UpdateStatus({
    required this.isUpdateRequired,
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.minimumRequiredVersion,
    required this.latestVersion,
    required this.updateMessage,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  factory UpdateStatus.noUpdate() {
    return UpdateStatus(
      isUpdateRequired: false,
      isUpdateAvailable: false,
      currentVersion: '0.0.0',
      minimumRequiredVersion: '0.0.0',
      latestVersion: '0.0.0',
      updateMessage: '',
      androidStoreUrl: '',
      iosStoreUrl: '',
    );
  }
}
