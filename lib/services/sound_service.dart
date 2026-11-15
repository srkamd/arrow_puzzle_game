import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool sfxEnabled = true;

  final Map<String, Uint8List> _cachedAudioBuffers = {};
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Juicy Musical Marimba Pop for Correct Moves (C5, D5, E5, G5, A5, C6)
      final pentatonicNotes = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5];
      for (int i = 0; i < pentatonicNotes.length; i++) {
        _cachedAudioBuffers['pop_$i'] = _generateMarimbaPopWav(pentatonicNotes[i]);
      }

      // 2. Distinct Gamey Error Buzz / Bonk for Wrong Moves
      _cachedAudioBuffers['blocked'] = _generateErrorBuzzWav();

      // 3. Star Collect Sparkle Chime
      _cachedAudioBuffers['star_collect'] = _generateStarCollectWav();

      // 4. Hammer Smash Rock Crunch
      _cachedAudioBuffers['hammer'] = _generateHammerCrunchWav();

      // 5. Level Victory Melodic Fanfare
      _cachedAudioBuffers['win'] = _generateWinFanfareWav();
    } catch (e) {
      // Memory synthesis fallback
    }
  }

  // --- Sound Playback Methods ---

  Future<void> playSuccess(int combo) async {
    if (!sfxEnabled) return;
    HapticFeedback.lightImpact();

    try {
      final clampedIdx = combo.clamp(0, 5);
      final bytes = _cachedAudioBuffers['pop_$clampedIdx'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  Future<void> playBlocked() async {
    if (!sfxEnabled) return;
    // Light vibration as requested by user
    HapticFeedback.lightImpact();

    try {
      final bytes = _cachedAudioBuffers['blocked'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  Future<void> playStarCollect() async {
    if (!sfxEnabled) return;
    HapticFeedback.selectionClick();

    try {
      final bytes = _cachedAudioBuffers['star_collect'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  Future<void> playHammer() async {
    if (!sfxEnabled) return;
    HapticFeedback.mediumImpact();

    try {
      final bytes = _cachedAudioBuffers['hammer'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  Future<void> playWin() async {
    if (!sfxEnabled) return;
    HapticFeedback.vibrate();

    try {
      final bytes = _cachedAudioBuffers['win'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  // --- 100% Royalty-Free Audio Synthesizer (22050Hz Mono PCM) ---

  Uint8List _createWav(int sampleRate, List<double> samples) {
    final numSamples = samples.length;
    final byteLength = 44 + numSamples * 2;
    final buffer = ByteData(byteLength);

    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, byteLength - 8, Endian.little);
    buffer.setUint8(8, 0x57);  // W
    buffer.setUint8(9, 0x41);  // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);

    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, numSamples * 2, Endian.little);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final sample = samples[i].clamp(-1.0, 1.0);
      final intSample = (sample * 32767).toInt();
      buffer.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  // Juicy Musical Marimba Pop (Clear Move)
  Uint8List _generateMarimbaPopWav(double freq) {
    const sampleRate = 22050;
    const duration = 0.20;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final attack = min(1.0, t / 0.003);
      final decay = exp(-t * 16.0);
      final env = attack * decay;

      final pitchSlide = 1.0 + exp(-t * 80.0) * 0.08;
      final curF = freq * pitchSlide;

      final fundamental = sin(2 * pi * curF * t) * 0.72;
      final overtone = sin(2 * pi * (curF * 2.756) * t) * 0.28 * exp(-t * 30.0);

      samples.add((fundamental + overtone) * env);
    }
    return _createWav(sampleRate, samples);
  }

  // Distinct Gamey Error Buzz / Bonk (Wrong Move)
  Uint8List _generateErrorBuzzWav() {
    const sampleRate = 22050;
    const duration = 0.16;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 18.0);
      // Dual descending tones for clear error recognition
      final f1 = 180.0 - (t / duration) * 70.0;
      final f2 = 135.0 - (t / duration) * 50.0;
      final s1 = sin(2 * pi * f1 * t) * 0.55;
      final s2 = sin(2 * pi * f2 * t) * 0.35;
      final harm = (sin(2 * pi * f1 * 2 * t) > 0 ? 0.15 : -0.15);
      final val = (s1 + s2 + harm) * env * 0.82;
      samples.add(val);
    }
    return _createWav(sampleRate, samples);
  }

  // Twinkling Star Collect Bling
  Uint8List _generateStarCollectWav() {
    const sampleRate = 22050;
    const duration = 0.24;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final isSecond = t > 0.08;
      final noteT = isSecond ? t - 0.08 : t;
      final freq = isSecond ? 1760.0 : 1318.0;
      final env = exp(-noteT * 18.0);
      final s = sin(2 * pi * freq * t) * env * 0.6;
      samples.add(s);
    }
    return _createWav(sampleRate, samples);
  }

  // Hammer Smash Rock Crunch
  Uint8List _generateHammerCrunchWav() {
    const sampleRate = 22050;
    const duration = 0.22;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 18.0);
      final noise = (Random().nextDouble() * 2.0 - 1.0) * 0.45;
      final tone = sin(2 * pi * 85.0 * (1.0 - t / duration) * t) * 0.55;
      samples.add((tone + noise) * env * 0.85);
    }
    return _createWav(sampleRate, samples);
  }

  // Level Win Fanfare
  Uint8List _generateWinFanfareWav() {
    const sampleRate = 22050;
    const duration = 0.50;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];
    final notes = [523.25, 659.25, 783.99, 1046.50];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final step = ((t / duration) * 4).floor().clamp(0, 3);
      final freq = notes[step];
      final stepT = t - (step * (duration / 4.0));
      final env = exp(-stepT * 12.0);
      final s = sin(2 * pi * freq * t) * env * 0.7;
      samples.add(s);
    }
    return _createWav(sampleRate, samples);
  }
}
