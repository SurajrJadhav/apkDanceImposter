import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String name;
  final DateTime dob;
  final String email;
  final DateTime createdAt;
  final List<String> groupIds;

  UserModel({
    required this.userId,
    required this.name,
    required this.dob,
    required this.email,
    required this.createdAt,
    this.groupIds = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'dob': Timestamp.fromDate(dob),
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'groupIds': groupIds,
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      dob: (map['dob'] as Timestamp).toDate(),
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      groupIds: List<String>.from(map['groupIds'] ?? []),
    );
  }

  // Create from Firestore DocumentSnapshot
  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  // Copy with method for updates
  UserModel copyWith({
    String? userId,
    String? name,
    DateTime? dob,
    String? email,
    DateTime? createdAt,
    List<String>? groupIds,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}
