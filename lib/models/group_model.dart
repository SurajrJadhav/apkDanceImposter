import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_state_model.dart';

class GroupMember {
  final String userId;
  final String name;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.name,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }
}

class GroupModel {
  final String groupId;
  final String creatorId;
  final String creatorName;
  final List<GroupMember> members;
  final DateTime createdAt;
  final DateTime expireAt;
  final GameState? gameState;

  GroupModel({
    required this.groupId,
    required this.creatorId,
    required this.creatorName,
    required this.members,
    required this.createdAt,
    required this.expireAt,
    this.gameState,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expireAt': Timestamp.fromDate(expireAt),
      'gameState': gameState?.toMap(),
    };
  }

  // Create from Firestore document
  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      groupId: map['groupId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      members: (map['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expireAt: map['expireAt'] != null 
          ? (map['expireAt'] as Timestamp).toDate()
          : (map['createdAt'] as Timestamp).toDate().add(const Duration(hours: 1)), // Fallback for old groups
      gameState: map['gameState'] != null
          ? GameState.fromMap(map['gameState'] as Map<String, dynamic>)
          : null,
    );
  }

  // Create from Firestore DocumentSnapshot
  factory GroupModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel.fromMap(data);
  }

  // Copy with method for updates
  GroupModel copyWith({
    String? groupId,
    String? creatorId,
    String? creatorName,
    List<GroupMember>? members,
    DateTime? createdAt,
    DateTime? expireAt,
    GameState? gameState,
  }) {
    return GroupModel(
      groupId: groupId ?? this.groupId,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      expireAt: expireAt ?? this.expireAt,
      gameState: gameState ?? this.gameState,
    );
  }
}
