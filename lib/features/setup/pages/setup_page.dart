import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lovely/common/services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lovely/features/setup/controllers/setup_controller.dart';
import 'package:lovely/features/setup/widgets/setup_steps.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  late final SetupController _controller;

  @override
  void initState() {
    super.initState();
    final profileService = ref.read(profileServiceProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) {
      // Handle unauthenticated state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(); 
      });
       _controller = SetupController(profileService: profileService, userId: '');
       return;
    }

    _controller = SetupController(
      profileService: profileService,
      userId: userId,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final progressValue =
            (_controller.currentPage + 1) / _controller.totalPages;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            backgroundColor: colorScheme.surface,
            elevation: 0,
            leading: _controller.currentPage > 0
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colorScheme.onSurface,
                    ),
                    onPressed: _controller.previousPage,
                  )
                : null,
            title: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "Step ${_controller.currentPage + 1}/${_controller.totalPages}",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _controller.pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        StepBasicInfo(controller: _controller),
                        StepGender(controller: _controller),
                        StepAvatar(controller: _controller),
                        // CHANGED: Removed StepPartnerLink
                      ],
                    ),
                  ),

                  // Bottom Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _controller.isLoading 
                          ? null 
                          : () => _controller.nextPage(context),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _controller.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _controller.currentPage ==
                                          _controller.totalPages - 1
                                      ? "Start Loving"
                                      : "Continue",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _controller.currentPage ==
                                          _controller.totalPages - 1
                                      ? Icons.favorite_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  // CHANGED: Removed the "Skip & Setup Later" button block
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}