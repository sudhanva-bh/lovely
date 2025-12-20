import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovely/common/models/user_model.dart';
import 'package:lovely/common/services/linking_service.dart';
import 'package:lovely/common/services/profile_service.dart';
import 'package:lovely/common/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _profileService;
  final AuthService _authService;
  final LinkingService _linkingService;
  final String _currentUserId;
  String? errorMessage;

  ProfileController({
    required ProfileService profileService,
    required AuthService authService,
    required LinkingService linkingService,
    required String currentUserId,
  }) : _profileService = profileService,
       _authService = authService,
       _linkingService = linkingService,
       _currentUserId = currentUserId;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isLinking = false;
  bool get isLinking => _isLinking;

  // The fully fetched user (with partner nested)
  UserModel? fullUser;

  // State for the Toggle: 'him' or 'her'
  String selectedTab = 'him';

  // Linking State
  String? myCoupleCode;

  // --- Editing State (Only for Self) ---
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  DateTime? dob;
  File? newProfileImage;

  /* ============================================================
   * Dialog Helpers
   * ============================================================ */

  void _showInfoDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Info"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(
    BuildContext context,
    String message, {
    String? title,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title ?? "Warning"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /* ============================================================
   * Derived Getters
   * ============================================================ */

  bool get isCurrentUserSelected {
    if (fullUser == null) return false;
    if (fullUser!.gender == 'Male' && selectedTab == 'him') return true;
    if (fullUser!.gender == 'Female' && selectedTab == 'her') return true;
    return false;
  }

  UserModel? get displayedUser {
    if (fullUser == null) return null;
    final me = fullUser!;
    final partner = fullUser!.partner;

    if (selectedTab == 'him') {
      if (me.gender == 'Male') return me;
      if (partner?.gender == 'Male') return partner;
      return (me.gender != 'Female') ? me : partner;
    } else {
      if (me.gender == 'Female') return me;
      if (partner?.gender == 'Female') return partner;
      return (me.gender != 'Male') ? me : partner;
    }
  }

  /* ============================================================
   * Realtime / Stream Updates
   * ============================================================ */

  void setUser(UserModel user) {
    errorMessage = null;
    final bool isFirstLoad = (fullUser == null);

    fullUser = user;

    if (isFirstLoad) {
      nameController.text = fullUser!.name;
      dob = fullUser!.dob;
      selectedTab = (fullUser!.gender == 'Female') ? 'her' : 'him';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setError(String error) {
    errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  void resetChanges() {
    if (fullUser == null) return;
    nameController.text = fullUser!.name;
    dob = fullUser!.dob;
    newProfileImage = null;
    notifyListeners();
  }

  void switchTab(String tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    notifyListeners();
  }

  /* ============================================================
   * Update Logic
   * ============================================================ */

  void setDob(DateTime newDob) {
    if (!isCurrentUserSelected) return;
    dob = newDob;
    notifyListeners();
  }

  Future<void> pickImage() async {
    if (!isCurrentUserSelected) return;

    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      newProfileImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> saveProfile(BuildContext context) async {
    if (!isCurrentUserSelected) return;
    if (!formKey.currentState!.validate()) return;
    if (dob == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      String profileUrl = fullUser!.profilePictureURL;

      if (newProfileImage != null) {
        profileUrl = await _profileService.uploadProfilePicture(
          _currentUserId,
          newProfileImage!,
        );
      }

      final updatedUser = fullUser!.copyWith(
        name: nameController.text.trim(),
        dob: dob,
        profilePictureURL: profileUrl,
      );

      await _profileService.saveProfile(updatedUser);

      fullUser = updatedUser;
      newProfileImage = null;

      if (context.mounted) {
        _showInfoDialog(context, "Profile updated successfully!");
      }
    } catch (e) {
      if (context.mounted) {
        _showWarningDialog(context, "Failed to save profile.\n$e");
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /* ============================================================
   * Linking Logic
   * ============================================================ */

  Future<void> fetchMyCode() async {
    try {
      myCoupleCode = await _linkingService.getCoupleCode();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching code: $e");
    }
  }

  Future<void> regenerateCode(BuildContext context) async {
    try {
      myCoupleCode = null;
      notifyListeners();

      myCoupleCode = await _linkingService.regenerateCoupleCode();
    } catch (e) {
      if (context.mounted) {
        _showWarningDialog(context, "Error regenerating code.\n$e");
      }
    } finally {
      notifyListeners();
    }
  }

  Future<bool> linkPartner(BuildContext context, String code) async {
    if (code.trim().isEmpty) return false;

    _isLinking = true;
    notifyListeners();

    try {
      await _linkingService.linkByCode(code.trim());

      if (context.mounted) {
        _showInfoDialog(
          context,
          "Linked successfully! Congratulations 🎉",
        );
        Navigator.of(context).pop();
      }
      return true;
    } on PostgrestException catch (e) {
      if (context.mounted) {
        _showWarningDialog(
          context,
          "${e.message}\nMake sure you have entered the correct Partner Code",
          title: "Linking Failed",
        );
      }
      print(e);
      return false;
    } catch (e) {
      if (context.mounted) {
        _showWarningDialog(context, "Linking failed.\n$e");
      }
      print(e);
      return false;
    } finally {
      _isLinking = false;
      notifyListeners();
    }
  }

  /* ============================================================
   * Sign Out Logic
   * ============================================================ */

  Future<void> signOut(BuildContext context) async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (context.mounted) {
        _showWarningDialog(context, "Error signing out.\n$e");
      }
    }
  }
}
