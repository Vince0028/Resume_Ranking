import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/supabase_service.dart';
import 'widgets/all_users_tab.dart';
import 'widgets/requests_tab.dart';
import 'widgets/friends_list_tab.dart';
import 'widgets/sent_requests_sheet.dart';
import '../chat/chat_list_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _sentRequests = [];
  bool _isLoading = true;
  final Set<String> _pendingActions =
      {}; // Track users with pending friend requests

  // Subscription to global friendship events
  StreamSubscription? _friendshipsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _setupSubscription();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _friendshipsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupSubscription() {
    // Listen to the global stream from SupabaseService
    // This avoids creating/destroying sockets on every navigation
    _friendshipsSubscription = SupabaseService.onFriendshipsChange.listen((_) {
      debugPrint('🔔 FriendsScreen received update from global stream');
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        SupabaseService.getAllUsers(),
        SupabaseService.getPendingFriendRequests(),
        SupabaseService.getAcceptedFriends(),
        SupabaseService.getSentFriendRequests(),
      ]);

      setState(() {
        _allUsers = results[0];
        _pendingRequests = results[1];
        _friends = results[2];
        _sentRequests = results[3];

        // Build set of users we've sent requests to
        _pendingActions.clear();
        for (var req in _sentRequests) {
          final addressee = req['profiles'];
          if (addressee != null) {
            _pendingActions.add(addressee['id']);
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Silently fail or show error
      }
    }
  }

  int get _notificationCount => _pendingRequests.length;

  void _showFriendQRCode() {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    // We encode the User ID prefixed with FRIEND:
    final qrData = 'FRIEND:${user.id}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'My Friend Code',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Let others scan this to add you!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF4A5D23),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF4A5D23),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scanQRCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 350,
          height: 450,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Scan Friend Code',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null &&
                            rawValue.startsWith('FRIEND:')) {
                          final friendId = rawValue.substring(
                            7,
                          ); // Remove FRIEND: prefix
                          if (friendId != SupabaseService.currentUser?.id) {
                            Navigator.pop(context); // Close scanner
                            _sendFriendRequest(
                              friendId,
                            ); // This method is not provided in the original context, assuming it exists or will be added.
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("You can't add yourself!"),
                              ),
                            );
                          }
                          return; // Stop after first valid code
                        }
                      }
                    },
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/ranking',
              (route) => false,
            );
          },
        ),
        actions: [
          // Notification badge for pending requests
          if (_notificationCount > 0)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    _tabController.animateTo(1); // Go to requests tab
                  },
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _notificationCount > 9 ? '9+' : '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // More Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'show_qr':
                  _showFriendQRCode();
                  break;
                case 'scan_qr':
                  _scanQRCode();
                  break;
                case 'sent_requests':
                  _showSentRequests();
                  break;
                case 'refresh':
                  _loadData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'show_qr',
                child: ListTile(
                  leading: Icon(Icons.qr_code),
                  title: Text('Show My Friend Code'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'scan_qr',
                child: ListTile(
                  leading: Icon(Icons.qr_code_scanner),
                  title: Text('Scan Friend Code'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'sent_requests',
                child: ListTile(
                  leading: Icon(Icons.outbox),
                  title: Text('Sent Requests'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(icon: Icon(Icons.people), text: 'All Users'),
            Tab(
              icon: Badge(
                isLabelVisible: _notificationCount > 0,
                label: Text('$_notificationCount'),
                child: const Icon(Icons.person_add),
              ),
              text: 'Requests',
            ),
            Tab(icon: const Icon(Icons.group), text: 'Friends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                AllUsersTab(
                  allUsers: _allUsers,
                  friends: _friends,
                  pendingActions: _pendingActions,
                  receivedRequests: _pendingRequests,
                  onRefresh: _loadData,
                  onAddFriend: _sendFriendRequest,
                  onViewRequest: () => _tabController.animateTo(1),
                ),
                RequestsTab(
                  requests: _pendingRequests, // requests
                  onRefresh: _loadData,
                  onAccept: _acceptRequest,
                  onReject: _rejectRequest,
                ),
                FriendsListTab(
                  friends: _friends,
                  currentUserId: SupabaseService.currentUser?.id,
                  onRefresh: _loadData,
                  onRemoveFriend: _confirmRemoveFriend,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const ChatListModal(),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.forum, color: Colors.white),
      ),
    );
  }

  Future<void> _sendFriendRequest(String addresseeId) async {
    try {
      await SupabaseService.sendFriendRequest(addresseeId);
      setState(() {
        _pendingActions.add(addresseeId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _acceptRequest(String friendshipId) async {
    try {
      await SupabaseService.acceptFriendRequest(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request accepted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectRequest(String friendshipId) async {
    try {
      await SupabaseService.rejectFriendRequest(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined.')),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmRemoveFriend(String friendshipId, String friendName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove $friendName from your friends?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await SupabaseService.removeFriend(friendshipId);
              _loadData();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showSentRequests() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SentRequestsSheet(sentRequests: _sentRequests),
    );
  }
}
