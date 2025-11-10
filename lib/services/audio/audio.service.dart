import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../local_storage/local_storage.services.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService instance = AudioService._internal();
  factory AudioService() => instance;
  AudioService._internal();

  final ValueNotifier<bool> _musicEnabledNotifier = ValueNotifier<bool>(true);
  ValueListenable<bool> get musicEnabledListenable => _musicEnabledNotifier;
  bool get isMusicEnabled => _musicEnabledNotifier.value;

  AudioPlayer? _player;
  bool _initialized = false;

  static const String _musicEnabledKey = 'music_enabled';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final saved = await storageInstance.getData(key: _musicEnabledKey);
    if (saved != null) {
      _musicEnabledNotifier.value = saved == 'true';
    }
    debugPrint('[AudioService] initialize: musicEnabled=${_musicEnabledNotifier.value}');
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

  Future<void> toggleMusic() async {
    await initialize();
    if (isMusicEnabled) {
      debugPrint('[AudioService] toggleMusic -> disabling');
      _musicEnabledNotifier.value = false;
      if (_player != null) {
        await _player!.pause();
      }
    } else {
      debugPrint('[AudioService] toggleMusic -> enabling');
      _musicEnabledNotifier.value = true;
      await _safeResume();
    }
    await _persist();
  }

  Future<void> _safePlay() async {
    try {
      _player ??= AudioPlayer();
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
      await _player!.resume();
      debugPrint('[AudioService] _safeResume: resumed');
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
}
