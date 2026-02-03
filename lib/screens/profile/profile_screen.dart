import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';

import '../../services/supabase_service.dart';
import 'widgets/profile_info_section.dart';
import 'widgets/profile_hobbies_section.dart';
import 'widgets/profile_project_list.dart';
import '../chat/chat_screen.dart';
import 'widgets/profile_sliver_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _fetchedProfile;
  bool _isLoading = true;

  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkArguments();
  }

  Future<void> _checkArguments() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String? userId = args?['userId'] as String?;
    final bool isOwner = args?['isOwner'] as bool? ?? true;

    // Only load if we haven't loaded yet or if we are switching users
    if (!isOwner && userId != null && _fetchedProfile?.id != userId) {
      _loadProfile(userId);
    } else if (isOwner && _fetchedProfile == null) {
      _loadProfile(null);
    }
  }

  Future<void> _loadProfile(String? targetUserId) async {
    final currentUser = SupabaseService.currentUser;
    final userId = targetUserId ?? currentUser?.id;

    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      if (mounted) setState(() => _isLoading = true);

      // Try to fetch resume first
      final resumeData = await SupabaseService.getUserResume(userId);

      if (resumeData != null) {
        final data = resumeData['resume_data'] as Map<String, dynamic>? ?? {};
        final fetchedProfile = UserProfile(
          id: userId,
          name: data['name']?.toString() ?? 'User',
          bio: resumeData['content']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
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
          imagePath: data['avatar_url']?.toString() ?? '',
          backgroundImagePath: data['background_url']?.toString() ?? '',
        );

        if (mounted) {
          setState(() {
            _fetchedProfile = fetchedProfile;
            _isLoading = false;
          });
        }
      } else {
        // Fallback to basic profile if no resume
        final profileData = await SupabaseService.getUserProfile(userId);
        if (profileData != null) {
          final fetchedProfile = UserProfile(
            id: userId,
            name: profileData['name'] ?? 'User',
            bio: profileData['bio'] ?? '',
            email: profileData['email'] ?? '',
            phone: profileData['phone'] ?? '',
            imagePath: profileData['avatar_url'] ?? '',
            hobbies:
                (profileData['hobbies'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
          );
          if (mounted) {
            setState(() {
              _fetchedProfile = fetchedProfile;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getAvatarImage(String imagePath) {
    if (imagePath.isNotEmpty && imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
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
                Navigator.popUntil(context, (route) => route.isFirst);
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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final Resume? resume = args?['resume'] as Resume?;
    final bool isOwner = args?['isOwner'] as bool? ?? true;

    // Build profile from resume data, fetched profile, or current user
    UserProfile displayProfile;
    if (resume != null) {
      final resumeData = resume.resumeData;
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
        imagePath: resumeData['avatar_url']?.toString() ?? '',
        backgroundImagePath: resumeData['background_url']?.toString() ?? '',
      );
    } else if (_fetchedProfile != null) {
      displayProfile = _fetchedProfile!;
    } else {
      displayProfile = context.watch<AppProvider>().userProfile;
    }

    if (_isLoading && _fetchedProfile == null && !isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
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
              const SizedBox(height: 80),
            ]),
          ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            )
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: displayProfile.id,
                      otherUserName: displayProfile.name,
                      otherUserAvatar: displayProfile.imagePath,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
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
