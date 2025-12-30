import 'package:flutter/material.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../models/game_state_model.dart';
import '../models/group_model.dart';

class GameScreen extends StatefulWidget {
  final String groupId;

  const GameScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final GameService _gameService = GameService();
  final AudioService _audioService = AudioService();
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  
  late AnimationController _animationController;
  StreamSubscription<GameState?>? _gameStateSubscription;
  
  String? _currentUserId;
  GameState? _gameState;
  DateTime? _lastPlayStartTime;
  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadUserAndSubscribe();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioService.dispose();
    _gameStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserAndSubscribe() async {
    final user = await _authService.getCurrentUserData();
    if (mounted) {
      setState(() {
        _currentUserId = user?.userId;
      });
    }

    _gameStateSubscription = _gameService.getGameStateStream(widget.groupId).listen((gameState) {
      if (!mounted) return;
      
      setState(() {
        _gameState = gameState;
      });

      if (gameState != null) {
        _handleGameState(gameState);
      }
    });
  }

  Future<void> _handleGameState(GameState gameState) async {
    if (_currentUserId == null) return;

    try {
      // Handle Idle/Stop
      // Handle Idle/Stop
      if (gameState.isIdle) {
        await _audioService.stop();
        // Do NOT pop here. Let the UI show the "Waiting" state.
        return;
      }

      // Handle Pause
      if (gameState.isPaused) {
        if (_lastStatus != 'paused') {
          await _audioService.pause();
          _lastStatus = 'paused';
        }
        return;
      }

      // Handle Playing
      if (gameState.isPlaying) {
        // Check if we need to start/restart playback
        // Play if:
        // 1. Status changed to playing
        // 2. Play start time changed (sync adjustment or resume)
        // 3. Last status was not playing
        if (_lastStatus != 'playing' || 
            gameState.playStartTime != _lastPlayStartTime) {
          
          _lastStatus = 'playing';
          _lastPlayStartTime = gameState.playStartTime;

          // Get song for current user
          final song = await _gameService.getSongForUser(
            groupId: widget.groupId,
            userId: _currentUserId!,
            gameState: gameState,
          );

          if (song != null && gameState.playStartTime != null) {
            await _audioService.playSong(
              song: song,
              startTime: gameState.playStartTime!,
            );
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Leave Game',
          ),
          actions: [
            // Show group ID
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  'Group: ${widget.groupId}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing music icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_animationController.value * 0.2),
                      child: Container(
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).primaryColor.withOpacity( 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Icon(
                          _gameState?.isPlaying == true
                              ? Icons.music_note
                              : Icons.pause,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 48),

                // Status text
                Text(
                  _gameState?.isPlaying == true
                      ? 'Listening...'
                      : _gameState?.isPaused == true
                          ? 'Paused'
                          : 'Lobby',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Subtitle
                Text(
                  _gameState?.isPlaying == true
                      ? 'Listen carefully to the music'
                      : _gameState?.isPaused == true
                          ? 'Game paused by creator'
                          : 'Waiting for host to start...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity( 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Audio player state
                if (_gameState?.isPlaying == true)
                  StreamBuilder<PlayerState>(
                    stream: _audioService.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final isPlaying = playerState?.playing ?? false;

                      return Column(
                        children: [
                          // Playing indicator
                          if (isPlaying)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Playing',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity( 0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),

                // Voting Phase
                if (_gameState?.isVoting == true) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Who is the Imposter?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<GroupModel?>(
                      stream: _groupService.getGroupStream(widget.groupId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        
                        final group = snapshot.data!;
                        final members = group.members
                            .where((m) => m.userId != group.creatorId) // Don't vote for creator
                            .toList();

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final isSelected = _gameState?.votes[_currentUserId] == member.userId;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_currentUserId != null) {
                                    _gameService.castVote(
                                      groupId: widget.groupId,
                                      userId: _currentUserId!,
                                      votedUserId: member.userId,
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected 
                                      ? Colors.red 
                                      : Colors.white.withOpacity( 0.1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(member.name),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],

                // Results Phase
                if (_gameState?.isEnded == true) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Game Over',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_gameState?.imposterUserId != null)
                    FutureBuilder<GroupModel?>(
                      future: _groupService.getGroup(widget.groupId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final group = snapshot.data!;
                        final imposter = group.members.firstWhere(
                          (m) => m.userId == _gameState!.imposterUserId,
                          orElse: () => GroupMember(userId: '', name: 'Unknown', joinedAt: DateTime.now()),
                        );

                        return Column(
                          children: [
                            Text(
                              'The Imposter was:',
                              style: TextStyle(
                                color: Colors.white.withOpacity( 0.7),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              imposter.name,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: () {
                                // Reset game state locally if needed, but mainly just wait for host
                                // or manually leave
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Waiting for Host...'),
                            ),
                          ],
                        );
                      },
                    ),
                ],

                if (_gameState?.isPlaying != true && 
                    _gameState?.isVoting != true && 
                    _gameState?.isEnded != true)
                  const Spacer(),

                // Warning text
                if (_gameState?.isPlaying == true)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '⚠️ Do not close this screen during the game',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity( 0.5),
                      ),
                      textAlign: TextAlign.center,
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

