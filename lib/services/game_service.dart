import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_state_model.dart';
import '../models/group_model.dart';
import '../models/song_model.dart';
import 'song_service.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SongService _songService = SongService();
  final Random _random = Random();

  // Start game with random imposter and song selection
  Future<void> startGame({
    required String groupId,
    required String creatorId,
    required List<GroupMember> members,
  }) async {
    try {
      // Get available songs from creator's library
      final sadSongs = await _songService.getSongs(creatorId, 'sad');
      final danceSongs = await _songService.getSongs(creatorId, 'dance');

      if (sadSongs.isEmpty || danceSongs.isEmpty) {
        throw 'Please add both sad and dance songs before starting the game';
      }

      // Select random songs
      final sadSong = sadSongs[_random.nextInt(sadSongs.length)];
      final danceSong = danceSongs[_random.nextInt(danceSongs.length)];

      // Select random imposter (excluding creator)
      final nonCreatorMembers = members.where((m) => m.userId != creatorId).toList();
      
      if (nonCreatorMembers.isEmpty) {
        throw 'Need at least one member besides creator to start game';
      }

      final imposter = nonCreatorMembers[_random.nextInt(nonCreatorMembers.length)];

      // Create song assignments
      final Map<String, SongAssignment> assignments = {};
      for (final member in members) {
        if (member.userId == creatorId) {
          // Creator doesn't play
          continue;
        }
        
        if (member.userId == imposter.userId) {
          // Imposter gets sad song
          assignments[member.userId] = SongAssignment(
            songType: 'sad',
            songId: sadSong.id,
          );
        } else {
          // Others get dance song
          assignments[member.userId] = SongAssignment(
            songType: 'dance',
            songId: danceSong.id,
          );
        }
      }

      // Create game state
      final gameState = GameState(
        status: 'playing',
        imposterUserId: imposter.userId,
        songAssignments: assignments,
        playStartTime: DateTime.now(),
        sadSongId: sadSong.id,
        danceSongId: danceSong.id,
        updatedAt: DateTime.now(),
      );

      // Update Firestore
      await _firestore.collection('groups').doc(groupId).update({
        'gameState': gameState.toMap(),
      });
    } catch (e) {
      throw 'Failed to start game: $e';
    }
  }

  // Pause game
  Future<void> pauseGame(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'gameState.status': 'paused',
        'gameState.updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to pause game: $e';
    }
  }

  // Resume game
  Future<void> resumeGame(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'gameState.status': 'playing',
        'gameState.playStartTime': DateTime.now().toIso8601String(),
        'gameState.updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to resume game: $e';
    }
  }

  // Stop game
  Future<void> stopGame(String groupId) async {
    try {
      final idleState = GameState.idle();
      await _firestore.collection('groups').doc(groupId).update({
        'gameState': idleState.toMap(),
      });
    } catch (e) {
      throw 'Failed to stop game: $e';
    }
  }

  // Get game state stream
  Stream<GameState?> getGameStateStream(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      
      final data = snapshot.data();
      if (data == null || data['gameState'] == null) {
        return GameState.idle();
      }
      
      return GameState.fromMap(data['gameState'] as Map<String, dynamic>);
    });
  }

  // Get song for user
  Future<SongModel?> getSongForUser({
    required String groupId,
    required String userId,
    required GameState gameState,
  }) async {
    try {
      final assignment = gameState.songAssignments[userId];
      if (assignment == null) return null;

      final songDoc = await _firestore
          .collection('songs')
          .doc(assignment.songId)
          .get();

      if (!songDoc.exists) return null;

      return SongModel.fromSnapshot(songDoc);
    } catch (e) {
      throw 'Failed to get song: $e';
    }
  }

  // Start voting phase
  Future<void> startVoting(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'gameState.status': 'voting',
        'gameState.updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to start voting: $e';
    }
  }

  // Cast vote
  Future<void> castVote({
    required String groupId,
    required String userId,
    required String votedUserId,
  }) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'gameState.votes.$userId': votedUserId,
        'gameState.updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to cast vote: $e';
    }
  }

  // End game and show results
  Future<void> endGame(String groupId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'gameState.status': 'ended',
        'gameState.updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to end game: $e';
    }
  }
}
