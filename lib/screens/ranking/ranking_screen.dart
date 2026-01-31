import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import 'widgets/resume_card.dart';
import 'widgets/resume_details_sheet.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Resume> _resumes = [];
  bool _isLoading = true;
  Resume?
  _myResume; // Current user's resume (can be null if they haven't created one)
  bool _hasResume = false;

  // Realtime subscription channels
  RealtimeChannel? _resumesChannel;
  RealtimeChannel? _ratingsChannel;

  @override
  void initState() {
    super.initState();
    _loadResumes();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    _resumesChannel?.unsubscribe();
    _ratingsChannel?.unsubscribe();
    super.dispose();
  }

  /// Set up realtime subscriptions for instant updates
  void _setupRealtimeSubscriptions() {
    // Subscribe to resume changes
    _resumesChannel = Supabase.instance.client
        .channel('resumes_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'resumes',
          callback: (payload) {
            debugPrint('🔔 Resume change detected: ${payload.eventType}');
            _loadResumes();
          },
        )
        .subscribe();

    // Subscribe to rating changes
    _ratingsChannel = Supabase.instance.client
        .channel('resume_ratings_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'resume_ratings',
          callback: (payload) {
            debugPrint('⭐ Rating change detected: ${payload.eventType}');
            _loadResumes();
          },
        )
        .subscribe();
  }

  Future<void> _loadResumes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final currentUser = SupabaseService.currentUser;
    List<Resume> allResumes = [];

    try {
      // Fetch all resumes from database
      final data = await SupabaseService.getResumeRankings();
      allResumes = data.map((json) => Resume.fromJson(json)).toList();

      // Sort by rating
      allResumes.sort((a, b) => b.averageRating.compareTo(a.averageRating));

      // Handle "My Resume" separation
      final currentUserId = currentUser?.id;

      if (currentUserId != null) {
        final myResumeIndex = allResumes.indexWhere(
          (r) => r.userId == currentUserId,
        );

        if (myResumeIndex != -1) {
          _myResume = allResumes[myResumeIndex];
          _hasResume = true;
          allResumes.removeAt(myResumeIndex);
        } else {
          _myResume = null;
          _hasResume = false;
        }
      } else {
        _myResume = null;
        _hasResume = false;
      }

      // Update UI
      if (mounted) {
        setState(() {
          if (_myResume != null) {
            _resumes = [_myResume!, ...allResumes];
          } else {
            _resumes = allResumes;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading resumes: $e');
      if (mounted) {
        setState(() {
          _resumes = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _rateResume(Resume resume, double rating) async {
    final currentUser = SupabaseService.currentUser;
    if (currentUser == null) return;

    // Can't rate your own resume
    if (resume.userId == currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can't rate your own resume! 😅"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Check if user already voted on this resume
      final hasVoted = await SupabaseService.hasUserRatedResume(
        resumeId: resume.id,
        raterId: currentUser.id,
      );

      // Rate the resume (will insert or update)
      await SupabaseService.rateResume(
        resumeId: resume.id,
        raterId: currentUser.id,
        rating: rating,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasVoted
                  ? 'Updated your rating to $rating stars! ⭐'
                  : 'Rated ${resume.userName}\'s resume with $rating stars! ⭐',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadResumes(); // Refresh rankings
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to rate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateResumeDialog(BuildContext context) {
    // Navigate directly to edit profile screen for new users to fill in their details
    // After saving, their resume will appear on the leaderboard
    Navigator.pushNamed(context, '/edit-profile').then((_) {
      // Refresh the rankings when returning from edit profile
      _loadResumes();
    });
  }

  void _showResumeDetails(
    BuildContext context,
    Resume resume,
    int rank, {
    bool isMyResume = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ResumeDetailsSheet(
        resume: resume,
        rank: rank,
        isMyResume: isMyResume,
        onRate: (rating) => _rateResume(resume, rating),
        onEdit: () {
          Navigator.pushNamed(
            context,
            '/edit-profile',
          ).then((_) => _loadResumes());
        },
        onViewFull: () {
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {'resume': resume, 'isOwner': isMyResume},
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Rankings'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadResumes),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4A5D23), Color(0xFF8FBC8F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Resume App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Rank & Connect',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Friends'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/friends');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Show "Create Your Resume" banner if user doesn't have one
                if (!_hasResume)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8FBC8F), Color(0xFF556B2F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8FBC8F).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Create Your Resume',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Build your professional resume and get ranked!',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateResumeDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF556B2F),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Show rankings
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadResumes,
                    child: _resumes.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.leaderboard,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No resumes yet!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Be the first to create one.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _resumes.length,
                            itemBuilder: (context, index) {
                              final resume = _resumes[index];
                              final rank = index + 1;
                              final isMyResume =
                                  resume.userId ==
                                  SupabaseService.currentUser?.id;
                              return ResumeCard(
                                resume: resume,
                                rank: rank,
                                isMyResume: isMyResume,
                                onTap: () => _showResumeDetails(
                                  context,
                                  resume,
                                  rank,
                                  isMyResume: isMyResume,
                                ),
                                onEdit: () => Navigator.pushNamed(
                                  context,
                                  '/edit-profile',
                                ).then((_) => _loadResumes()),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _hasResume
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit My Resume'),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showCreateResumeDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Resume'),
            ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await SupabaseService.signOut();
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/signin',
                  (route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
