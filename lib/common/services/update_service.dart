import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UpdateService {
  final SupabaseClient _supabase;

  UpdateService(this._supabase);

  /// Checks if a newer version is available in Supabase
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      // 1. Get current local version & build number
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);
      // packageInfo.buildNumber is a String, parse it safely to int
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 2. Get latest version from Supabase
      // Assuming you always want the row with the highest build_number or created_at
      final response = await _supabase
          .from('app_versions')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final latestVersionStr = response['version'] as String;
      final latestVersion = Version.parse(latestVersionStr);

      // IMPORTANT: Ensure your Supabase table has a 'build_number' (int8) column
      // If it's missing or null, default to 0
      final latestBuild = response['build_number'] as int? ?? 0;

      final downloadUrl = response['download_url'] as String;
      final isMandatory = response['is_mandatory'] as bool;
      final releaseNotes = response['release_notes'] as String?;

      // Debugging logs
      // print("Local: $currentVersion ($currentBuild) vs Remote: $latestVersion ($latestBuild)");

      // 3. Compare Logic

      // Case A: The semantic version is strictly higher (e.g., 1.0.1 > 1.0.0)
      if (latestVersion > currentVersion) {
        return AppUpdateInfo(
          version: latestVersionStr,
          url: downloadUrl,
          isMandatory: isMandatory,
          releaseNotes: releaseNotes,
        );
      }
      // Case B: The version strings are equal, but the Remote Build Number is higher
      // (e.g., Local: 1.0.0 (10) vs Remote: 1.0.0 (12))
      else if (latestVersion == currentVersion && latestBuild > currentBuild) {
        return AppUpdateInfo(
          version: latestVersionStr,
          url: downloadUrl,
          isMandatory: isMandatory,
          releaseNotes: releaseNotes,
        );
      }
    } catch (e) {
      debugPrint("Error checking for updates: $e");
    }
    return null;
  }

  /// Triggers the download and installation
  Stream<OtaEvent> downloadAndInstall(String url) {
    if (Platform.isAndroid) {
      // destinationFilename is optional; ota_update handles temp storage
      return OtaUpdate().execute(
        url,
        destinationFilename: 'lovely_update.apk',
      );
    } else {
      throw Exception("OTA updates are only supported on Android.");
    }
  }
}

class AppUpdateInfo {
  final String version;
  final String url;
  final bool isMandatory;
  final String? releaseNotes;

  AppUpdateInfo({
    required this.version,
    required this.url,
    required this.isMandatory,
    this.releaseNotes,
  });
}

// Providers
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(Supabase.instance.client);
});

// A FutureProvider to easily fetch the status on app start
final updateCheckProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.checkForUpdate();
});
