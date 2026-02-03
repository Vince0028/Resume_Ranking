import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Realtime subscription management
  static RealtimeChannel? _friendshipsChannel;
  static final _friendshipsController = StreamController<void>.broadcast();
  static Stream<void> get onFriendshipsChange => _friendshipsController.stream;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    _setupRealtimeSubscriptions();
  }

  static void _setupRealtimeSubscriptions() {
    // Listen to auth state to manage subscriptions
    client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _subscribeToFriendships();
      } else if (event == AuthChangeEvent.signedOut) {
        _unsubscribeFromFriendships();
      }
    });

    // If already signed in (e.g. hot restart), ensure subscribed
    if (currentUser != null) {
      _subscribeToFriendships();
    }
  }

  static void _subscribeToFriendships() {
    if (_friendshipsChannel != null) return; // Already subscribed

    final userId = currentUser?.id;
    if (userId == null) return;

    debugPrint('📡 Initializing global friendship subscription for $userId');

    _friendshipsChannel = client
        .channel('friendships_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;

            // Filter for relevance to current user
            bool isRelevant =
                (newRecord['requester_id'] == userId) ||
                (newRecord['addressee_id'] == userId) ||
                (oldRecord['requester_id'] == userId) ||
                (oldRecord['addressee_id'] == userId);

            // Handle deletions where IDs might be in oldRecord only
            if (!isRelevant &&
                payload.eventType == PostgresChangeEvent.delete) {
              // We can't easily check against local lists here without state access,
              // so we err on the side of caution or need to trust RLS/payload.
              // If RLS is on, we only get relevant rows anyway.
              // For now, we'll assume if we got the event, we should check it.
              // Ideally RLS ensures we only see our own rows.
              isRelevant = true;
            }

            if (isRelevant) {
              debugPrint('🔔 Friendship update detected, notifying listeners');
              _friendshipsController.add(null);
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('📡 Global Friendship Status: $status ${error ?? ""}');
        });
  }

  static void _unsubscribeFromFriendships() {
    if (_friendshipsChannel != null) {
      debugPrint('🔕 Unsubscribing from timeouts');
      _friendshipsChannel!.unsubscribe();
      _friendshipsChannel = null;
    }
  }

  // Get current user
  static User? get currentUser => client.auth.currentUser;

  // Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
      emailRedirectTo: 'io.supabase.finalmobprog://login-callback',
    );
    return response;
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // Subscription will be triggered by onAuthStateChange
    return response;
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
    // Subscription will be cleaned up by onAuthStateChange
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;

  // === Storage Operations ===

  /// Upload image to Supabase Storage and return the public URL
  /// [bucket] - Storage bucket name (e.g., 'avatars', 'backgrounds')
  /// [filePath] - Local file path
  /// [folder] - Optional folder within the bucket
  static Future<String?> uploadImage({
    required String bucket,
    required String filePath,
    String? folder,
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;

      // Read file as bytes to avoid platform-specific issues
      final bytes = await file.readAsBytes();

      final fileExt = filePath.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = folder != null
          ? '$folder/$userId/$fileName'
          : '$userId/$fileName';

      // Determine content type
      String contentType = 'image/jpeg';
      if (fileExt == 'png') {
        contentType = 'image/png';
      } else if (fileExt == 'gif') {
        contentType = 'image/gif';
      } else if (fileExt == 'webp') {
        contentType = 'image/webp';
      }

      // Upload the file as bytes
      await client.storage
          .from(bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );

      // Get the public URL
      final publicUrl = client.storage.from(bucket).getPublicUrl(storagePath);
      debugPrint('📸 Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Upload image from bytes (for web platform support)
  static Future<String?> uploadImageBytes({
    required String bucket,
    required Uint8List bytes,
    String fileExtension = 'jpg',
  }) async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return null;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final storagePath = '$userId/$fileName';

      // Determine content type
      String contentType = 'image/jpeg';
      if (fileExtension == 'png') {
        contentType = 'image/png';
      } else if (fileExtension == 'gif') {
        contentType = 'image/gif';
      } else if (fileExtension == 'webp') {
        contentType = 'image/webp';
      }

      // Upload the bytes
      await client.storage
          .from(bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: contentType,
            ),
          );

      // Get the public URL
      final publicUrl = client.storage.from(bucket).getPublicUrl(storagePath);
      debugPrint('📸 Image uploaded from bytes: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image bytes: $e');
      return null;
    }
  }

  /// Upload avatar image from file path (for mobile)
  static Future<String?> uploadAvatar(String filePath) async {
    return uploadImage(bucket: 'avatars', filePath: filePath);
  }

  /// Upload avatar image from bytes (for web)
  static Future<String?> uploadAvatarBytes(Uint8List bytes) async {
    return uploadImageBytes(bucket: 'avatars', bytes: bytes);
  }

  /// Upload background image from file path (for mobile)
  static Future<String?> uploadBackground(String filePath) async {
    return uploadImage(bucket: 'backgrounds', filePath: filePath);
  }

  /// Upload background image from bytes (for web)
  static Future<String?> uploadBackgroundBytes(Uint8List bytes) async {
    return uploadImageBytes(bucket: 'backgrounds', bytes: bytes);
  }

  // === Resume/Profile Database Operations ===

  // Create or update user profile in database
  static Future<void> upsertProfile({
    required String userId,
    required String name,
    required String bio,
    required String email,
    required String phone,
    String? avatarUrl,
    List<String>? hobbies,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'name': name,
      'bio': bio,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'hobbies': hobbies,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Get all resumes ranked by average rating
  static Future<List<Map<String, dynamic>>> getResumeRankings() async {
    // Note: Removed profiles join due to PostgREST schema cache issues
    // The resume_data field contains the user info we need
    final response = await client
        .from('resumes')
        .select('*')
        .order('average_rating', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get current user's resume
  static Future<Map<String, dynamic>?> getCurrentUserResume() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await client
          .from('resumes')
          .select('*, profiles(name, avatar_url)')
          .eq('user_id', user.id)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Get current user's profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return getUserProfile(user.id);
  }

  // Get any user's profile by ID
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  // Check if current user has a resume
  static Future<bool> hasResume() async {
    final resume = await getCurrentUserResume();
    return resume != null;
  }

  // Submit a resume (creates new or updates existing)
  static Future<void> submitResume({
    required String userId,
    required String title,
    required String content,
    required Map<String, dynamic> resumeData,
  }) async {
    // Check if user already has a resume
    final existingResume = await getUserResume(userId);

    if (existingResume != null) {
      // Update existing resume (preserve ratings)
      await client
          .from('resumes')
          .update({
            'title': title,
            'content': content,
            'resume_data': resumeData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } else {
      // Create new resume
      await client.from('resumes').insert({
        'user_id': userId,
        'title': title,
        'content': content,
        'resume_data': resumeData,
        'average_rating': 0.0,
        'total_ratings': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Check if user has already rated a resume
  static Future<bool> hasUserRatedResume({
    required String resumeId,
    required String raterId,
  }) async {
    final response = await client
        .from('resume_ratings')
        .select('id')
        .eq('resume_id', resumeId)
        .eq('rater_id', raterId)
        .maybeSingle();
    return response != null;
  }

  // Rate a resume (insert new or update existing rating)
  static Future<void> rateResume({
    required String resumeId,
    required String raterId,
    required double rating,
  }) async {
    debugPrint('🌟 Rating resume: $resumeId with $rating stars by $raterId');

    // Insert or update the rating using onConflict
    await client.from('resume_ratings').upsert(
      {
        'resume_id': resumeId,
        'rater_id': raterId,
        'rating': rating,
        'created_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'resume_id,rater_id', // Update if same user rates same resume
    );
    debugPrint('✅ Rating inserted/updated');

    // Update average rating on the resume
    final ratings = await client
        .from('resume_ratings')
        .select('rating')
        .eq('resume_id', resumeId);

    debugPrint('📊 Found ${ratings.length} ratings for resume $resumeId');

    if (ratings.isNotEmpty) {
      final avgRating =
          ratings
              .map((r) => (r['rating'] as num).toDouble())
              .reduce((a, b) => a + b) /
          ratings.length;

      debugPrint(
        '📈 Calculated average: $avgRating from ${ratings.length} ratings',
      );

      await client
          .from('resumes')
          .update({
            'average_rating': avgRating,
            'total_ratings': ratings.length,
          })
          .eq('id', resumeId);

      debugPrint('✅ Resume average updated to $avgRating');
    }
  }

  // Get user's own resume
  static Future<Map<String, dynamic>?> getUserResume(String userId) async {
    final response = await client
        .from('resumes')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  // === Friendship Operations ===

  // Get all users (for adding friends)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final currentUserId = currentUser?.id;
    final response = await client
        .from('profiles')
        .select('id, name, email, avatar_url, bio')
        .neq('id', currentUserId ?? '');
    return List<Map<String, dynamic>>.from(response);
  }

  // Send friend request
  static Future<void> sendFriendRequest(String addresseeId) async {
    final requesterId = currentUser?.id;
    if (requesterId == null) return;

    // First, try to delete any existing rejected/old requests between these users
    await client
        .from('friendships')
        .delete()
        .or(
          'and(requester_id.eq.$requesterId,addressee_id.eq.$addresseeId),and(requester_id.eq.$addresseeId,addressee_id.eq.$requesterId)',
        );

    // Then insert new request
    await client.from('friendships').insert({
      'requester_id': requesterId,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  // Accept friend request
  static Future<void> acceptFriendRequest(String friendshipId) async {
    await client
        .from('friendships')
        .update({
          'status': 'accepted',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', friendshipId);
  }

  // Reject friend request (delete so they can re-add later)
  static Future<void> rejectFriendRequest(String friendshipId) async {
    await client.from('friendships').delete().eq('id', friendshipId);
  }

  // Remove friend
  static Future<void> removeFriend(String friendshipId) async {
    await client.from('friendships').delete().eq('id', friendshipId);
  }

  // Get pending friend requests (received)
  static Future<List<Map<String, dynamic>>> getPendingFriendRequests() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('friendships')
        .select(
          '*, profiles!friendships_requester_id_fkey(id, name, email, avatar_url)',
        )
        .eq('addressee_id', userId)
        .eq('status', 'pending');
    return List<Map<String, dynamic>>.from(response);
  }

  // Get accepted friends
  static Future<List<Map<String, dynamic>>> getAcceptedFriends() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    // Get friendships where user is either requester or addressee
    final response = await client
        .from('friendships')
        .select('''
          *,
          requester:profiles!friendships_requester_id_fkey(id, name, email, avatar_url),
          addressee:profiles!friendships_addressee_id_fkey(id, name, email, avatar_url)
        ''')
        .eq('status', 'accepted')
        .or('requester_id.eq.$userId,addressee_id.eq.$userId');

    return List<Map<String, dynamic>>.from(response);
  }

  // Get friendship status with a user
  static Future<Map<String, dynamic>?> getFriendshipStatus(
    String otherUserId,
  ) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await client
        .from('friendships')
        .select()
        .or(
          'and(requester_id.eq.$userId,addressee_id.eq.$otherUserId),and(requester_id.eq.$otherUserId,addressee_id.eq.$userId)',
        )
        .maybeSingle();

    return response;
  }

  // Update current user's profile
  static Future<void> updateProfile({
    required String name,
    String? bio,
    String? email,
    String? phone,
    String? avatarUrl,
    List<String>? hobbies,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');

    await client.from('profiles').upsert({
      'id': user.id,
      'name': name,
      'bio': bio,
      'email': email ?? user.email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'hobbies': hobbies,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // Get sent friend requests (pending)
  static Future<List<Map<String, dynamic>>> getSentFriendRequests() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('friendships')
        .select(
          '*, profiles!friendships_addressee_id_fkey(id, name, email, avatar_url)',
        )
        .eq('requester_id', userId)
        .eq('status', 'pending');
    return List<Map<String, dynamic>>.from(response);
  }

  // === Messaging Operations ===

  // Get messages between current user and another user
  static Future<List<Map<String, dynamic>>> getMessages(
    String otherUserId,
  ) async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)',
        )
        .order('created_at', ascending: true); // Oldest first for chat UI

    return List<Map<String, dynamic>>.from(response);
  }

  // Send a message
  static Future<void> sendMessage(String receiverId, String content) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await client.from('messages').insert({
      'sender_id': userId,
      'receiver_id': receiverId,
      'content': content,
      'created_at': DateTime.now().toUtc().toIso8601String(), // UTC
    });
  }

  static RealtimeChannel? _messagesChannel;

  // Subscribe to messages for a specific chat
  static void subscribeToMessages(
    String otherUserId,
    Function(Map<String, dynamic>) onMessage,
  ) {
    final userId = currentUser?.id;
    if (userId == null) return;

    _messagesChannel?.unsubscribe();

    _messagesChannel = client
        .channel('chat:$userId:$otherUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newRecord = payload.newRecord;
            // Check if it's from the user we are chatting with, sent to us
            if (newRecord['sender_id'] == otherUserId &&
                newRecord['receiver_id'] == userId) {
              onMessage(newRecord);
            }
          },
        )
        .subscribe((status, [error]) {
          debugPrint('🔔 Chat Subscription Status: $status ${error ?? ""}');
        });
  }

  // Unsubscribe from messages
  static void unsubscribeFromMessages() {
    _messagesChannel?.unsubscribe();
    _messagesChannel = null;
  }

  // Get list of recent chat partners with last message
  static Future<List<Map<String, dynamic>>> getRecentChats() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    // Fetch all messages involving the user
    final response = await client
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(500); // Increased limit to catch more conversations

    final List<dynamic> messages = response;
    final Map<String, Map<String, dynamic>> chats = {};

    for (final msg in messages) {
      final senderId = msg['sender_id'] as String;
      final receiverId = msg['receiver_id'] as String;
      final content = msg['content'] as String;
      final createdAt = msg['created_at'] as String;

      final otherId = senderId == userId ? receiverId : senderId;

      if (!chats.containsKey(otherId)) {
        chats[otherId] = {
          'partner_id': otherId,
          'last_message': content,
          'timestamp': createdAt,
        };
      }
    }

    // Now fetch profiles for these partners
    if (chats.isEmpty) return [];

    final partnerIds = chats.keys.toList();
    final profilesResponse = await client
        .from('profiles')
        .select('id, name, avatar_url')
        .inFilter('id', partnerIds);

    final List<Map<String, dynamic>> results = [];
    for (final profile in profilesResponse) {
      final id = profile['id'] as String;
      if (chats.containsKey(id)) {
        results.add({
          ...chats[id]!, // message info
          ...profile, // profile info
        });
      }
    }

    // Sort by timestamp
    results.sort(
      (a, b) => DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp'])),
    );

    return results;
  }
}
