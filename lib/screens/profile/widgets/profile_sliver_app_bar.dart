import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/models.dart';

class ProfileSliverAppBar extends StatelessWidget {
  final UserProfile profile;
  final bool isOwner;
  final VoidCallback onShowQRCode;
  final VoidCallback onLogout;
  final ImageProvider? avatarImage;

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
            (profile.backgroundImagePath.isNotEmpty &&
                    File(profile.backgroundImagePath).existsSync())
                ? Image.file(
                    File(profile.backgroundImagePath),
                    fit: BoxFit.cover,
                  )
                : Container(color: Theme.of(context).primaryColor),

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
                  child: avatarImage != null
                      ? CircleAvatar(radius: 73, backgroundImage: avatarImage)
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF4A6741),
                                const Color(0xFF2E4A2E),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              profile.name.isNotEmpty
                                  ? profile.name[0].toUpperCase()
                                  : 'U',
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
                        ),
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
}
