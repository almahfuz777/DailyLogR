// lib/providers/version_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

/// Represents the state of the application version and update status.
class AppVersionState {
  final String currentVersion;
  final bool isChecking;
  final String? latestVersion;
  final String? apkDownloadUrl;
  final String? statusMessage;

  const AppVersionState({
    required this.currentVersion,
    this.isChecking = false,
    this.latestVersion,
    this.apkDownloadUrl,
    this.statusMessage,
  });

  AppVersionState copyWith({
    String? currentVersion,
    bool? isChecking,
    String? latestVersion,
    String? apkDownloadUrl,
    String? statusMessage,
  }) {
    return AppVersionState(
      currentVersion: currentVersion ?? this.currentVersion,
      isChecking: isChecking ?? this.isChecking,
      latestVersion: latestVersion ?? this.latestVersion,
      apkDownloadUrl: apkDownloadUrl ?? this.apkDownloadUrl,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

/// Dynamic notifier for app version fetching and update checking.
class AppVersionNotifier extends Notifier<AppVersionState> {
  @override
  AppVersionState build() {
    _loadCurrentVersion();
    return const AppVersionState(currentVersion: '...');
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      state = state.copyWith(currentVersion: packageInfo.version);
    } catch (_) {
      state = state.copyWith(currentVersion: 'Unknown');
    }
  }

  /// Checks for new releases on GitHub.
  Future<void> checkForUpdates() async {
    if (state.isChecking) return;

    if (state.currentVersion == '...' || state.currentVersion == 'Unknown') {
      state = state.copyWith(
        statusMessage: 'Cannot check for updates: current app version is unresolved.',
      );
      return;
    }

    // Version checking starts here
    state = state.copyWith(
      isChecking: true,
      statusMessage: null,
      latestVersion: null,
      apkDownloadUrl: null,
    );

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/almahfuz777/DailyLogR/releases/latest'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String? ?? '';

        if (tagName.isNotEmpty) {
          final isNewer = _isNewerVersion(state.currentVersion, tagName);

          if (isNewer) {
            final assets = data['assets'] as List?;
            String? apkUrl;
            if (assets != null && assets.isNotEmpty) {
              final apkAsset = assets.firstWhere(
                (asset) => (asset['name'] as String).toLowerCase().endsWith('.apk'),
                orElse: () => assets.first,
              );
              apkUrl = apkAsset['browser_download_url'] as String?;
            }
            state = state.copyWith(
              isChecking: false,
              latestVersion: tagName,
              apkDownloadUrl: apkUrl ?? 'https://github.com/almahfuz777/DailyLogR/releases/',
              statusMessage: 'New version $tagName is available!',
            );
          } else {
            state = state.copyWith(
              isChecking: false,
              latestVersion: tagName,
              statusMessage: 'You are using the latest version.',
            );
          }
        } else {
          state = state.copyWith(
            isChecking: false,
            statusMessage: 'No release tag found.',
          );
        }
      } else {
        state = state.copyWith(
          isChecking: false,
          statusMessage: 'Failed to check for updates (code ${response.statusCode}).',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        statusMessage: 'Unable to check for updates. Please check your internet connection.',
      );
    }
  }

  // Compare version numbers from strings
  bool _isNewerVersion(String current, String latest) {
    final cleanCurrent = current.replaceAll(RegExp(r'[^\d.]'), '');
    final cleanLatest = latest.replaceAll(RegExp(r'[^\d.]'), '');

    final currentParts = cleanCurrent.split('.').map(int.tryParse).toList();
    final latestParts = cleanLatest.split('.').map(int.tryParse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      final latestVal = latestParts[i] ?? 0;
      final currentVal = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      if (latestVal > currentVal) return true;
      if (latestVal < currentVal) return false;
    }
    return false;
  }
}

/// Global provider for checking app versions and updates.
final appVersionProvider = NotifierProvider<AppVersionNotifier, AppVersionState>(() {
  return AppVersionNotifier();
});
