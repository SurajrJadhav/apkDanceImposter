import 'package:flutter/material.dart';
import '../services/song_service.dart';
import '../services/auth_service.dart';
import '../models/song_model.dart';

class SongLibraryScreen extends StatefulWidget {
  const SongLibraryScreen({
    super.key,
  });

  @override
  State<SongLibraryScreen> createState() => _SongLibraryScreenState();
}

class _SongLibraryScreenState extends State<SongLibraryScreen>
    with SingleTickerProviderStateMixin {
  final SongService _songService = SongService();
  final AuthService _authService = AuthService();
  late TabController _tabController;
  bool _isUploading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUserId = user?.userId;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _addStarterSongs() async {
    if (_currentUserId == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await _songService.addDefaultSongs(_currentUserId!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starter pack added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _addSongs(String type) async {
    if (_currentUserId == null) return;

    try {
      // Free upload (AdMob removed)
      _pickAndUploadSongs(type);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking song limit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadSongs(String type) async {
    try {
      final files = await _songService.pickSongFiles();
      if (files == null || files.isEmpty) return;

      setState(() {
        _isUploading = true;
      });

      if (_currentUserId == null) throw 'User not found';

      for (final file in files) {
        await _songService.uploadSong(
          file: file,
          type: type,
          userId: _currentUserId!,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${files.length} song(s) uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteSong(SongModel song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song'),
        content: Text('Delete "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _songService.deleteSong(song);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Song deleted'),
              backgroundColor: Colors.green,
            ),
          );
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
      }
    }
  }

  Widget _buildSongList(String type) {
    if (_currentUserId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<SongModel>>(
      stream: _songService.getSongsStream(_currentUserId!, type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final songs = snapshot.data ?? [];

        if (songs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $type songs yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add songs',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: type == 'sad'
                        ? Colors.blue.withOpacity( 0.1)
                        : Colors.purple.withOpacity( 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: type == 'sad' ? Colors.blue : Colors.purple,
                  ),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Added ${_formatDate(song.createdAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteSong(song),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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
          'Song Library',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (!_isUploading)
            TextButton.icon(
              onPressed: () => _addStarterSongs(),
              icon: const Icon(Icons.playlist_add, size: 18),
              label: const Text('Add Starter Pack'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(text: 'Sad Songs'),
            Tab(text: 'Dance Songs'),
          ],
        ),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading songs...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSongList('sad'),
                _buildSongList('dance'),
              ],
            ),
      floatingActionButton: _isUploading
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                final type = _tabController.index == 0 ? 'sad' : 'dance';
                _addSongs(type);
              },
              icon: const Icon(Icons.add),
              label: Text(_tabController.index == 0 ? 'Add Sad Songs' : 'Add Dance Songs'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
    );
  }
}

