import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovely/features/setup/controllers/setup_controller.dart';
import 'setup_widgets.dart';

// --- Step 1: Basic Info ---
class StepBasicInfo extends StatelessWidget {
  final SetupController controller;
  const StepBasicInfo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Form(
        key: controller.formKeyStep1,
        child: Column(
          children: [
            const SetupStepHeader(
              imagePath: 'assets/setup/name_and_dob.png',
              title: "Let's get started",
              subtitle: "We just need the basics to set up your profile.",
            ),
            TextFormField(
              initialValue: controller.name,
              style: theme.textTheme.bodyLarge,
              decoration: getSetupInputDecoration(
                context,
                "What's your name?",
                Icons.person_rounded,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Name is required' : null,
              onSaved: (value) => controller.setName(value!),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) controller.setDob(picked);
              },
              child: IgnorePointer(
                child: TextFormField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: controller.dob == null
                        ? ""
                        : DateFormat('MMMM dd, yyyy').format(controller.dob!),
                  ),
                  style: theme.textTheme.bodyLarge,
                  decoration: getSetupInputDecoration(
                    context,
                    "When is your birthday?",
                    Icons.cake_rounded,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Step 2: Gender ---
class StepGender extends StatelessWidget {
  final SetupController controller;
  const StepGender({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SetupStepHeader(
            imagePath: 'assets/setup/select_gender.png',
            title: "You & Your Partner",
            subtitle: "This helps us personalize the app experience.",
          ),
          Text(
            "I am...",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GenderSelector(
            selectedGender: controller.myGender,
            onSelect: controller.setMyGender,
          ),
          const SizedBox(height: 30),
          Text(
            "My partner is...",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GenderSelector(
            selectedGender: controller.partnerGender,
            onSelect: controller.setPartnerGender,
          ),
        ],
      ),
    );
  }
}

// --- Step 3: Avatar ---
class StepAvatar extends StatelessWidget {
  final SetupController controller;
  const StepAvatar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          const SetupStepHeader(
            imagePath: 'assets/setup/profile_picture.png',
            title: "Put a face to the name",
            subtitle: "Add a photo so your partner sees your smiling face.",
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 4,
                    ),
                    image: controller.profileImage != null
                        ? DecorationImage(
                            image: FileImage(controller.profileImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: controller.profileImage == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 80,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: controller.pickImage,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CHANGED: Removed StepPartnerLink class
