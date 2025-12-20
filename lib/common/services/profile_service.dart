import 'dart:io';

import 'package:lovely/common/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  // 1. Create or Update User
  Future<void> saveProfile(UserModel user) async {
    // user.toMap() now correctly creates 'partner_uid' instead of 'partner_id'
    final Map<String, dynamic> data = user.toMap();

    // We no longer need manual logic here because toMap handles
    // the partner_uid correctly based on whether user.partner is null or not.
    // ensure the 'partner' object key isn't sent (though toMap doesn't include it anyway)
    data.remove('partner');

    // Ensure we are updating the row matching the UID
    await _supabase.from('profiles').upsert(data);
  }

  // 2. Get Single Profile (with joined Partner data)
  Future<UserModel> getProfile(String uid) async {
    try {
      // Fetch profile and join the partner profile using the foreign key constraint.
      // We alias the joined table as 'partner'.
      // Note: If 'partner:partner_uid(*)' fails, try 'partner:profiles!profiles_partner_uid_fkey(*)'
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
        // Same join logic here
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

final currentUserUidProvider = StateProvider<String?>(
  (ref) => Supabase.instance.client.auth.currentUser?.id,
);

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
