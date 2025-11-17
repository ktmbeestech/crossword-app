import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../local_storage/local_storage.services.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService instance = AudioService._internal();
  factory AudioService() => instance;
  AudioService._internal();

  final ValueNotifier<bool> _musicEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _sfxEnabledNotifier = ValueNotifier<bool>(true);
  ValueListenable<bool> get musicEnabledListenable => _musicEnabledNotifier;
  ValueListenable<bool> get sfxEnabledListenable => _sfxEnabledNotifier;
  bool get isMusicEnabled => _musicEnabledNotifier.value;
  bool get isSfxEnabled => _sfxEnabledNotifier.value;

  AudioPlayer? _player;
  AudioPlayer? _sfxPlayer;
  bool _initialized = false;

  static const String _musicEnabledKey = 'music_enabled';
  static const String _sfxEnabledKey = 'sfx_enabled';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final saved = await storageInstance.getData(key: _musicEnabledKey);
    if (saved != null) {
      _musicEnabledNotifier.value = saved == 'true';
    }
    final savedSfx = await storageInstance.getData(key: _sfxEnabledKey);
    if (savedSfx != null) {
      _sfxEnabledNotifier.value = savedSfx == 'true';
    }
    debugPrint('[AudioService] initialize: musicEnabled=${_musicEnabledNotifier.value}, sfxEnabled=${_sfxEnabledNotifier.value}');
    try {
      WidgetsBinding.instance.addObserver(this);
      _player ??= AudioPlayer();
      try {
        await _player!.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gain,
              isSpeakerphoneOn: true,
              stayAwake: false,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {
                AVAudioSessionOptions.mixWithOthers,
              },
            ),
          ),
        );
      } catch (e, st) {
        debugPrint('[AudioService] setAudioContext failed: $e');
        debugPrint('$st');
      }
      try {
        _player!.onPlayerStateChanged.listen((state) {
          debugPrint('[AudioService] onPlayerStateChanged: $state');
        });
        _player!.onPlayerComplete.listen((_) {
          debugPrint('[AudioService] onPlayerComplete');
        });
      } catch (e) {
        debugPrint('[AudioService] attaching listeners failed: $e');
      }
      try {
        await _player!.setPlayerMode(PlayerMode.mediaPlayer);
      } catch (e) {
        debugPrint('[AudioService] setPlayerMode failed: $e');
      }
      await _player!.setReleaseMode(ReleaseMode.loop);
      try {
        _sfxPlayer ??= AudioPlayer();
        try {
          await _sfxPlayer!.setAudioContext(
            AudioContext(
              android: AudioContextAndroid(
                // Route SFX through MEDIA stream so device notification settings don't mute it
                contentType: AndroidContentType.music,
                usageType: AndroidUsageType.media,
                audioFocus: AndroidAudioFocus.none,
                isSpeakerphoneOn: true,
                stayAwake: false,
              ),
              iOS: AudioContextIOS(
                category: AVAudioSessionCategory.playback,
                options: {
                  AVAudioSessionOptions.mixWithOthers,
                },
              ),
            ),
          );
        } catch (e) {
          debugPrint('[AudioService] sfx setAudioContext failed: $e');
        }
        await _sfxPlayer!.setPlayerMode(PlayerMode.mediaPlayer);
        await _sfxPlayer!.setReleaseMode(ReleaseMode.stop);
        await _sfxPlayer!.setVolume(1.0);
      } catch (e) {
        debugPrint('[AudioService] sfx player setup failed: $e');
      }
      if (isMusicEnabled) {
        await _safePlay();
      }
    } catch (e, st) {
      debugPrint('[AudioService] initialize setup failed: $e');
      debugPrint('$st');
    }
  }

  Future<void> _persist() async {
    await storageInstance.setData(
      key: _musicEnabledKey,
      value: _musicEnabledNotifier.value.toString(),
    );
  }

  Future<void> _persistSfx() async {
    await storageInstance.setData(
      key: _sfxEnabledKey,
      value: _sfxEnabledNotifier.value.toString(),
    );
  }

  Future<void> toggleMusic() async {
    try {
      await initialize();
      if (isMusicEnabled) {
        debugPrint('[AudioService] toggleMusic -> disabling');
        _musicEnabledNotifier.value = false;
        if (_player != null) {
          try {
            final state = _player!.state;
            final currentState = state is Future ? await state : state;
            debugPrint('[AudioService] toggleMusic: currentState=$currentState');
            await _player!.stop();
            debugPrint('[AudioService] toggleMusic: stopped');
          } catch (e, st) {
            debugPrint('[AudioService] toggleMusic: state/pause handling failed: $e');
            debugPrint('$st');
            try {
              await _player!.stop();
            } catch (_) {}
          }
          // Dispose the player to avoid lingering platform state
          try {
            await _player!.release();
          } catch (_) {}
          try {
            await _player!.dispose();
          } catch (_) {}
          _player = null;
        }
      } else {
        debugPrint('[AudioService] toggleMusic -> enabling');
        _musicEnabledNotifier.value = true;
        await _safeResume();
      }
      await _persist();
    } catch (e, st) {
      debugPrint('[AudioService] toggleMusic: unexpected error $e');
      debugPrint('$st');
    }
  }

  Future<void> toggleSfx() async {
    await initialize();
    _sfxEnabledNotifier.value = !_sfxEnabledNotifier.value;
    debugPrint('[AudioService] toggleSfx -> ${_sfxEnabledNotifier.value ? 'enabling' : 'disabling'}');
    await _persistSfx();
  }

  Future<void> _safePlay() async {
    try {
      _player ??= AudioPlayer();
      try {
        await _player!.setAudioContext(
          AudioContext(
            android: AudioContextAndroid(
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gain,
              isSpeakerphoneOn: true,
              stayAwake: false,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {
                AVAudioSessionOptions.mixWithOthers,
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('[AudioService] _safePlay: setAudioContext failed: $e');
      }
      try {
        await _player!.setPlayerMode(PlayerMode.mediaPlayer);
      } catch (e) {
        debugPrint('[AudioService] _safePlay: setPlayerMode failed: $e');
      }
      await _player!.setReleaseMode(ReleaseMode.loop);
      await _player!.setVolume(1.0);
      await _player!.setSource(AssetSource('audio/crossword_music.mp3'));
      await _player!.resume();
      debugPrint('[AudioService] _safePlay: started');

      await Future.delayed(const Duration(milliseconds: 200));
      final state = await _player!.state;
      debugPrint('[AudioService] _safePlay: state after start -> $state');
      if (state != PlayerState.playing) {
        try {
          await _player!.resume();
          debugPrint('[AudioService] _safePlay: resume fallback attempted');
        } catch (e) {
          debugPrint('[AudioService] _safePlay: resume fallback failed: $e');
        }
      }
    } catch (_) {
      debugPrint('[AudioService] _safePlay: failed to start');
    }
  }

  Future<void> _safeResume() async {
    try {
      if (_player == null) {
        debugPrint('[AudioService] _safeResume: no player, calling _safePlay');
        await _safePlay();
        return;
      }
      PlayerState current;
      try {
        final state = _player!.state;
        current = state is Future ? await state : state;
      } catch (_) {
        current = PlayerState.stopped;
      }
      debugPrint('[AudioService] _safeResume: currentState=$current');
      if (current == PlayerState.stopped || current == PlayerState.completed) {
        await _safePlay();
        return;
      }
      try {
        await _player!.resume();
        debugPrint('[AudioService] _safeResume: resumed');
      } catch (e) {
        debugPrint('[AudioService] _safeResume: resume failed -> $e, falling back to _safePlay');
        await _safePlay();
      }
    } catch (_) {
      debugPrint('[AudioService] _safeResume failed, calling _safePlay');
      await _safePlay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (isMusicEnabled) {
        _safeResume();
      }
    }
  }

  Future<void> playClick() async {
    await _playAssetSfx('audio/ClickAudio.mp3');
  }

  Future<void> playIdea() async {
    await _playAssetSfx('audio/ding-idea-.mp3');
  }

  Future<void> playMistake() async {
    await _playAssetSfx('audio/MistakeSound.mp3');
  }

  Future<void> _playAssetSfx(String assetPath) async {
    try {
      await initialize();
      if (!isSfxEnabled) {
        debugPrint('[AudioService] SFX disabled, skipping: $assetPath');
        return;
      }

      if (_sfxPlayer == null) {
        debugPrint('[AudioService] _playAssetSfx: sfxPlayer was null, reinitializing');
        await initialize();
      }
      if (_sfxPlayer == null) return;

      // Duck background music slightly while SFX plays so it is clearly audible
      double previousMusicVol = 1.0;
      try {
        if (_player != null && isMusicEnabled) {
          previousMusicVol = 1.0; // we always set to 1.0 when starting music
          await _player!.setVolume(0.25);
        }
      } catch (_) {}

      try {
        await _sfxPlayer!.setVolume(1.0);
        await _sfxPlayer!.play(AssetSource(assetPath));
        debugPrint('[AudioService] SFX playing: $assetPath');
      } catch (e) {
        debugPrint('[AudioService] _playAssetSfx play failed for $assetPath (shared): $e');
        // Fallback: try with a fresh ephemeral player
        try {
          final temp = AudioPlayer();
          await temp.setAudioContext(
            AudioContext(
              android: AudioContextAndroid(
                contentType: AndroidContentType.music,
                usageType: AndroidUsageType.media,
                audioFocus: AndroidAudioFocus.none,
                isSpeakerphoneOn: true,
                stayAwake: false,
              ),
              iOS: AudioContextIOS(
                category: AVAudioSessionCategory.playback,
                options: { AVAudioSessionOptions.mixWithOthers },
              ),
            ),
          );
          await temp.setPlayerMode(PlayerMode.mediaPlayer);
          await temp.setReleaseMode(ReleaseMode.stop);
          await temp.setVolume(1.0);
          await temp.play(AssetSource(assetPath));
          temp.onPlayerComplete.first.then((_) async {
            try { await temp.dispose(); } catch (_) {}
          });
          debugPrint('[AudioService] SFX playing via fallback: $assetPath');
        } catch (e2) {
          debugPrint('[AudioService] _playAssetSfx fallback failed for $assetPath: $e2');
        }
      }

      // Restore music volume after a short delay
      Future.delayed(const Duration(milliseconds: 900), () async {
        try {
          if (_player != null && isMusicEnabled) {
            await _player!.setVolume(previousMusicVol);
          }
        } catch (_) {}
      });
    } catch (e) {
      debugPrint('[AudioService] _playAssetSfx failed for $assetPath: $e');
    }
  }
}
