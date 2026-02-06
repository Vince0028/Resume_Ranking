import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ProfileSliverAppBar extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;
  final VoidCallback onShowQRCode;
  final VoidCallback onLogout;
  final ImageProvider? avatarImage; // Keep for non-network images (file/memory)

  const ProfileSliverAppBar({
    super.key,
    required this.profile,
    required this.isOwner,
    required this.onShowQRCode,
    required this.onLogout,
    this.avatarImage,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          profile.name,
          style: const TextStyle(
            color: Colors.white,
            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background decoration
            _buildBackground(context),

            // Centered Circular Avatar
            Center(
              child: Container(
                width: 154,
                height: 154,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8FBC8F), Color(0xFF6B8E6B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _buildAvatar(),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: isOwner
          ? [
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: onShowQRCode,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'logout') {
                    onLogout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ]
          : null,
    );
  }

  Widget _buildBackground(BuildContext context) {
    if (profile.backgroundImagePath.isNotEmpty) {
      if (profile.backgroundImagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: profile.backgroundImagePath,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).primaryColor,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).primaryColor,
            child: const Icon(Icons.error, color: Colors.white),
          ),
        );
      } else if (File(profile.backgroundImagePath).existsSync()) {
        return Image.file(File(profile.backgroundImagePath), fit: BoxFit.cover);
      }
    }
    return Container(color: Theme.of(context).primaryColor);
  }

  Widget _buildAvatar() {
    ImageProvider? imageProvider = avatarImage;

    // If we have a network URL passed via profile and it's not being overridden by avatarImage (which might be local)
    // Actually, ProfileScreen passes _getAvatarImage which returns NetworkImage if http.
    // We should prefer CachedNetworkImageProvider for network images.

    if (profile.imagePath.isNotEmpty && profile.imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: profile.imagePath,
        imageBuilder: (context, imageProvider) =>
            CircleAvatar(radius: 73, backgroundImage: imageProvider),
        placeholder: (context, url) =>
            const CircleAvatar(radius: 73, child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            const CircleAvatar(radius: 73, child: Icon(Icons.error)),
      );
    }

    // Fallback for local images or no image
    return imageProvider != null
        ? CircleAvatar(radius: 73, backgroundImage: imageProvider)
        : Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF4A6741), const Color(0xFF2E4A2E)],
              ),
            ),
            child: Center(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 64,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
