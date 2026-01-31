import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// A widget that displays the user's hobbies as chips.
class ProfileHobbiesSection extends StatelessWidget {
  final UserProfile profile;

  const ProfileHobbiesSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Interests & Skills'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: profile.hobbies
                .map(
                  (hobby) => Chip(
                    label: Text(hobby),
                    backgroundColor: const Color(0xFFFFF9C4), // Cream color
                    labelStyle: const TextStyle(color: Color(0xFF4A5D23)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF4A5D23),
        ),
      ),
    );
  }
}
