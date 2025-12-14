class GameState {
  final String status; // 'idle', 'playing', 'paused'
  final String? imposterUserId;
  final Map<String, SongAssignment> songAssignments;
  final Map<String, String> votes; // userId -> votedUserId
  final DateTime? playStartTime;
  final String? sadSongId;
  final String? danceSongId;
  final DateTime updatedAt;

  GameState({
    required this.status,
    this.imposterUserId,
    required this.songAssignments,
    this.votes = const {},
    this.playStartTime,
    this.sadSongId,
    this.danceSongId,
    required this.updatedAt,
  });

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'imposterUserId': imposterUserId,
      'songAssignments': songAssignments.map((key, value) => MapEntry(key, value.toMap())),
      'votes': votes,
      'playStartTime': playStartTime?.toIso8601String(),
      'sadSongId': sadSongId,
      'danceSongId': danceSongId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Firestore map
  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      status: map['status'] as String? ?? 'idle',
      imposterUserId: map['imposterUserId'] as String?,
      songAssignments: (map['songAssignments'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              SongAssignment.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      votes: (map['votes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value as String),
          ) ??
          {},
      playStartTime: map['playStartTime'] != null
          ? DateTime.parse(map['playStartTime'] as String)
          : null,
      sadSongId: map['sadSongId'] as String?,
      danceSongId: map['danceSongId'] as String?,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  // Create idle state
  factory GameState.idle() {
    return GameState(
      status: 'idle',
      songAssignments: {},
      votes: {},
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method
  GameState copyWith({
    String? status,
    String? imposterUserId,
    Map<String, SongAssignment>? songAssignments,
    Map<String, String>? votes,
    DateTime? playStartTime,
    String? sadSongId,
    String? danceSongId,
    DateTime? updatedAt,
  }) {
    return GameState(
      status: status ?? this.status,
      imposterUserId: imposterUserId ?? this.imposterUserId,
      songAssignments: songAssignments ?? this.songAssignments,
      votes: votes ?? this.votes,
      playStartTime: playStartTime ?? this.playStartTime,
      sadSongId: sadSongId ?? this.sadSongId,
      danceSongId: danceSongId ?? this.danceSongId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPlaying => status == 'playing';
  bool get isPaused => status == 'paused';
  bool get isIdle => status == 'idle';
  bool get isVoting => status == 'voting';
  bool get isEnded => status == 'ended';
}

class SongAssignment {
  final String songType; // 'sad' or 'dance'
  final String songId;

  SongAssignment({
    required this.songType,
    required this.songId,
  });

  Map<String, dynamic> toMap() {
    return {
      'songType': songType,
      'songId': songId,
    };
  }

  factory SongAssignment.fromMap(Map<String, dynamic> map) {
    return SongAssignment(
      songType: map['songType'] as String,
      songId: map['songId'] as String,
    );
  }
}
