import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/models/user_model.dart';
import 'package:lovely/common/services/profile_service.dart';
import 'package:lovely/common/services/auth_service.dart';
import 'package:lovely/common/services/linking_service.dart';
import 'package:lovely/features/linking/link_partner_dialog.dart';
import 'package:lovely/features/profile/controllers/profile_controller.dart';
import 'package:lovely/features/profile/widgets/profile_avatar.dart';
import 'package:lovely/features/profile/widgets/profile_details_card.dart';
import 'package:lovely/features/profile/widgets/profile_toggle.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final ProfileController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profileService = ref.read(profileServiceProvider);
    final authService = ref.read(authServiceProvider);
    final linkingService = ref.read(linkingServiceProvider);
    final userId = ref.read(currentUserUidProvider);

    _controller = ProfileController(
      profileService: profileService,
      authService: authService,
      linkingService: linkingService,
      currentUserId: userId ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      _controller.resetChanges();
    });
  }

  Future<void> _handleSave() async {
    await _controller.saveProfile(context);
    if (mounted && !_controller.isSaving) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  void _showLinkPartnerDialog(BuildContext context, {String? initialCode}) {
    _controller.fetchMyCode();
    showDialog(
      context: context,
      builder: (context) => LinkPartnerDialog(
        controller: _controller,
        initialCode: initialCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userProfileStreamProvider);

    ref.listen(pendingLinkingCodeProvider, (previous, next) {
      if (next != null) {
        ref.read(pendingLinkingCodeProvider.notifier).state = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showLinkPartnerDialog(context, initialCode: next);
          }
        });
      }
    });

    ref.listen(userProfileStreamProvider, (previous, next) {
      next.when(
        data: (user) => _controller.setUser(user),
        error: (e, stack) => _controller.setError(e.toString()),
        loading: () {},
      );
    });

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final theme = Theme.of(context);
        final user = _controller.displayedUser;
        final isMe = _controller.isCurrentUserSelected;

        if (!isMe && _isEditing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isEditing = false);
          });
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: ProfileToggle(
              selectedTab: _controller.selectedTab,
              onTabChanged: _controller.switchTab,
            ),
          ),
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.errorMessage != null
              ? Center(child: Text("Error: ${_controller.errorMessage}"))
              : user == null
              ? const Center(child: Text("No profile data found."))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      ProfileAvatar(
                        profileUrl: user.profilePictureURL,
                        newImageFile: _controller.newProfileImage,
                        isEditing: isMe && _isEditing,
                        onPickImage: _controller.pickImage,
                      ),
                      const SizedBox(height: 20),
                      _buildNameSection(context, user, isMe && _isEditing),
                      const SizedBox(height: 40),

                      // --- DETAILS CARD WITH ACTION BUTTON ---
                      ProfileDetailsCard(
                        user: user,
                        isEditing: isMe && _isEditing,
                        editedDob: _controller.dob,
                        onDobChanged: _controller.setDob,
                        // Pass the button logic here
                        partnerActionButton: _buildPartnerActionButton(
                          context,
                          isMe,
                          user,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // --- Edit / Save Controls ---
                      if (isMe) ...[
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _toggleEdit,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.outline,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _controller.isSaving
                                      ? null
                                      : _handleSave,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _controller.isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text("Save Changes"),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _toggleEdit,
                              icon: const Icon(Icons.edit_rounded, size: 20),
                              label: const Text("Edit Profile"),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                foregroundColor: theme.colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                      ],

                      // --- Sign Out Button ---
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () => _controller.signOut(context),
                          icon: Icon(
                            Icons.logout_rounded,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            "Sign Out",
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// Builds the "Link" or "Unlink" button to sit inside the card
  Widget? _buildPartnerActionButton(
    BuildContext context,
    bool isMe,
    UserModel user,
  ) {
    if (!isMe) return null; // Only show for current user

    final theme = Theme.of(context);

    if (user.partner == null) {
      // 1. Link Button
      return FilledButton(
        onPressed: () => _showLinkPartnerDialog(context),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text("Link"),
      );
    } else {
      // 2. Unlink Button
      return OutlinedButton(
        onPressed: () => _controller.unlinkPartner(context),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: const Text("Unlink"),
      );
    }
  }

  Widget _buildNameSection(
    BuildContext context,
    UserModel user,
    bool isEditing,
  ) {
    final theme = Theme.of(context);
    if (isEditing) {
      return Form(
        key: _controller.formKey,
        child: SizedBox(
          width: 250,
          child: TextFormField(
            controller: _controller.nameController,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            decoration: const InputDecoration(
              hintText: "Your Name",
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black12),
              ),
            ),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Name is required' : null,
          ),
        ),
      );
    }
    return Text(
      user.name,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }
}
