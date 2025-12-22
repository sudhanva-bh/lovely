import 'package:flutter/material.dart';

void showToast(
  BuildContext context,
  String title, {
  String? body,
  String? imageUrl,
}) {
  OverlayEntry? overlayEntry;
  // Track if the entry is currently in the tree to prevent double-removal errors
  bool isEntryMounted = false;

  // Helper to remove the overlay safely
  void removeToast() {
    if (isEntryMounted && overlayEntry != null) {
      overlayEntry.remove();
      isEntryMounted = false;
    }
  }

  // Define the entry
  overlayEntry = OverlayEntry(
    builder: (context) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final textTheme = theme.textTheme;

      return Positioned(
        top: MediaQuery.of(context).padding.top + 12, // Safe area + padding
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: -150, end: 0), // Slide down from above
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack, // Bouncy effect
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            // WRAP CONTENT IN DISMISSIBLE
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.up,
              onDismissed: (_) {
                // Remove immediately when swiped
                removeToast();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Use surface color with a high elevation style
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Leading Icon / Image ---
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_rounded,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),

                    // --- Text Content ---
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (body != null && body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              body,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // --- Visual Swipe Indicator (Optional) ---
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  // Insert into overlay
  Overlay.of(context).insert(overlayEntry);
  isEntryMounted = true;

  // Remove automatically after 4 seconds (if not already swiped)
  Future.delayed(const Duration(seconds: 4), () {
    removeToast();
  });
}
