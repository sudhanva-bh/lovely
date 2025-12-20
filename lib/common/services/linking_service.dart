import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LinkingService {
  final SupabaseClient _client;

  LinkingService(this._client);

  /// Convenience getter
  String get currentUid => _client.auth.currentUser!.id;

  /* -----------------------------------------------------------
   * 1. Link profiles (two-way) using UID
   * ----------------------------------------------------------- */
  Future<void> linkProfiles({
    required String targetUid,
  }) async {
    // rpc throws a PostgrestException if there is an error
    await _client.rpc(
      'linkProfiles',
      params: {
        'target_uid': targetUid,
      },
    );
  }

  /* -----------------------------------------------------------
   * 2. Link by Code (New)
   * Calls: public.link_profile_by_code(code text)
   * ----------------------------------------------------------- */
  Future<void> linkByCode(String code) async {
    await _client.rpc(
      'linkprofilesbycouplecode',
      params: {
        'input_couple_code': code,
      },
    );
  }

  /* -----------------------------------------------------------
   * 3. Get Current Code
   * Fetches the code from the profile
   * ----------------------------------------------------------- */
  Future<String> getCoupleCode() async {
    // Attempt to fetch existing code
    final response = await _client
        .from('profiles')
        .select('couple_code')
        .eq('uid', currentUid)
        .single();

    final code = response['couple_code'] as String?;
    if (code != null && code.isNotEmpty) {
      return code;
    }

    // If none exists, generate one
    return await regenerateCoupleCode();
  }

  /* -----------------------------------------------------------
   * 4. Unlink profiles
   * ----------------------------------------------------------- */
  Future<void> unlinkProfiles() async {
    await _client.rpc(
      'unlinkprofiles',
    );
  }

  /* -----------------------------------------------------------
   * 5. Regenerate couple code
   * ----------------------------------------------------------- */
  Future<String> regenerateCoupleCode() async {
    final response = await _client.rpc(
      'regenerate_couple_code_for_current_user',
    );

    // RPC returns the data directly.
    // If there is an error, it throws an exception which is caught by the controller.
    return response as String;
  }
}

final linkingServiceProvider = Provider<LinkingService>((ref) {
  return LinkingService(Supabase.instance.client);
});

// Stores the linking code received from a deep link
final pendingLinkingCodeProvider = StateProvider<String?>((ref) => null);
