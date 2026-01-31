import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../models/models.dart';

class ResumeDetailsSheet extends StatelessWidget {
  final Resume resume;
  final int rank;
  final bool isMyResume;
  final Function(double) onRate;
  final VoidCallback onEdit;
  final VoidCallback onViewFull;

  const ResumeDetailsSheet({
    super.key,
    required this.resume,
    required this.rank,
    required this.isMyResume,
    required this.onRate,
    required this.onEdit,
    required this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Rank & Name
              Row(
                children: [
                  if (rank <= 3)
                    Icon(
                      Icons.emoji_events,
                      color: rank == 1
                          ? Colors.amber
                          : rank == 2
                          ? Colors.grey
                          : Colors.brown,
                      size: 32,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '#$rank ${resume.userName}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                resume.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // Current rating
              Row(
                children: [
                  RatingBarIndicator(
                    rating: resume.averageRating,
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${resume.averageRating.toStringAsFixed(1)} (${resume.totalRatings} ratings)',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Rate this resume section - only show for OTHER users' resumes
              if (!isMyResume) ...[
                Text(
                  'Rate this Resume',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      Navigator.pop(context);
                      onRate(rating);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
              ],
              const Divider(),
              const SizedBox(height: 16),
              // Resume content
              Text(
                'About',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                resume.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              // View full profile button - only show edit if it's your own resume
              if (isMyResume) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit My Resume'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // View Full Resume button - shown to everyone
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onViewFull();
                  },
                  icon: const Icon(Icons.person),
                  label: const Text('View Full Resume'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
