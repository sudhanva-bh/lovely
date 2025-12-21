import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/models/user_model.dart';
import 'package:lovely/common/services/notification_service.dart';
import 'package:lovely/common/services/profile_service.dart';
import 'package:lovely/common/services/auth_service.dart';
import 'package:lovely/common/services/linking_service.dart';
import 'package:lovely/common/theme/app_theme.dart';
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
    final notificationService = ref.read(
      notificationServiceProvider,
    ); // Add provider import if needed

    _controller = ProfileController(
      profileService: profileService,
      authService: authService,
      linkingService: linkingService,
      notificationService: notificationService, // Pass it here
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
        // 1. Determine Theme based on Selected Tab
        // "Him" -> Blue (Male theme), "Her" -> Pink (Female/Default theme)
        final pageTheme = _controller.selectedTab == 'him'
            ? AppTheme.getThemeForGender('Male')
            : AppTheme.getThemeForGender('Female');

        return Theme(
          data: pageTheme,
          child: Builder(
            builder: (context) {
              // Re-fetch theme from context to ensure downstream widgets use the override
              final theme = Theme.of(context);
              final user = _controller.displayedUser;
              final isMe = _controller.isCurrentUserSelected;

              if (!isMe && _isEditing) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _isEditing = false);
                });
              }

              if (_controller.isLoading) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (_controller.errorMessage != null) {
                return Scaffold(
                  body: Center(
                    child: Text("Error: ${_controller.errorMessage}"),
                  ),
                );
              }

              if (user == null) {
                return const Scaffold(
                  body: Center(child: Text("No profile data found.")),
                );
              }

              return Scaffold(
                backgroundColor: theme.colorScheme.surface,
                body: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeaderStack(context, user, isMe),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            // Name Section
                            _buildNameSection(
                              context,
                              user,
                              isMe && _isEditing,
                            ),

                            const SizedBox(height: 32),

                            // Details Card
                            ProfileDetailsCard(
                              user: user,
                              isMe: isMe,
                              isEditing: isMe && _isEditing,
                              editedDob: _controller.dob,
                              onDobChanged: _controller.setDob,
                              partnerActionButton: _buildPartnerActionButton(
                                context,
                                isMe,
                                user,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Action Buttons (Edit / Sign Out)
                            // Only show if it's the current user's profile
                            if (isMe) _buildActionButtons(context, theme),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeaderStack(BuildContext context, UserModel user, bool isMe) {
    final theme = Theme.of(context);

    // Only show toggle if a partner exists
    final showToggle = _controller.fullUser?.partner != null;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // 1. Gradient Background Container
        Container(
          height: 280,
          width: double.infinity,
          margin: const EdgeInsets.only(
            bottom: 60,
          ), // Space for avatar half-overhang
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.tertiary,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Custom Top Bar with Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Toggle (Hidden if no partner)
                      if (showToggle)
                        ProfileToggle(
                          selectedTab: _controller.selectedTab,
                          onTabChanged: _controller.switchTab,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Avatar Floating in the middle
        Positioned(
          bottom: 0,
          child: ProfileAvatar(
            profileUrl: user.profilePictureURL,
            newImageFile: _controller.newProfileImage,
            isEditing: isMe && _isEditing,
            onPickImage: _controller.pickImage,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme) {
    // Shared button style
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    if (_isEditing) {
      // --- Editing Mode: Cancel | Save ---
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _toggleEdit,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.outline),
                shape: buttonShape,
              ),
              child: const Text("Cancel"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: _controller.isSaving ? null : _handleSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: buttonShape,
                elevation: 4,
                shadowColor: theme.colorScheme.primary.withOpacity(0.4),
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
      );
    } else {
      // --- View Mode: Edit | Sign Out (Side by Side) ---
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text("Edit"),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.5),
                foregroundColor: theme.colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: buttonShape,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _controller.signOut(context),
              icon: Icon(
                Icons.logout_rounded,
                size: 18,
                color: theme.colorScheme.error,
              ),
              label: Text(
                "Sign Out",
                style: TextStyle(
                  color: theme.colorScheme.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: theme.colorScheme.error.withOpacity(0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: buttonShape,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget? _buildPartnerActionButton(
    BuildContext context,
    bool isMe,
    UserModel user,
  ) {
    if (!isMe) return null;

    final theme = Theme.of(context);

    if (user.partner == null) {
      return FilledButton.icon(
        onPressed: () => _showLinkPartnerDialog(context),
        icon: const Icon(Icons.link_rounded, size: 16),
        label: const Text("Link"),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => _controller.unlinkPartner(context),
        icon: const Icon(Icons.link_off_rounded, size: 16),
        label: const Text("Unlink"),
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: theme.colorScheme.error,
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
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
        child: TextFormField(
          controller: _controller.nameController,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: "Your Name",
            border: InputBorder.none,
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Name is required' : null,
        ),
      );
    }
    return Column(
      children: [
        Text(
          user.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        // Removed the "Single/Taken" badge
      ],
    );
  }
}
