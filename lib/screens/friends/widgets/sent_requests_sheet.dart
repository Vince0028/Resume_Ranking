import 'package:flutter/material.dart';

class SentRequestsSheet extends StatelessWidget {
  final List<dynamic> sentRequests;

  const SentRequestsSheet({super.key, required this.sentRequests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sent Friend Requests',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (sentRequests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('No pending sent requests.')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: sentRequests.length,
              itemBuilder: (context, index) {
                final request = sentRequests[index];
                final addressee = request['profiles'] as Map<String, dynamic>?;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text((addressee?['name'] ?? 'U')[0].toUpperCase()),
                  ),
                  title: Text(addressee?['name'] ?? 'Unknown'),
                  subtitle: const Text('Pending...'),
                  trailing: const Icon(
                    Icons.hourglass_empty,
                    color: Colors.orange,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
