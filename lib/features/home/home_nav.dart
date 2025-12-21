import 'dart:ui'; // Required for ImageFilter
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:lovely/common/utils/toast.dart';
import 'package:lovely/features/profile/pages/profile_page.dart';
// Import services to access the pendingLinkingCodeProvider
import 'package:lovely/common/services/linking_service.dart';

/// ------------------------------------------------------------
/// RIVERPOD PROVIDER — GLOBAL NAVIGATION STATE
/// ------------------------------------------------------------
final homeNavIndexProvider = StateProvider<int>((ref) => 0);

class HomeNav extends ConsumerStatefulWidget {
  final int initialIndex;
  final String? linkingCode; 

  const HomeNav({
    super.key, 
    this.initialIndex = 0,
    this.linkingCode, 
  });

  @override
  ConsumerState<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends ConsumerState<HomeNav> {
  @override
  void initState() {
    super.initState();

    // 1. Handle initial index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != 0) {
        ref.read(homeNavIndexProvider.notifier).state = widget.initialIndex;
      }
      // 2. Handle deep link if present at launch
      _processLinkingCode();
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showToast(
          context,
          message.notification!.body ?? 'New Notification',
        );
      }
    });
  }

  // 3. Handle new deep links while app is running
  @override
  void didUpdateWidget(HomeNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.linkingCode != oldWidget.linkingCode) {
       _processLinkingCode();
    }
  }

  void _processLinkingCode() {
    final code = widget.linkingCode;
    
    // Only proceed if there is actually a code
    if (code != null && code.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // A. Switch to Profile Tab (Index 4)
        ref.read(homeNavIndexProvider.notifier).state = 4;
        
        // B. Set the global provider so ProfilePage sees it
        ref.read(pendingLinkingCodeProvider.notifier).state = code;

        // C. CRITICAL FIX: Clear the URL!
        // We replace the current route with '/' so that if the user clicks 
        // the link again, GoRouter sees it as a NEW change.
        if (mounted) {
          context.replace('/');
        }
      });
    }
  }

  // Original Pages
  final List<Widget> _pages = [
    const Center(child: Text('Home', style: TextStyle(fontSize: 30))),
    const Center(child: Text('Search', style: TextStyle(fontSize: 30))),
    const Center(child: Text('Story', style: TextStyle(fontSize: 30))),
    const Center(child: Text('Chat', style: TextStyle(fontSize: 30))),
    const ProfilePage(),
  ];

  void _onNavTap(int index) {
    HapticFeedback.lightImpact();
    ref.read(homeNavIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for changes
    final currentIndex = ref.watch(homeNavIndexProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // block automatic popping
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // system already popped, do nothing

        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Do you want to close the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (!context.mounted) return;

        if (confirm == true) {
          // Effectively exit the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: FadeIndexedStack(
          index: currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(80),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(Icons.home_rounded, 'Home', 0, currentIndex),
                    _buildNavItem(
                      Icons.search_rounded,
                      'Search',
                      1,
                      currentIndex,
                    ),
                    _buildNavItem(
                      Icons.menu_book_rounded,
                      'Story',
                      2,
                      currentIndex,
                    ),
                    _buildNavItem(Icons.chat_rounded, 'Chat', 3, currentIndex),
                    _buildNavItem(
                      Icons.person_rounded,
                      'Profile',
                      4,
                      currentIndex,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the icons
  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final bool isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(
                0,
                isSelected ? -2 : 0,
                0,
              ),
              child: Icon(
                icon,
                size: 26,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// CUSTOM FADE INDEXED STACK
/// ------------------------------------------------------------
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: widget.children.asMap().entries.map((entry) {
        final int i = entry.key;
        final Widget child = entry.value;
        final bool isActive = i == widget.index;

        return IgnorePointer(
          ignoring: !isActive,
          child: AnimatedOpacity(
            duration: widget.duration,
            curve: Curves.easeInOut,
            opacity: isActive ? 1.0 : 0.0,
            child: child,
          ),
        );
      }).toList(),
    );
  }
}