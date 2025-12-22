import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PresetNotificationService {
  PresetNotificationService(this._supabase);

  final SupabaseClient _supabase;

  /// Notify partner when profiles are linked
  Future<void> notifyOnLink({
    required String recipientUid,
  }) async {
    await _supabase.rpc(
      'notify_on_link',
      params: {'recipient_uid': recipientUid},
    );
  }

  Future<void> notifyOnUnlink(String recipientUid) async {
    await _supabase.rpc(
      'notify_on_unlink',
      params: {'recipient_uid': recipientUid},
    );
  }
}

final presetNotificationServiceProvider = Provider<PresetNotificationService>((
  ref,
) {
  return PresetNotificationService(
    Supabase.instance.client,
  );
});
