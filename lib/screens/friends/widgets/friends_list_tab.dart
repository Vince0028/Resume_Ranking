import 'package:flutter/material.dart';
import '../../profile/profile_screen.dart';
import '../../chat/chat_screen.dart';
import 'empty_state_widget.dart';

class FriendsListTab extends StatelessWidget {
  final List<dynamic> friends;
  final String? currentUserId;
  final Future<void> Function() onRefresh;
  final Function(String, String) onRemoveFriend;

  const FriendsListTab({
    super.key,
    required this.friends,
    required this.currentUserId,
    required this.onRefresh,
    required this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: friends.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.group_outlined,
              message: 'No friends yet. Start connecting!',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friendship = friends[index];
                final requester =
                    friendship['requester'] as Map<String, dynamic>?;
                final addressee =
                    friendship['addressee'] as Map<String, dynamic>?;

                // Show the other person (not current user)
                final friend = requester?['id'] == currentUserId
                    ? addressee
                    : requester;
                final friendshipId = friendship['id'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      if (friend != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                            settings: RouteSettings(
                              arguments: {
                                'userId': friend['id'],
                                'isOwner': false,
                              },
                            ),
                          ),
                        );
                      }
                    },
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        (friend?['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(friend?['name'] ?? 'Unknown'),
                    subtitle: Text(friend?['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          onPressed: () {
                            if (friend != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: friend['id'],
                                    otherUserName: friend['name'] ?? 'Unknown',
                                    otherUserAvatar: friend['avatar_url'],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              onRemoveFriend(
                                friendshipId,
                                friend?['name'] ?? 'this user',
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(
                                  Icons.person_remove,
                                  color: Colors.red,
                                ),
                                title: Text(
                                  'Remove Friend',
                                  style: TextStyle(color: Colors.red),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
