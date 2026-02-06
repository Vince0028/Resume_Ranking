import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import 'widgets/project_editor_dialog.dart';
import 'widgets/location_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _hobbiesController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  List<Project> _projects = [];
  String _imagePath = '';
  String _backgroundImagePath = '';
  double? _latitude;
  double? _longitude;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize with empty controllers first
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _hobbiesController = TextEditingController();

    // Load actual user data from database
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final currentUser = SupabaseService.currentUser;
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Fetch both profile and resume data in parallel or sequence
      final profile = await SupabaseService.getCurrentUserProfile();
      final resumeData = await SupabaseService.getUserResume(currentUser.id);

      if (mounted) {
        setState(() {
          if (profile != null) {
            _nameController.text = profile['name'] ?? '';
            _bioController.text = profile['bio'] ?? '';
            _emailController.text = profile['email'] ?? currentUser.email ?? '';
            _phoneController.text = profile['phone'] ?? '';
            final hobbies = profile['hobbies'] as List<dynamic>?;
            _hobbiesController.text = hobbies?.join(', ') ?? '';
            _imagePath = profile['avatar_url'] ?? '';
            _latitude = (profile['latitude'] as num?)?.toDouble();
            _longitude = (profile['longitude'] as num?)?.toDouble();
          } else {
            // New user - set email from auth
            _emailController.text = currentUser.email ?? '';
            _nameController.text = currentUser.userMetadata?['name'] ?? '';
          }

          // Load projects from resume data
          if (resumeData != null) {
            final data =
                resumeData['resume_data'] as Map<String, dynamic>? ?? {};
            _projects =
                (data['projects'] as List<dynamic>?)
                    ?.map((e) => Project.fromJson(e))
                    .toList() ??
                [];
            // Load image URLs from resume data if available
            if (_imagePath.isEmpty && data['avatar_url'] != null) {
              _imagePath = data['avatar_url'] as String? ?? '';
            }
            if (data['background_url'] != null) {
              _backgroundImagePath = data['background_url'] as String? ?? '';
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailController.text = currentUser.email ?? '';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hobbiesController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Store image bytes for cross-platform display
  Uint8List? _imageBytes;
  Uint8List? _backgroundBytes;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      debugPrint('📷 Picked image path: ${pickedFile.path}');

      // Compress image
      final Uint8List? bytes = await FlutterImageCompress.compressWithFile(
        pickedFile.path,
        minWidth: 512,
        minHeight: 512,
        quality: 70,
      );

      if (bytes != null) {
        setState(() {
          _imagePath = pickedFile.path;
          _imageBytes = bytes;
        });
      }
    }
  }

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      debugPrint('🖼️ Picked background path: ${pickedFile.path}');

      // Compress image
      final Uint8List? bytes = await FlutterImageCompress.compressWithFile(
        pickedFile.path,
        minWidth: 1920,
        minHeight: 1080,
        quality: 70,
      );

      if (bytes != null) {
        setState(() {
          _backgroundImagePath = pickedFile.path;
          _backgroundBytes = bytes;
        });
      }
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Save Changes?'),
          content: const Text('Are you sure you want to update your profile?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Show loading indicator
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingCtx) => const AlertDialog(
                    content: Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 20),
                        Text('Saving profile...'),
                      ],
                    ),
                  ),
                );

                try {
                  final hobbiesList = _hobbiesController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  final currentUser = SupabaseService.currentUser;
                  if (currentUser == null) {
                    throw Exception('Not logged in');
                  }

                  // Upload avatar if we have bytes (works on web and mobile)
                  String? avatarUrl = _imagePath.startsWith('http')
                      ? _imagePath
                      : '';
                  if (_imageBytes != null) {
                    final uploadedUrl = await SupabaseService.uploadAvatarBytes(
                      _imageBytes!,
                    );
                    if (uploadedUrl != null) {
                      avatarUrl = uploadedUrl;
                      _imagePath = uploadedUrl; // Update local state
                      _imageBytes =
                          null; // Clear bytes to indicate it's uploaded
                    }
                  } else if (_imagePath.startsWith('http')) {
                    avatarUrl = _imagePath; // Keep existing URL
                  }

                  // Upload background if we have bytes
                  String? backgroundUrl =
                      _backgroundImagePath.startsWith('http')
                      ? _backgroundImagePath
                      : '';
                  if (_backgroundBytes != null) {
                    final uploadedUrl =
                        await SupabaseService.uploadBackgroundBytes(
                          _backgroundBytes!,
                        );
                    if (uploadedUrl != null) {
                      backgroundUrl = uploadedUrl;
                      _backgroundImagePath = uploadedUrl; // Update local state
                      _backgroundBytes =
                          null; // Clear bytes to indicate it's uploaded
                    }
                  } else if (_backgroundImagePath.startsWith('http')) {
                    backgroundUrl = _backgroundImagePath; // Keep existing URL
                  }

                  // Save to Supabase database
                  await SupabaseService.updateProfile(
                    name: _nameController.text,
                    bio: _bioController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
                    hobbies: hobbiesList,
                    latitude: _latitude,
                    longitude: _longitude,
                  );

                  // Also create/update the resume entry for the leaderboard
                  await SupabaseService.submitResume(
                    userId: currentUser.id,
                    title: hobbiesList.isNotEmpty
                        ? hobbiesList.first
                        : 'Professional',
                    content: _bioController.text,
                    resumeData: {
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                      'hobbies': hobbiesList,
                      'projects': _projects.map((p) => p.toJson()).toList(),
                      'avatar_url': avatarUrl,
                      'background_url': backgroundUrl,
                    },
                  );

                  // Also update local AppProvider (use empty profile as base for non-Vince users)
                  final newProfile = UserProfile(
                    id: currentUser.id,
                    name: _nameController.text,
                    bio: _bioController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    imagePath: _imagePath,
                    backgroundImagePath: _backgroundImagePath,
                    hobbies: hobbiesList,
                    projects: _projects,
                  );
                  context.read<AppProvider>().updateUserProfile(newProfile);

                  // Update password if provided
                  if (_newPasswordController.text.isNotEmpty) {
                    await _updatePassword();
                  }

                  // Note: Skipping Supabase Auth email update to avoid validation errors
                  // The email is stored in the profile/resume data instead

                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    Navigator.pop(context); // Go back to previous screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Profile saved successfully! Your resume is now on the leaderboard.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating profile: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      throw Exception('Please fill all password fields');
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      throw Exception('New passwords do not match');
    }

    // In real app, you'd verify current password first
    // For now, we'll just update the password
    await SupabaseService.client.auth.updateUser(
      UserAttributes(password: _newPasswordController.text),
    );
  }

  Future<void> _updateEmail() async {
    await SupabaseService.client.auth.updateUser(
      UserAttributes(email: _emailController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/ranking',
              (route) => false,
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Banner Image Picker
                    GestureDetector(
                      onTap: _pickBackgroundImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _backgroundImagePath.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        color: Colors.grey,
                                      ),
                                      Text('Tap to change banner'),
                                    ],
                                  ),
                                )
                              : _backgroundImagePath.startsWith('http')
                              ? Image.network(
                                  _backgroundImagePath,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : _backgroundBytes != null
                              ? Image.memory(
                                  _backgroundBytes!,
                                  width: double.infinity,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Icon(Icons.image, size: 40),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                            ),
                            child: ClipOval(
                              child: _imagePath.isEmpty
                                  ? const Icon(Icons.add_a_photo, size: 40)
                                  : _imagePath.startsWith('http')
                                  ? Image.network(
                                      _imagePath,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) {
                                        debugPrint(
                                          '❌ Network image error: $err',
                                        );
                                        return const Icon(
                                          Icons.error,
                                          size: 40,
                                        );
                                      },
                                    )
                                  : _imageBytes != null
                                  ? Image.memory(
                                      _imageBytes!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image, size: 40),
                            ),
                          ),
                          // Camera badge to indicate tap to change
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap to change photo'),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.info),
                      ),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a bio'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Please enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your phone number'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hobbiesController,
                      decoration: const InputDecoration(
                        labelText: 'Hobbies (comma separated)',
                        prefixIcon: Icon(Icons.star),
                        hintText: 'Coding, Reading, Gaming',
                      ),
                    ),
                    const SizedBox(height: 30),

                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LocationPicker(
                      initialLatitude: _latitude,
                      initialLongitude: _longitude,
                      onLocationPicked: (lat, long) {
                        setState(() {
                          _latitude = lat;
                          _longitude = long;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    _buildProjectSection(
                      title: 'Projects',
                      projects: _projects,
                      onAdd: () async {
                        final result = await showDialog<Project>(
                          context: context,
                          builder: (context) => const ProjectEditorDialog(),
                        );
                        if (result != null) {
                          setState(() {
                            _projects.add(result);
                          });
                        }
                      },
                      onEdit: (index) async {
                        final result = await showDialog<Project>(
                          context: context,
                          builder: (context) =>
                              ProjectEditorDialog(project: _projects[index]),
                        );
                        if (result != null) {
                          setState(() {
                            _projects[index] = result;
                          });
                        }
                      },
                      onDelete: (index) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Project'),
                            content: Text(
                              'Are you sure you want to delete "${_projects[index].title}"? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          setState(() {
                            _projects.removeAt(index);
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    // Account Security Section
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Security',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _currentPasswordController,
                              obscureText: _obscureCurrentPassword,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureCurrentPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureCurrentPassword =
                                          !_obscureCurrentPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: _obscureNewPassword,
                              decoration: InputDecoration(
                                labelText:
                                    'New Password (leave blank to keep current)',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureNewPassword =
                                          !_obscureNewPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value != null &&
                                    value.isNotEmpty &&
                                    value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_newPasswordController.text.isNotEmpty)
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password',
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (_newPasswordController.text.isNotEmpty &&
                                      value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProjectSection({
    required String title,
    required List<Project> projects,
    required VoidCallback onAdd,
    required Function(int) onEdit,
    required Function(int) onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8FBC8F), Color(0xFF6B8E6B)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'No projects added yet',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap + to add your first project',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else if (projects.length <= 3)
          ...projects.asMap().entries.map((entry) {
            final index = entry.key;
            final project = entry.value;
            return _buildProjectCard(project, index, onEdit, onDelete, isDark);
          })
        else
          SizedBox(
            height: 450,
            child: SingleChildScrollView(
              child: Column(
                children: projects.asMap().entries.map((entry) {
                  final index = entry.key;
                  final project = entry.value;
                  return _buildProjectCard(
                    project,
                    index,
                    onEdit,
                    onDelete,
                    isDark,
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProjectCard(
    Project project,
    int index,
    Function(int) onEdit,
    Function(int) onDelete,
    bool isDark,
  ) {
    final hasLink = project.link != null && project.link!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A3A2A), const Color(0xFF1E2E1E)]
              : [Colors.white, const Color(0xFFF5FAF5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8FBC8F).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF8FBC8F).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8FBC8F).withOpacity(0.2),
                  const Color(0xFF8FBC8F).withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8FBC8F).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.code,
                    size: 20,
                    color: isDark ? Colors.white : const Color(0xFF4A6741),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF2E4A2E),
                    ),
                  ),
                ),
                if (hasLink)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 14, color: Colors.blue[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[400],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: () => onEdit(index),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red[400],
                  ),
                  onPressed: () => onDelete(index),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              project.description,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Tech stack chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.stack.split(',').map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF8FBC8F).withOpacity(0.3),
                        const Color(0xFF6B8E6B).withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8FBC8F).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    tech.trim(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFB8D4B8)
                          : const Color(0xFF4A6741),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Link display
          if (hasLink)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.open_in_new, size: 14, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.link!,
                      style: TextStyle(fontSize: 12, color: Colors.blue[400]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
