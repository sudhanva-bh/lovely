import 'dart:io';

import 'package:lovely/common/models/user_model.dart';
import 'package:lovely/features/auth/providers/auth_provider.dart'; // Import AuthProvider
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  // 1. Create or Update User
  Future<void> saveProfile(UserModel user) async {
    final Map<String, dynamic> data = user.toMap();
    data.remove('partner');
    await _supabase.from('profiles').upsert(data);
  }

  // 2. Get Single Profile (with joined Partner data)
  Future<UserModel> getProfile(String uid) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, partner:profiles(*)')
          .eq('uid', uid)
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  // 3. Search Profiles
  Future<List<UserModel>> searchProfiles(String query) async {
    final response = await _supabase
        .from('profiles')
        .select('*, partner:profiles(*)')
        .ilike('name', '%$query%')
        .limit(10);

    return (response as List).map((e) => UserModel.fromMap(e)).toList();
  }

  Future<String> uploadProfilePicture(String uid, File imageFile) async {
    try {
      final String path = '$uid/avatar';

      await _supabase.storage
          .from('profile_pics')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final String publicUrl = _supabase.storage
          .from('profile_pics')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(Supabase.instance.client);
});

// CHANGED: Converted to Provider and watch authState to be reactive
final currentUserUidProvider = Provider<String?>((ref) {
  // Watch auth changes to trigger rebuilds
  ref.watch(authStateProvider);
  // Return current value synchronously to avoid async race conditions
  return Supabase.instance.client.auth.currentUser?.id;
});

final userProfileStreamProvider = StreamProvider.autoDispose<UserModel>((ref) {
  final service = ref.watch(profileServiceProvider);
  final uid = ref.watch(currentUserUidProvider);

  if (uid == null) {
    return const Stream.empty();
  }

  return Supabase.instance.client
      .from('profiles')
      .stream(primaryKey: ['uid'])
      .eq('uid', uid)
      .asyncMap((event) async {
        return await service.getProfile(uid);
      });
});