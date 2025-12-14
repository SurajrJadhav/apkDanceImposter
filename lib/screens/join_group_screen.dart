import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'qr_scanner_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupIdController = TextEditingController();
  final GroupService _groupService = GroupService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  String? _validateGroupId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a group ID';
    }
    if (value.length != 6) {
      return 'Group ID must be 6 characters';
    }
    return null;
  }

  Future<void> _joinGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _authService.getCurrentUserData();
      if (currentUser == null) {
        throw 'User not found';
      }

      await _groupService.joinGroup(
        groupId: _groupIdController.text.trim().toUpperCase(),
        userId: currentUser.userId,
        userName: currentUser.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home with success result
        Navigator.pop(context, true);
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Join Group',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black87.withOpacity( 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group,
                    size: 80,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Join a Group',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the 6-character group ID shared by the group creator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRScannerScreen(),
                      ),
                    );
                    if (result != null && result is String) {
                      setState(() {
                        _groupIdController.text = result;
                      });
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  label: 'Group ID',
                  hint: 'Enter 6-character ID',
                  controller: _groupIdController,
                  validator: _validateGroupId,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Group IDs are case-insensitive',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                CustomButton(
                  text: 'Join Group',
                  onPressed: _joinGroup,
                  isLoading: _isLoading,
                  backgroundColor: Colors.black87,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ask the group creator to share their unique group ID with you',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

