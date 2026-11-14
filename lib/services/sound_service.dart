import 'dart:io';
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

  final Map<String, String> _cachedSoundPaths = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Pre-synthesize copyright-free sound effects into temp WAV files
    try {
      final tempDir = Directory.systemTemp;

      // 1. Success Ding Combo sounds (C5 to C6)
      final pentatonicFreqs = [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5];
      for (int i = 0; i < pentatonicFreqs.length; i++) {
        final bytes = _generateChimeWav(pentatonicFreqs[i]);
        final file = File('${tempDir.path}/sfx_ding_$i.wav');
        await file.writeAsBytes(bytes);
        _cachedSoundPaths['ding_$i'] = file.path;
      }

      // 2. Blocked / Error Thud
      final blockBytes = _generateThudWav();
      final blockFile = File('${tempDir.path}/sfx_blocked.wav');
      await blockFile.writeAsBytes(blockBytes);
      _cachedSoundPaths['blocked'] = blockFile.path;

      // 3. Hammer Smash
      final hammerBytes = _generateHammerWav();
      final hammerFile = File('${tempDir.path}/sfx_hammer.wav');
      await hammerFile.writeAsBytes(hammerBytes);
      _cachedSoundPaths['hammer'] = hammerFile.path;

      // 4. Portal Warp
      final warpBytes = _generateWarpWav();
      final warpFile = File('${tempDir.path}/sfx_warp.wav');
      await warpFile.writeAsBytes(warpBytes);
      _cachedSoundPaths['warp'] = warpFile.path;

      // 5. Win Fanfare
      final winBytes = _generateWinWav();
      final winFile = File('${tempDir.path}/sfx_win.wav');
      await winFile.writeAsBytes(winBytes);
      _cachedSoundPaths['win'] = winFile.path;

    } catch (e) {
      // In case temp storage is limited, fallback gracefully
    }
  }

  // --- Sound Playback Methods ---

  Future<void> playSuccess(int combo) async {
    if (!sfxEnabled) return;
    HapticFeedback.lightImpact();

    final clampedIdx = combo.clamp(0, 5);
    final path = _cachedSoundPaths['ding_$clampedIdx'];
    if (path != null) {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> playBlocked() async {
    if (!sfxEnabled) return;
    HapticFeedback.heavyImpact();

    final path = _cachedSoundPaths['blocked'];
    if (path != null) {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> playHammer() async {
    if (!sfxEnabled) return;
    HapticFeedback.heavyImpact();

    final path = _cachedSoundPaths['hammer'];
    if (path != null) {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> playWarp() async {
    if (!sfxEnabled) return;
    HapticFeedback.mediumImpact();

    final path = _cachedSoundPaths['warp'];
    if (path != null) {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> playWin() async {
    if (!sfxEnabled) return;
    HapticFeedback.vibrate();

    final path = _cachedSoundPaths['win'];
    if (path != null) {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(DeviceFileSource(path));
    }
  }

  // --- Copyright-Free Procedural Audio Generators ---

  Uint8List _createWav(int sampleRate, List<double> samples) {
    final numSamples = samples.length;
    final byteLength = 44 + numSamples * 2;
    final buffer = ByteData(byteLength);

    // RIFF chunk descriptor
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, byteLength - 8, Endian.little);
    buffer.setUint8(8, 0x57);  // W
    buffer.setUint8(9, 0x41);  // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt subchunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    buffer.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    buffer.setUint32(24, sampleRate, Endian.little); // SampleRate
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    buffer.setUint16(32, 2, Endian.little);  // BlockAlign (NumChannels * BitsPerSample/8)
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample (16 bits)

    // data subchunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, numSamples * 2, Endian.little);

    // Samples
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
      // Exponential decay envelope
      final env = exp(-t * 14.0);
      // Sine wave with overtone
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
      // Pitch slides rapidly down from 140Hz to 55Hz
      final curFreq = 140.0 - (t / duration) * 85.0;
      final env = exp(-t * 18.0);
      // Triangle wave with slight punch
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
      // Sci-fi pitch sweep upwards 320 -> 840Hz
      final curFreq = 320.0 + (t / duration) * 520.0;
      final env = sin(pi * (t / duration)); // parabolic swell
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
