import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ChatListModal extends StatefulWidget {
  const ChatListModal({super.key});

  @override
  State<ChatListModal> createState() => _ChatListModalState();
}

class _ChatListModalState extends State<ChatListModal> {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await SupabaseService.getRecentChats();
    if (mounted) {
      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    final dt = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('h:mm a').format(dt);
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Recent Chats',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              // List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _chats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No recent chats',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _chats.length,
                        itemBuilder: (context, index) {
                          final chat = _chats[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  chat['avatar_url'] != null &&
                                      chat['avatar_url'].isNotEmpty
                                  ? NetworkImage(chat['avatar_url'])
                                  : null,
                              child:
                                  chat['avatar_url'] == null ||
                                      chat['avatar_url'].isEmpty
                                  ? Text((chat['name'] ?? 'U')[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(
                              chat['name'] ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              chat['last_message'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Text(
                              _formatTimestamp(chat['timestamp']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () async {
                              // Close modal before navigating
                              // Navigator.pop(context);
                              // Wait, user might want to go back to list?
                              // If we pop, we go back to Friends.
                              // If we push, we are on top of modal.
                              // Let's push on top.
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    otherUserId: chat['partner_id'],
                                    otherUserName: chat['name'] ?? 'Unknown',
                                    otherUserAvatar: chat['avatar_url'],
                                  ),
                                ),
                              );
                              _loadChats(); // Refresh when coming back
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
