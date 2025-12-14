import 'package:cloud_firestore/cloud_firestore.dart';

class SongModel {
  final String id;
  final String title;
  final String downloadUrl;
  final String type; // 'sad' or 'dance'
  final String userId; // Owner of the song
  final DateTime createdAt;
  final int? durationMs; // Optional duration in milliseconds

  SongModel({
    required this.id,
    required this.title,
    required this.downloadUrl,
    required this.type,
    required this.userId,
    required this.createdAt,
    this.durationMs,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'downloadUrl': downloadUrl,
      'type': type,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'durationMs': durationMs,
    };
  }

  // Create from Firestore map
  factory SongModel.fromMap(Map<String, dynamic> map) {
    return SongModel(
      id: map['id'] as String,
      title: map['title'] as String,
      downloadUrl: map['downloadUrl'] as String,
      type: map['type'] as String,
      userId: map['userId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      durationMs: map['durationMs'] as int?,
    );
  }

  // Create from Firestore snapshot
  factory SongModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SongModel.fromMap(data);
  }

  // Copy with method
  SongModel copyWith({
    String? id,
    String? title,
    String? downloadUrl,
    String? type,
    String? userId,
    DateTime? createdAt,
    int? durationMs,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
