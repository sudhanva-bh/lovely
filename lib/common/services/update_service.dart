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
      // 1. Get current local version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);

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
      final downloadUrl = response['download_url'] as String;
      final isMandatory = response['is_mandatory'] as bool;
      final releaseNotes = response['release_notes'] as String?;

      print("----------------------------------------------------------------");
      print("Current Version: $currentVersion, Latest Version: $latestVersion");
      print(latestVersion > currentVersion);
      print("----------------------------------------------------------------");

      // 3. Compare
      if (latestVersion > currentVersion) {
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
