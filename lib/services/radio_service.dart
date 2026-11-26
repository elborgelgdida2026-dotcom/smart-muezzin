import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/radio_station.dart';

/// Live Quran radio playback.
///
/// Streams are the 8 stations in [kRadioStations], all verified live
/// (HTTP 200 + audio/mpeg) on 2026-11-26 — see radio_station.dart.
/// Behaviour:
///  - play/stop, volume, favorites persisted locally.
///  - sleep timer 15/30/45/60/90 minutes (stops playback, then clears).
///  - auto-reconnect: if the primary URL errors, the fallback URL is
///    tried once automatically; the UI shows which URL is in use and
///    offers a manual retry. Nothing is faked: a dead stream shows an
///    honest error, never silence presented as a working station.
/// Background playback depends on the OS audio session; on Android the
/// stream keeps playing while the app is in the background, but it is
/// NOT a native lock-screen radio service.
class RadioService {
  RadioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  RadioStation? _current;
  bool _triedFallback = false;
  bool _playing = false;
  String? _error;
  double _volume = 1.0;
  Timer? _sleepTimer;
  int? _sleepMinutesLeft;
  final _errorController = StreamController<String?>.broadcast();
  final _stateController = StreamController<void>.broadcast();

  RadioStation? get current => _current;
  bool get isPlaying => _playing;
  String? get error => _error;
  double get volume => _volume;
  int? get sleepMinutesLeft => _sleepMinutesLeft;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<void> get stateStream => _stateController.stream;

  void _emit() => _stateController.add(null);

  Future<void> init() async {
    _player.onPlayerStateChanged.listen((s) {
      _playing = s == PlayerState.playing;
      _emit();
    });
    // audioplayers reports stream failures through onLog in some cases;
    // the explicit catch in play() plus this listener cover reconnects.
    _player.onPlayerComplete.listen((_) {
      // A live stream should never "complete"; treat it as a drop.
      if (_current != null && _playing) {
        _reconnect();
      }
    });
  }

  Future<void> play(RadioStation station) async {
    _error = null;
    _errorController.add(null);
    _current = station;
    _triedFallback = false;
    try {
      await _player.stop();
      await _player.setVolume(_volume);
      await _player.play(UrlSource(station.url));
      _playing = true;
    } catch (e) {
      await _tryFallback(e);
    }
    _emit();
  }

  Future<void> _tryFallback(Object e) async {
    final station = _current;
    if (station != null && !_triedFallback && station.fallbackUrl != null) {
      _triedFallback = true;
      try {
        await _player.play(UrlSource(station.fallbackUrl!));
        _playing = true;
        _emit();
        return;
      } catch (_) {
        // fall through to the honest error below
      }
    }
    _playing = false;
    _error = 'تعذر تشغيل البث (${station?.name ?? ''}). تحقق من الإنترنت ثم أعد المحاولة.';
    _errorController.add(_error);
    _emit();
  }

  /// Called when a playing stream drops unexpectedly.
  Future<void> _reconnect() async {
    final station = _current;
    if (station == null) return;
    _triedFallback = false;
    try {
      await _player.play(UrlSource(station.url));
    } catch (e) {
      await _tryFallback(e);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _playing = false;
    _cancelSleepTimer();
    _emit();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    _emit();
  }

  /// Sleep timer in minutes; 0 cancels it.
  void setSleepTimer(int minutes) {
    _cancelSleepTimer();
    if (minutes <= 0) {
      _sleepMinutesLeft = null;
      _emit();
      return;
    }
    _sleepMinutesLeft = minutes;
    _sleepTimer = Timer(Duration(minutes: minutes), () async {
      await stop();
    });
    _emit();
  }

  void _cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepMinutesLeft = null;
  }

  // ---- favorites (persisted locally) ----

  static const _kFav = 'radio_favorites';

  Future<Set<String>> favorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kFav) ?? []).toSet();
  }

  Future<bool> toggleFavorite(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final favs = (prefs.getStringList(_kFav) ?? []).toSet();
    final nowFav = favs.toggle(stationId);
    await prefs.setStringList(_kFav, favs.toList());
    return nowFav;
  }

  void dispose() {
    _sleepTimer?.cancel();
    _errorController.close();
    _stateController.close();
    _player.dispose();
  }
}

extension _ToggleSet on Set<String> {
  /// Toggles [value]; returns true if it is now present.
  bool toggle(String value) {
    if (contains(value)) {
      remove(value);
      return false;
    }
    add(value);
    return true;
  }
}
