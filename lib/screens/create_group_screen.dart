import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../models/group_model.dart';
import '../widgets/custom_button.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'group_members_screen.dart';
import '../services/ad_service.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  GroupModel? _createdGroup;

  Future<void> _createGroup() async {
    // Show loading while ad initializes
    setState(() {
      _isLoading = true;
    });

    AdService().showRewardedAd(
      onUserEarnedReward: () {
        // User watched the ad, proceed with group creation
        _performGroupCreation();
      },
      onAdDismissed: () {
        // User closed ad without watching to completion
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must watch the ad to create a group'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
      onAdFailedToLoad: () {
        // Ad failed to load
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load ad. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Future<void> _performGroupCreation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        throw 'User not found';
      }

      final group = await _groupService.createGroup(
        creatorId: currentUser.userId,
        creatorName: currentUser.name,
      );

      setState(() {
        _createdGroup = group;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

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

  void _copyGroupId() {
    if (_createdGroup != null) {
      Clipboard.setData(ClipboardData(text: _createdGroup!.groupId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group ID copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // Always return the group creation status when backing out
          Navigator.pop(context, _createdGroup != null);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context, _createdGroup != null),
          ),
        title: const Text(
          'Create Group',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              if (_createdGroup == null) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity( 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_add,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Create Your Group',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Generate a unique group ID that others can use to join',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity( 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Group Created!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share this ID with others to invite them',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity( 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity( 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Group ID',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _createdGroup!.groupId,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: QrImageView(
                          data: _createdGroup!.groupId,
                          version: QrVersions.auto,
                          size: 160.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _copyGroupId,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy ID'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (_createdGroup == null)
                CustomButton(
                  text: 'Generate Group ID',
                  onPressed: _createGroup,
                  isLoading: _isLoading,
                )
              else
                Column(
                  children: [
                    CustomButton(
                      text: 'View Members',
                      onPressed: () {
                        if (_createdGroup != null) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupMembersScreen(
                                groupId: _createdGroup!.groupId,
                              ),
                            ),
                            result: true, // Trigger refresh in HomeScreen
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

