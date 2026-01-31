import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _avatarUrl;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await SupabaseService.getCurrentUserProfile();
      final resume = await SupabaseService.getCurrentUserResume();

      if (mounted) {
        setState(() {
          _userName =
              profile?['name'] ??
              SupabaseService.currentUser?.userMetadata?['name'];
          _avatarUrl = profile?['avatar_url'];

          // Also check resume_data for avatar_url
          if (_avatarUrl == null && resume != null) {
            final resumeData = resume['resume_data'] as Map<String, dynamic>?;
            _avatarUrl = resumeData?['avatar_url'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // User info section
          if (user != null) ...[
            const SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null || _avatarUrl!.isEmpty
                    ? Text(
                        (_userName?.isNotEmpty == true
                            ? _userName![0].toUpperCase()
                            : user.email?[0].toUpperCase() ?? 'U'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(_userName ?? user.userMetadata?['name'] ?? 'User'),
              subtitle: Text(user.email ?? ''),
            ),
            const Divider(),
          ],
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About App'),
            subtitle: const Text('Resume Ranking App v1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Resume Ranking App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Vince Nelmar Alobin',
                children: const [
                  Text(
                    'This app allows users to create, share, and rank resumes. Built with Flutter and Supabase.',
                  ),
                ],
              );
            },
          ),
          const Divider(),
          const Divider(),
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                value: provider.themeMode == ThemeMode.dark,
                onChanged: (val) {
                  provider.toggleTheme(val);
                },
                activeColor: Theme.of(context).colorScheme.primary,
                activeTrackColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.5),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await SupabaseService.signOut();
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/signin',
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
