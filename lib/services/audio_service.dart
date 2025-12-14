import 'package:just_audio/just_audio.dart';
import '../models/song_model.dart';
import 'song_service.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SongService _songService = SongService();

  // Load and play song with sync
  Future<void> playSong({
    required SongModel song,
    required DateTime startTime,
  }) async {
    try {
      // Download and cache song
      final filePath = await _songService.downloadAndCacheSong(song);

      // Load audio file
      await _audioPlayer.setFilePath(filePath);

      // Calculate offset for sync
      final now = DateTime.now();
      final offset = now.difference(startTime);

      // If offset is positive, seek to that position
      if (offset.inMilliseconds > 0) {
        final duration = _audioPlayer.duration;
        if (duration != null && offset < duration) {
          await _audioPlayer.seek(offset);
        }
      }

      // Start playback
      await _audioPlayer.play();
    } catch (e) {
      throw 'Failed to play song: $e';
    }
  }

  // Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      throw 'Failed to pause: $e';
    }
  }

  // Resume playback with sync
  Future<void> resume(DateTime startTime) async {
    try {
      // Calculate offset
      final now = DateTime.now();
      final offset = now.difference(startTime);

      // Seek to correct position
      if (offset.inMilliseconds > 0) {
        final duration = _audioPlayer.duration;
        if (duration != null && offset < duration) {
          await _audioPlayer.seek(offset);
        }
      }

      await _audioPlayer.play();
    } catch (e) {
      throw 'Failed to resume: $e';
    }
  }

  // Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      throw 'Failed to stop: $e';
    }
  }

  // Get current position
  Duration? get position => _audioPlayer.position;

  // Get duration
  Duration? get duration => _audioPlayer.duration;

  // Get playback state stream
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  // Dispose
  void dispose() {
    _audioPlayer.dispose();
  }
}
