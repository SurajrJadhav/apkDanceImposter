import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/game_service.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'group_members_screen.dart';
import 'game_screen.dart';
import 'login_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  final GameService _gameService = GameService();
  
  UserModel? _currentUser;
  List<GroupModel> _userGroups = [];
  bool _isLoading = true;
  
  // Game monitoring
  final List<StreamSubscription> _gameSubscriptions = [];
  String? _activeGameGroupId;
  bool _isInGameScreen = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    for (var sub in _gameSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserData();
      if (user != null) {
        final groups = await _groupService.getUserGroups(user.userId);
        setState(() {
          _currentUser = user;
          _userGroups = groups;
          _isLoading = false;
        });
        
        // Check for expired groups
        _checkExpiredGroups();
        
        _updateGameMonitoring();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkExpiredGroups() async {
    if (_currentUser == null) return;

    final now = DateTime.now();
    for (final group in _userGroups) {
      if (now.isAfter(group.expireAt)) {
        // Group expired
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Group ${group.groupId} has expired (1 hour limit).'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        // Leave/Delete locally and on server
        if (group.creatorId == _currentUser!.userId) {
          await _groupService.deleteGroup(group.groupId, _currentUser!.userId);
        } else {
          await _groupService.leaveGroup(groupId: group.groupId, userId: _currentUser!.userId);
        }
        
        // Refresh list
        _loadUserData();
      }
    }
  }

  void _updateGameMonitoring() {
    // Cancel existing subscriptions
    for (var sub in _gameSubscriptions) {
      sub.cancel();
    }
    _gameSubscriptions.clear();

    if (_currentUser == null) return;

    // Monitor each group
    for (final group in _userGroups) {
      // Skip if user is the creator (they control the game)
      if (group.creatorId == _currentUser!.userId) continue;

      final sub = _gameService.getGameStateStream(group.groupId).listen((gameState) {
        if (!mounted) return;

        // Check if game is playing and user is a member
        if (gameState != null && gameState.isPlaying) {
          // Check if user is assigned a song (they're in the game)
          if (gameState.songAssignments.containsKey(_currentUser!.userId)) {
            _navigateToGameScreen(group.groupId);
          }
        } else if (gameState != null && gameState.isIdle) {
          // Game stopped, but we stay in GameScreen (Lobby mode)
          // _closeGameScreen(group.groupId); 
        }
      });

      _gameSubscriptions.add(sub);
    }
  }

  void _navigateToGameScreen(String groupId) {
    // Prevent multiple navigations
    if (_isInGameScreen && _activeGameGroupId == groupId) return;

    setState(() {
      _isInGameScreen = true;
      _activeGameGroupId = groupId;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(groupId: groupId),
        fullscreenDialog: true,
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isInGameScreen = false;
          _activeGameGroupId = null;
        });
      }
    });
  }



  Future<void> _logout() async {
    try {
      await _authService.logoutUser();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGroup(GroupModel group) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete group ${group.groupId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentUser != null) {
      try {
        // Delete the group document and remove from creator's list
        await _groupService.deleteGroup(group.groupId, _currentUser!.userId);
        
        // Reload groups
        _loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _leaveGroup(GroupModel group) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave group ${group.groupId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentUser != null) {
      try {
        await _groupService.leaveGroup(
          groupId: group.groupId,
          userId: _currentUser!.userId,
        );
        
        // Reload groups
        _loadUserData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Left group successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to leave group: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _copyGroupId(String groupId) {
    Clipboard.setData(ClipboardData(text: groupId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group ID copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Check if user is in any group (as creator or member)
  bool get _isInGroup {
    return _userGroups.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Group Manager',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadUserData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TutorialScreen(),
                ),
              );
            },
            tooltip: 'How to Play',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User greeting
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentUser?.email ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                
                const SizedBox(height: 32),

                // My Groups Section
                if (_userGroups.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Groups',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_userGroups.length} ${_userGroups.length == 1 ? 'group' : 'groups'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // List of groups
                  ..._userGroups.map((group) {
                    final isCreator = group.creatorId == _currentUser?.userId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCreator
                              ? Theme.of(context).primaryColor.withOpacity( 0.3)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity( 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isCreator
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupMembersScreen(
                                        groupId: group.groupId,
                                      ),
                                    ),
                                  ).then((_) => _loadUserData());
                                }
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isCreator
                                            ? Theme.of(context).primaryColor.withOpacity( 0.1)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isCreator ? Icons.star : Icons.group,
                                        color: isCreator
                                            ? Theme.of(context).primaryColor
                                            : Colors.grey[700],
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                group.groupId,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.copy, size: 18),
                                                onPressed: () => _copyGroupId(group.groupId),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isCreator
                                                ? 'Created by you • ${group.members.length} members'
                                                : 'Created by ${group.creatorName} • ${group.members.length} members',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isCreator)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => _deleteGroup(group),
                                        tooltip: 'Delete Group',
                                      ),
                                  ],
                                ),
                                if (isCreator) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GroupMembersScreen(
                                              groupId: group.groupId,
                                            ),
                                          ),
                                        ).then((_) => _loadUserData());
                                      },
                                      icon: const Icon(Icons.people, size: 18),
                                      label: const Text('View Members'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  // Buttons for non-creator members
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => GroupMembersScreen(
                                                  groupId: group.groupId,
                                                ),
                                              ),
                                            ).then((_) => _loadUserData());
                                          },
                                          icon: const Icon(Icons.people, size: 18),
                                          label: const Text('View'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Theme.of(context).primaryColor,
                                            side: BorderSide(color: Theme.of(context).primaryColor),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _leaveGroup(group),
                                          icon: const Icon(Icons.exit_to_app, size: 18),
                                          label: const Text('Leave'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: const BorderSide(color: Colors.red),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 32),
                ],

                // Create Group Button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: _isInGroup
                        ? null
                        : LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity( 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    color: _isInGroup ? Colors.grey[200] : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: _isInGroup
                        ? null
                        : [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity( 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_add,
                        size: 48,
                        color: _isInGroup ? Colors.grey[400] : Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Create a New Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isInGroup ? Colors.grey[600] : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isInGroup
                            ? 'Leave your current group to create a new one'
                            : 'Start a new group and invite members',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _isInGroup ? Colors.grey[500] : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isInGroup
                              ? null
                              : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const CreateGroupScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUserData();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInGroup ? Colors.grey[400] : Colors.white,
                            foregroundColor: _isInGroup
                                ? Colors.grey[600]
                                : Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create Group',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Join Group Button
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _isInGroup ? Colors.grey[200] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.group,
                        size: 48,
                        color: _isInGroup ? Colors.grey[400] : Colors.black54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join a Group',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _isInGroup ? Colors.grey[600] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isInGroup
                            ? 'Leave your current group to join a new one'
                            : 'Enter a group ID to join',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _isInGroup ? Colors.grey[500] : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isInGroup
                              ? null
                              : () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const JoinGroupScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUserData();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isInGroup ? Colors.grey[400] : Colors.black87,
                            foregroundColor: _isInGroup ? Colors.grey[600] : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Join Group',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Banner Ad
                // const Center(
                //   child: BannerAdWidget(),
                // ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

