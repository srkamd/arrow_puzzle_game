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
  bool musicEnabled = false;

  final Map<String, Uint8List> _cachedAudioBuffers = {};
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Success Ding Combo sounds (C5 to C6)
      final pentatonicFreqs = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5];
      for (int i = 0; i < pentatonicFreqs.length; i++) {
        _cachedAudioBuffers['ding_$i'] = _generateChimeWav(pentatonicFreqs[i]);
      }

      // 2. Blocked / Error Thud
      _cachedAudioBuffers['blocked'] = _generateThudWav();

      // 3. Hammer Smash
      _cachedAudioBuffers['hammer'] = _generateHammerWav();

      // 4. Portal Warp
      _cachedAudioBuffers['warp'] = _generateWarpWav();

      // 5. Win Fanfare
      _cachedAudioBuffers['win'] = _generateWinWav();
    } catch (e) {
      // Memory synthesis fallback
    }
  }

  // --- Sound Playback Methods (In-Memory BytesSource) ---

  Future<void> playSuccess(int combo) async {
    if (!sfxEnabled) return;
    HapticFeedback.lightImpact();

    try {
      final clampedIdx = combo.clamp(0, 5);
      final bytes = _cachedAudioBuffers['ding_$clampedIdx'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  Future<void> playBlocked() async {
    if (!sfxEnabled) return;
    HapticFeedback.heavyImpact();

    try {
      final bytes = _cachedAudioBuffers['blocked'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  Future<void> playHammer() async {
    if (!sfxEnabled) return;
    HapticFeedback.heavyImpact();

    try {
      final bytes = _cachedAudioBuffers['hammer'];
      if (bytes != null) {
        await _sfxPlayer.stop();
        await _sfxPlayer.play(BytesSource(bytes));
      }
    } catch (_) {}
  }

  Future<void> playWarp() async {
    if (!sfxEnabled) return;
    HapticFeedback.mediumImpact();

    try {
      final bytes = _cachedAudioBuffers['warp'];
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

  // --- Copyright-Free Procedural Audio Generators ---

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

  Uint8List _generateChimeWav(double freq) {
    const sampleRate = 22050;
    const duration = 0.22;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 14.0);
      final val = (sin(2 * pi * freq * t) * 0.75 +
                   sin(2 * pi * (freq * 2.0) * t) * 0.25) * env;
      samples.add(val);
    }
    return _createWav(sampleRate, samples);
  }

  Uint8List _generateThudWav() {
    const sampleRate = 22050;
    const duration = 0.18;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final curFreq = 140.0 - (t / duration) * 85.0;
      final env = exp(-t * 18.0);
      final phase = (curFreq * t) % 1.0;
      final val = (phase < 0.5 ? 4.0 * phase - 1.0 : 3.0 - 4.0 * phase) * env * 0.9;
      samples.add(val);
    }
    return _createWav(sampleRate, samples);
  }

  Uint8List _generateHammerWav() {
    const sampleRate = 22050;
    const duration = 0.25;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final env = exp(-t * 16.0);
      final noise = (Random().nextDouble() * 2.0 - 1.0) * 0.5;
      final tone = sin(2 * pi * 80.0 * (1.0 - t / duration) * t) * 0.5;
      samples.add((tone + noise) * env * 0.9);
    }
    return _createWav(sampleRate, samples);
  }

  Uint8List _generateWarpWav() {
    const sampleRate = 22050;
    const duration = 0.28;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final curFreq = 320.0 + (t / duration) * 520.0;
      final env = sin(pi * (t / duration));
      final val = sin(2 * pi * curFreq * t) * env * 0.8;
      samples.add(val);
    }
    return _createWav(sampleRate, samples);
  }

  Uint8List _generateWinWav() {
    const sampleRate = 22050;
    const duration = 0.55;
    final totalSamples = (sampleRate * duration).toInt();
    final samples = <double>[];
    final notes = [523.25, 659.25, 783.99, 1046.50];

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final noteIdx = ((t / duration) * 4).floor().clamp(0, 3);
      final freq = notes[noteIdx];
      final noteT = t - (noteIdx * (duration / 4.0));
      final env = exp(-noteT * 12.0);
      final val = sin(2 * pi * freq * t) * env * 0.7;
      samples.add(val);
    }
    return _createWav(sampleRate, samples);
  }
}
