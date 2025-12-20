import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lovely/common/models/user_model.dart';
import 'package:lovely/common/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupController extends ChangeNotifier {
  final ProfileService _profileService;
  final String _userId;

  SetupController({
    required ProfileService profileService,
    required String userId,
  }) : _profileService = profileService,
       _userId = userId;

  final PageController pageController = PageController();
  final GlobalKey<FormState> formKeyStep1 = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  int _currentPage = 0;
  int get currentPage => _currentPage;
  // CHANGED: Reduced to 3 steps (Basic Info, Gender, Avatar)
  int get totalPages => 3;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Form Data
  String name = '';
  DateTime? dob;
  String myGender = '';
  String partnerGender = '';
  File? profileImage;
  // CHANGED: Removed partnerCode

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // --- Setters ---
  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setDob(DateTime value) {
    dob = value;
    notifyListeners();
  }

  void setMyGender(String value) {
    myGender = value;
    notifyListeners();
  }

  void setPartnerGender(String value) {
    partnerGender = value;
    notifyListeners();
  }

  // CHANGED: Removed setPartnerCode

  // --- Image Picking ---
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        profileImage = File(pickedFile.path);
        notifyListeners();
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  // --- Logic ---
  void nextPage(BuildContext context) {
    FocusScope.of(context).unfocus();

    // Validation Logic
    if (_currentPage == 0) {
      if (!formKeyStep1.currentState!.validate()) return;
      formKeyStep1.currentState!.save();

      if (dob == null) {
        _showError(context, "Please select your date of birth");
        return;
      }
    } else if (_currentPage == 1) {
      if (myGender.isEmpty || partnerGender.isEmpty) {
        _showError(context, "Please select both genders");
        return;
      }
    }

    // Navigation
    if (_currentPage < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubicEmphasized,
      );
      _currentPage++;
      notifyListeners();
    } else {
      submitData(context);
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubicEmphasized,
      );
      _currentPage--;
      notifyListeners();
    }
  }

  Future<void> submitData(BuildContext context) async {
    _setLoading(true);

    try {
      String profilePicUrl = '';

      // 1. Upload Image if selected
      if (profileImage != null) {
        profilePicUrl = await _profileService.uploadProfilePicture(
          _userId,
          profileImage!,
        );
      }

      // CHANGED: Removed Partner User logic

      // 2. Create User Model
      final user = UserModel(
        uid: _userId,
        name: name,
        dob: dob!,
        gender: myGender,
        profilePictureURL: profilePicUrl,
        partner: null, // CHANGED: Always null now
      );

      // 3. Save to DB
      await _profileService.saveProfile(user);

      // 4. Update Auth Metadata
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'hasCompletedSetup': true},
        ),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Setup Complete!")),
        );

        context.go('/');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, "Setup failed: $e");
      }
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}