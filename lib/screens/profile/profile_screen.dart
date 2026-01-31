import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';

import '../../services/supabase_service.dart';
import 'widgets/profile_info_section.dart';
import 'widgets/profile_hobbies_section.dart';
import 'widgets/profile_project_list.dart';
import 'widgets/profile_sliver_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _fetchedProfile;
  bool _isLoading = true;
  String? _avatarUrl;
  String? _backgroundUrl;

  @override
  void initState() {
    super.initState();
    _loadOwnProfile();
  }

  Future<void> _loadOwnProfile() async {
    final currentUser = SupabaseService.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch the user's resume from Supabase
      final resumeData = await SupabaseService.getUserResume(currentUser.id);

      if (resumeData != null && mounted) {
        final data = resumeData['resume_data'] as Map<String, dynamic>? ?? {};
        setState(() {
          // Load avatar URL from resume data
          _avatarUrl = data['avatar_url']?.toString();
          _backgroundUrl = data['background_url']?.toString();

          _fetchedProfile = UserProfile(
            id: currentUser.id,
            name:
                data['name']?.toString() ??
                currentUser.email?.split('@').first ??
                'User',
            bio: resumeData['content']?.toString() ?? '',
            email: data['email']?.toString() ?? currentUser.email ?? '',
            phone: data['phone']?.toString() ?? '',
            hobbies:
                (data['hobbies'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
            projects:
                (data['projects'] as List<dynamic>?)
                    ?.map((e) => Project.fromJson(e))
                    .toList() ??
                [],
            imagePath: _avatarUrl ?? '',
            backgroundImagePath: _backgroundUrl ?? '',
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getAvatarImage(String imagePath) {
    // Check if it's a URL (from Supabase storage)
    if (imagePath.isNotEmpty && imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
    // Default avatar (null to trigger Initials/Icon in AppBar)
    return null;
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/signin');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if viewing someone else's resume
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Resume? resume = args?['resume'] as Resume?;
    final bool isOwner = args?['isOwner'] as bool? ?? true;

    // Show loading indicator while fetching own profile
    if (_isLoading && resume == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build profile from resume data or current user's profile
    UserProfile displayProfile;
    if (resume != null) {
      // Create a profile from resume data (viewing someone else's)
      final resumeData = resume.resumeData;
      final otherAvatarUrl = resumeData['avatar_url']?.toString() ?? '';
      final otherBackgroundUrl = resumeData['background_url']?.toString() ?? '';
      displayProfile = UserProfile(
        id: resume.userId,
        name: resume.userName,
        bio: resume.content,
        email: resumeData['email']?.toString() ?? '',
        phone: resumeData['phone']?.toString() ?? '',
        hobbies:
            (resumeData['hobbies'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        projects:
            (resumeData['projects'] as List<dynamic>?)
                ?.map((e) => Project.fromJson(e))
                .toList() ??
            [],
        imagePath: otherAvatarUrl,
        backgroundImagePath: otherBackgroundUrl,
      );
    } else if (_fetchedProfile != null) {
      // Use profile fetched from Supabase
      displayProfile = _fetchedProfile!;
    } else {
      // Fallback to AppProvider
      displayProfile = context.watch<AppProvider>().userProfile;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ProfileSliverAppBar(
            profile: displayProfile,
            isOwner: isOwner,
            onShowQRCode: () => _showQRCode(context, displayProfile),
            onLogout: () => _showLogoutDialog(context),
            avatarImage: _getAvatarImage(displayProfile.imagePath),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ProfileInfoSection(profile: displayProfile),
              const SizedBox(height: 20),
              ProfileHobbiesSection(profile: displayProfile),
              const SizedBox(height: 20),
              ProfileProjectList(
                title: 'Projects',
                projects: displayProfile.projects,
              ),
              const SizedBox(height: 80), // Space for FAB
            ]),
          ),
        ],
      ),
      // Only show Edit Profile FAB if viewing your own profile
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            )
          : null,
    );
  }

  void _showQRCode(BuildContext context, UserProfile profile) {
    // Generate QR data with profile info
    final qrData =
        '''
VCARD:
NAME:${profile.name}
EMAIL:${profile.email}
TEL:${profile.phone}
BIO:${profile.bio}
''';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'My Profile QR',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan to get my contact info',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF4A5D23),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF4A5D23),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                profile.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                profile.email,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
