import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Generate unique 6-character group ID
  String _generateGroupId() {
    // Generate UUID and take first 6 characters (alphanumeric)
    String uuid = _uuid.v4().replaceAll('-', '').substring(0, 6).toUpperCase();
    return uuid;
  }

  // Create a new group
  Future<GroupModel> createGroup({
    required String creatorId,
    required String creatorName,
  }) async {
    try {
      // Generate unique ID
      String groupId = _generateGroupId();

      // Check if ID already exists (very unlikely but safe)
      DocumentSnapshot existingGroup = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      // If exists, generate new one
      while (existingGroup.exists) {
        groupId = _generateGroupId();
        existingGroup = await _firestore
            .collection('groups')
            .doc(groupId)
            .get();
      }

      // Create group with creator as first member
      GroupModel group = GroupModel(
        groupId: groupId,
        creatorId: creatorId,
        creatorName: creatorName,
        members: [
          GroupMember(
            userId: creatorId,
            name: creatorName,
            joinedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore
          .collection('groups')
          .doc(groupId)
          .set(group.toMap());

      // Update user's groupIds
      await _firestore
          .collection('users')
          .doc(creatorId)
          .update({
        'groupIds': FieldValue.arrayUnion([groupId]),
      });

      return group;
    } catch (e) {
      throw 'Failed to create group: ${e.toString()}';
    }
  }

  // Join an existing group
  Future<void> joinGroup({
    required String groupId,
    required String userId,
    required String userName,
  }) async {
    try {
      // Check if group exists
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId.toUpperCase())
          .get();

      if (!groupDoc.exists) {
        throw 'Group not found. Please check the ID.';
      }

      GroupModel group = GroupModel.fromSnapshot(groupDoc);

      // Check if user already in group
      bool alreadyMember = group.members.any((m) => m.userId == userId);
      if (alreadyMember) {
        throw 'You are already a member of this group.';
      }

      // Add user to group members
      GroupMember newMember = GroupMember(
        userId: userId,
        name: userName,
        joinedAt: DateTime.now(),
      );

      await _firestore
          .collection('groups')
          .doc(groupId.toUpperCase())
          .update({
        'members': FieldValue.arrayUnion([newMember.toMap()]),
      });

      // Update user's groupIds
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'groupIds': FieldValue.arrayUnion([groupId.toUpperCase()]),
      });
    } catch (e) {
      if (e.toString().contains('Group not found') || 
          e.toString().contains('already a member')) {
        rethrow;
      }
      throw 'Failed to join group: ${e.toString()}';
    }
  }

  // Get group by ID
  Future<GroupModel?> getGroup(String groupId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('groups')
          .doc(groupId.toUpperCase())
          .get();

      if (doc.exists) {
        return GroupModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      throw 'Failed to get group: ${e.toString()}';
    }
  }

  // Stream of group members (real-time updates)
  Stream<GroupModel?> getGroupStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId.toUpperCase())
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return GroupModel.fromSnapshot(doc);
      }
      return null;
    });
  }

  // Get all groups for a user
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      // Get user's groupIds
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];

      UserModel user = UserModel.fromSnapshot(userDoc);
      
      if (user.groupIds.isEmpty) return [];

      // Get all groups
      List<GroupModel> groups = [];
      for (String groupId in user.groupIds) {
        GroupModel? group = await getGroup(groupId);
        if (group != null) {
          groups.add(group);
        }
      }

      return groups;
    } catch (e) {
      throw 'Failed to get user groups: ${e.toString()}';
    }
  }

  // Delete a group (Creator only)
  Future<void> deleteGroup(String groupId, String creatorId) async {
    try {
      // Delete group document
      await _firestore.collection('groups').doc(groupId.toUpperCase()).delete();

      // Remove group ID from creator's list
      await _firestore.collection('users').doc(creatorId).update({
        'groupIds': FieldValue.arrayRemove([groupId.toUpperCase()]),
      });
    } catch (e) {
      throw 'Failed to delete group: ${e.toString()}';
    }
  }

  // Leave a group
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    try {
      DocumentSnapshot groupDoc = await _firestore
          .collection('groups')
          .doc(groupId.toUpperCase())
          .get();

      if (!groupDoc.exists) {
        throw 'Group not found.';
      }

      GroupModel group = GroupModel.fromSnapshot(groupDoc);

      // Find and remove the member
      List<Map<String, dynamic>> updatedMembers = group.members
          .where((m) => m.userId != userId)
          .map((m) => m.toMap())
          .toList();

      // Update group
      await _firestore
          .collection('groups')
          .doc(groupId.toUpperCase())
          .update({
        'members': updatedMembers,
      });

      // Update user's groupIds
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'groupIds': FieldValue.arrayRemove([groupId.toUpperCase()]),
      });

      // If no members left, delete the group
      if (updatedMembers.isEmpty) {
        await _firestore
            .collection('groups')
            .doc(groupId.toUpperCase())
            .delete();
      }
    } catch (e) {
      throw 'Failed to leave group: ${e.toString()}';
    }
  }
}
