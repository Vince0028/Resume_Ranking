import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/models.dart';

class ResumeCard extends StatelessWidget {
  final Resume resume;
  final int rank;
  final bool isMyResume;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ResumeCard({
    super.key,
    required this.resume,
    required this.rank,
    required this.isMyResume,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    final rankColors = {
      1: Colors.amber,
      2: Colors.grey.shade400,
      3: Colors.brown.shade300,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isTopThree ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isMyResume
            ? BorderSide(color: Theme.of(context).primaryColor, width: 3)
            : isTopThree
            ? BorderSide(
                color: rankColors[rank] ?? Colors.transparent,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // "My Resume" badge
          if (isMyResume)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: const Text(
                '⭐ MY RESUME',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(isMyResume ? 0 : 16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          rankColors[rank] ??
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: isTopThree
                          ? Icon(
                              rank == 1
                                  ? Icons.emoji_events
                                  : Icons.workspace_premium,
                              color: rank == 1 ? Colors.white : Colors.white,
                              size: 28,
                            )
                          : Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                resume.userName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isMyResume)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: onEdit,
                                tooltip: 'Edit My Resume',
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resume.title,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Star rating display
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: resume.averageRating,
                              itemBuilder: (context, _) =>
                                  const Icon(Icons.star, color: Colors.amber),
                              itemCount: 5,
                              itemSize: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${resume.averageRating.toStringAsFixed(1)} (${resume.totalRatings})',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
