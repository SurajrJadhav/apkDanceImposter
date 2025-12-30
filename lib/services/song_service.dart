import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/song_model.dart';

class SongService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Pick MP3 files from device
  Future<List<File>?> pickSongFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths.map((path) => File(path!)).toList();
      }
      return null;
    } catch (e) {
      throw 'Failed to pick files: $e';
    }
  }

  // Upload song to Firebase Storage
  Future<SongModel> uploadSong({
    required File file,
    required String type, // 'sad' or 'dance'
    required String userId,
  }) async {
    try {
      final songId = _uuid.v4();
      final fileName = file.path.split('/').last;
      final storageRef = _storage.ref().child('songs/$userId/$songId/$fileName');

      // Upload file
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Create song model
      final song = SongModel(
        id: songId,
        title: fileName,
        downloadUrl: downloadUrl,
        type: type,
        userId: userId,
        createdAt: DateTime.now(),
        expireAt: DateTime.now().add(const Duration(days: 8)),
      );

      // Save metadata to Firestore
      await _firestore
          .collection('songs')
          .doc(songId)
          .set(song.toMap());

      return song;
    } catch (e) {
      throw 'Failed to upload song: $e';
    }
  }

  // Get songs for a user by type
  Future<List<SongModel>> getSongs(String userId, String type) async {
    try {
      final querySnapshot = await _firestore
          .collection('songs')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => SongModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw 'Failed to get songs: $e';
    }
  }

  // Stream of songs for a user by type
  Stream<List<SongModel>> getSongsStream(String userId, String type) {
    return _firestore
        .collection('songs')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SongModel.fromSnapshot(doc)).toList());
  }

  // Get single song by ID
  Future<SongModel?> getSongById(String songId) async {
    try {
      final doc = await _firestore.collection('songs').doc(songId).get();
      if (doc.exists) {
        return SongModel.fromSnapshot(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete song
  Future<void> deleteSong(SongModel song) async {
    try {
      // Delete from Storage only if it's a Firebase Storage URL
      if (song.downloadUrl.contains('firebasestorage.googleapis.com')) {
        try {
          final storageRef = _storage.refFromURL(song.downloadUrl);
          await storageRef.delete();
        } catch (e) {
          debugPrint('Error deleting file from storage: $e');
          // Continue to delete from Firestore even if storage delete fails
          // (e.g. if file was already deleted by lifecycle rule)
        }
      }

      // Delete from Firestore
      await _firestore.collection('songs').doc(song.id).delete();
    } catch (e) {
      throw 'Failed to delete song: $e';
    }
  }

  // Download and cache song locally
  Future<String> downloadAndCacheSong(SongModel song) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/song_cache');
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final filePath = '${cacheDir.path}/${song.id}.mp3';
      final file = File(filePath);

      // Check if already cached
      if (await file.exists()) {
        return filePath;
      }

      // Handle Asset URLs (Bundled Songs)
      if (song.downloadUrl.startsWith('asset://')) {
        final assetPath = song.downloadUrl.replaceFirst('asset://', '');
        // Load asset data
        final byteData = await rootBundle.load(assetPath);
        final bytes = byteData.buffer.asUint8List();
        // Write to cache file
        await file.writeAsBytes(bytes);
        return filePath;
      }

      // Check if it's a Firebase Storage URL or a regular HTTP URL
      if (song.downloadUrl.startsWith('http') && !song.downloadUrl.contains('firebasestorage')) {
        // Download from regular URL
        final response = await http.get(Uri.parse(song.downloadUrl));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        } else {
          throw 'Failed to download song: ${response.statusCode}';
        }
      } else {
        // Download from Firebase Storage
        final storageRef = _storage.refFromURL(song.downloadUrl);
        await storageRef.writeToFile(file);
      }

      return filePath;
    } catch (e) {
      throw 'Failed to download song: $e';
    }
  }

  // Get cached song path if exists
  Future<String?> getCachedSongPath(String songId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/song_cache/$songId.mp3';
      final file = File(filePath);

      if (await file.exists()) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear song cache
  Future<void> clearCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/song_cache');
      
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      throw 'Failed to clear cache: $e';
    }
  }

  // Add default starter songs
  Future<void> addDefaultSongs(String userId) async {
    try {
      final List<Map<String, String>> defaultSongs = [
        {
          'title': 'Funky Energy (Dance)',
          'url': 'asset://assets/songs/funky_energy.mp3',
          'type': 'dance',
        },
        {
          'title': 'Upbeat Groove (Dance)',
          'url': 'asset://assets/songs/upbeat_groove.mp3',
          'type': 'dance',
        },
        {
          'title': 'Melancholy Piano (Sad)',
          'url': 'asset://assets/songs/melancholy_piano.mp3',
          'type': 'sad',
        },
        {
          'title': 'Slow Motion (Sad)',
          'url': 'asset://assets/songs/slow_motion.mp3',
          'type': 'sad',
        },
      ];

      // Get existing songs to prevent duplicates
      final existingSongsSnapshot = await _firestore
          .collection('songs')
          .where('userId', isEqualTo: userId)
          .get();
      
      final existingTitles = existingSongsSnapshot.docs
          .map((doc) => doc.data()['title'] as String)
          .toSet();

      int addedCount = 0;

      for (final songData in defaultSongs) {
        if (existingTitles.contains(songData['title'])) {
          continue; // Skip if already exists
        }

        final songId = _uuid.v4();
        
        final song = SongModel(
          id: songId,
          title: songData['title']!,
          downloadUrl: songData['url']!,
          type: songData['type']!,
          userId: userId,
          createdAt: DateTime.now(),
          expireAt: DateTime.now().add(const Duration(days: 8)),
        );

        await _firestore
            .collection('songs')
            .doc(songId)
            .set(song.toMap());
        
        addedCount++;
      }
      
      if (addedCount == 0) {
        throw 'Starter pack already added!';
      }
    } catch (e) {
      throw 'Failed to add default songs: $e';
    }
  }
}
