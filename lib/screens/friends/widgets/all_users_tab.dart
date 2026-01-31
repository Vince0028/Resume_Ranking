import 'package:flutter/material.dart';
import 'empty_state_widget.dart';

class AllUsersTab extends StatelessWidget {
  final List<dynamic> allUsers;
  final List<dynamic> friends;
  final Set<String> pendingActions;
  final List<dynamic> receivedRequests;
  final Future<void> Function() onRefresh;
  final Function(String) onAddFriend;
  final VoidCallback onViewRequest;

  const AllUsersTab({
    super.key,
    required this.allUsers,
    required this.friends,
    required this.pendingActions,
    required this.receivedRequests,
    required this.onRefresh,
    required this.onAddFriend,
    required this.onViewRequest,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: allUsers.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.people_outline,
              message: 'No other users found yet.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allUsers.length,
              itemBuilder: (context, index) {
                final user = allUsers[index];
                final userId = user['id'];

                final isFriend = friends.any((f) {
                  final requester = f['requester'];
                  final addressee = f['addressee'];
                  return requester?['id'] == userId ||
                      addressee?['id'] == userId;
                });

                final isPending = pendingActions.contains(userId);

                final hasReceivedRequest = receivedRequests.any((r) {
                  final requester = r['profiles'];
                  return requester?['id'] == userId;
                });

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        (user['name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user['name'] ?? 'Unknown User'),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: _buildUserActionButton(
                      context: context,
                      userId: userId,
                      isFriend: isFriend,
                      isPending: isPending,
                      hasReceivedRequest: hasReceivedRequest,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildUserActionButton({
    required BuildContext context,
    required String userId,
    required bool isFriend,
    required bool isPending,
    required bool hasReceivedRequest,
  }) {
    if (isFriend) {
      return const Chip(
        label: Text('Friends'),
        avatar: Icon(Icons.check, size: 16),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    if (hasReceivedRequest) {
      return ElevatedButton(
        onPressed: onViewRequest,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
        child: const Text('View Request'),
      );
    }

    if (isPending) {
      return const Chip(
        label: Text('Pending'),
        avatar: Icon(Icons.hourglass_empty, size: 16),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => onAddFriend(userId),
      icon: const Icon(Icons.person_add, size: 18),
      label: const Text('Add'),
    );
  }
}
