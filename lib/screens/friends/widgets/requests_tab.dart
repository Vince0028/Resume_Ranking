import 'package:flutter/material.dart';
import 'empty_state_widget.dart';

class RequestsTab extends StatelessWidget {
  final List<dynamic> requests;
  final Future<void> Function() onRefresh;
  final Function(String) onAccept;
  final Function(String) onReject;

  const RequestsTab({
    super.key,
    required this.requests,
    required this.onRefresh,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: requests.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.inbox_outlined,
              message: 'No pending friend requests.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final requester = request['profiles'] as Map<String, dynamic>?;
                final friendshipId = request['id'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Text(
                                (requester?['name'] ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    requester?['name'] ?? 'Unknown User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    requester?['email'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => onReject(friendshipId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Decline'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => onAccept(friendshipId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Accept'),
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
