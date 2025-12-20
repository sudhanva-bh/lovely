import 'dart:io';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profileUrl;
  final File? newImageFile;
  final bool isEditing;
  final VoidCallback onPickImage;

  const ProfileAvatar({
    super.key,
    required this.profileUrl,
    this.newImageFile,
    required this.isEditing,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ImageProvider? imageProvider;

    if (isEditing && newImageFile != null) {
      imageProvider = FileImage(newImageFile!);
    } else if (profileUrl != null && profileUrl!.isNotEmpty) {
      imageProvider = NetworkImage(profileUrl!);
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border.all(color: theme.colorScheme.surface, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: imageProvider != null
                  ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: imageProvider == null
                ? Icon(
                    Icons.person_rounded,
                    size: 70,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          if (isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: onPickImage,
                child: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.surface, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}