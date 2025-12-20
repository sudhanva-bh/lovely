import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovely/common/models/user_model.dart';

class ProfileDetailsCard extends StatelessWidget {
  final UserModel user;
  final bool isEditing;
  final DateTime? editedDob;
  final Function(DateTime) onDobChanged;
  // New: Accept a widget for the action button
  final Widget? partnerActionButton;

  const ProfileDetailsCard({
    super.key,
    required this.user,
    required this.isEditing,
    this.editedDob,
    required this.onDobChanged,
    this.partnerActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Birthday Row
          InkWell(
            onTap: isEditing
                ? () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: editedDob ?? DateTime(2000),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) onDobChanged(picked);
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cake_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Birthday",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (isEditing ? editedDob : user.dob) != null
                              ? DateFormat('MMMM dd, yyyy').format(
                                  isEditing ? editedDob! : user.dob,
                                )
                              : "Not set",
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),

          Divider(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            height: 30,
          ),

          // Gender Row
          _buildRow(
            context,
            icon: Icons.transgender_rounded,
            iconColor: theme.colorScheme.secondary,
            bgColor: theme.colorScheme.secondaryContainer,
            label: "Gender",
            value: user.gender,
          ),

          Divider(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            height: 30,
          ),

          // Partner Status Row
          _buildRow(
            context,
            icon: Icons.favorite_rounded,
            iconColor: user.partner != null ? Colors.green : Colors.orange,
            bgColor: user.partner != null ? Colors.green : Colors.orange,
            label: "Partner Status",
            value: user.partner != null ? "Linked" : "Not Linked",
            // Pass the button here
            trailing: partnerActionButton,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    Widget? trailing, // Add trailing widget support
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Render the trailing button if provided
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }
}
