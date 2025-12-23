import 'package:flutter/foundation.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppIconService {
  /// Switches the app icon and label.
  /// [isDisguised] = true -> Calculator Icon & Name
  /// [isDisguised] = false -> Lovely Icon & Name (Default)
  Future<void> setDisguise(bool isDisguised) async {
    // Web doesn't support dynamic icons
    if (kIsWeb) return;

    try {
      if (await FlutterDynamicIcon.supportsAlternateIcons) {
        if (isDisguised) {
          // Activates the <activity-alias android:name=".CalculatorAlias" ... />
          await FlutterDynamicIcon.setAlternateIconName("CalculatorAlias");
        } else {
          // Resets to the default <activity android:name=".MainActivity" ... />
          await FlutterDynamicIcon.setAlternateIconName(null);
        }
        debugPrint(
          "App Icon changed to: ${isDisguised ? 'Calculator' : 'Lovely'}",
        );
      }
    } catch (e) {
      debugPrint("Failed to change app icon: $e");
    }
  }
}

final appIconServiceProvider = Provider<AppIconService>((ref) {
  return AppIconService();
});
