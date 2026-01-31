import 'package:flutter/material.dart';
import '../../../models/models.dart';

/// A widget that displays the user's bio and contact information.
class ProfileInfoSection extends StatelessWidget {
  final UserProfile profile;

  const ProfileInfoSection({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'About Me'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                profile.bio,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Contact Information'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email, color: Color(0xFF88B04B)),
                  title: Text(profile.email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone, color: Color(0xFF88B04B)),
                  title: Text(profile.phone),
                ),
              ],
            ),
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
