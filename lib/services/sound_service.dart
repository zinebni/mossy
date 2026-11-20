import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// Joyful sound effects service for Mossy.
/// Uses bundled WAV audio assets with instant fallback to synthesized
/// in-memory WAV PCM bytes and native [SystemSound] clicks.
class SoundService {
  static final SoundService instance = SoundService._internal();

  SoundService._internal();

  factory SoundService() => instance;

  bool isMuted = false;

  // Cached in-memory WAV byte buffers for instant offline fallback
  static Uint8List? _unlockChimeBytes;
  static Uint8List? _badgeFanfareBytes;
  static Uint8List? _gardenTapBytes;
  static Uint8List? _celebrationBytes;

  static Uint8List getUnlockChimeBytes() {
    return _unlockChimeBytes ??= _synthesizeArpeggioWav(
      frequencies: [523.25, 659.25, 783.99, 1046.50], // C5, E5, G5, C6
      durations: [0.15, 0.15, 0.18, 0.55],
      decayRates: [4.0, 4.0, 3.5, 2.5],
    );
  }

  static Uint8List getBadgeFanfareBytes() {
    return _badgeFanfareBytes ??= _synthesizeArpeggioWav(
      frequencies: [392.00, 523.25, 659.25, 783.99, 1046.50, 1318.51], // G4, C5, E5, G5, C6, E6
      durations: [0.14, 0.14, 0.16, 0.18, 0.35, 0.65],
      decayRates: [3.5, 3.5, 3.0, 3.0, 2.2, 1.8],
      bellHarmonics: true,
    );
  }

  static Uint8List getGardenTapBytes() {
    return _gardenTapBytes ??= _synthesizePopWav();
  }

  static Uint8List getCelebrationBytes() {
    return _celebrationBytes ??= _synthesizeArpeggioWav(
      frequencies: [440.0, 554.37, 659.25, 880.0, 1108.73, 1318.51],
      durations: [0.12, 0.12, 0.15, 0.18, 0.3, 0.7],
      decayRates: [3.5, 3.5, 3.0, 2.8, 2.2, 1.8],
      bellHarmonics: true,
    );
  }

  /// Plays a joyful ascending chime when an item or garden level is unlocked.
  Future<void> playUnlockSound() async {
    await _play(
      assetPath: 'sounds/unlock_chime.wav',
      byteGetter: getUnlockChimeBytes,
      haptic: HapticFeedback.mediumImpact,
      volume: 0.9,
    );
  }

  /// Plays a triumphant, magical fanfare when a new badge/achievement is earned.
  Future<void> playBadgeSound() async {
    await _play(
      assetPath: 'sounds/badge_fanfare.wav',
      byteGetter: getBadgeFanfareBytes,
      haptic: HapticFeedback.heavyImpact,
      volume: 0.95,
    );
  }

  /// Plays a gentle, playful flower/water pop sound when tapping the garden sanctuary.
  Future<void> playGardenTapSound() async {
    await _play(
      assetPath: 'sounds/garden_tap.wav',
      byteGetter: getGardenTapBytes,
      haptic: HapticFeedback.lightImpact,
      volume: 0.8,
      lowLatency: true,
    );
  }

  /// Plays an extended celebration burst sound.
  Future<void> playCelebrationSound() async {
    await _play(
      assetPath: 'sounds/celebration.wav',
      byteGetter: getCelebrationBytes,
      haptic: HapticFeedback.heavyImpact,
      volume: 0.9,
    );
  }

  Future<void> _play({
    required String assetPath,
    required Uint8List Function() byteGetter,
    required Future<void> Function() haptic,
    double volume = 0.85,
    bool lowLatency = false,
  }) async {
    // 1. Immediate tactile and system audio response
    try {
      await haptic().catchError((_) {});
      await SystemSound.play(SystemSoundType.click).catchError((_) {});
    } catch (_) {}

    if (isMuted) return;

    // 2. Play via AudioPlayer
    try {
      final player = AudioPlayer();
      if (lowLatency) {
        await player.setPlayerMode(PlayerMode.lowLatency).catchError((_) {});
      }

      bool played = false;
      // Try asset playback first
      try {
        await player.play(AssetSource(assetPath), volume: volume);
        played = true;
      } catch (_) {
        played = false;
      }

      // Fallback to in-memory WAV byte stream with explicit audio/wav MIME type
      if (!played) {
        final bytes = byteGetter();
        await player.play(BytesSource(bytes, mimeType: 'audio/wav'), volume: volume);
      }

      // Dispose player after completion to avoid native channel leaks
      player.onPlayerComplete.listen((_) {
        player.dispose().catchError((_) {});
      });
    } catch (e) {
      debugPrint('[Mossy SoundService] audio playback note: $e');
    }
  }

  /// Synthesizes an arpeggio sequence in 16-bit PCM mono WAV format.
  static Uint8List _synthesizeArpeggioWav({
    required List<double> frequencies,
    required List<double> durations,
    required List<double> decayRates,
    bool bellHarmonics = false,
    int sampleRate = 22050,
  }) {
    final totalDuration = durations.fold<double>(0.0, (acc, d) => acc + d) + 0.3;
    final totalSamples = (totalDuration * sampleRate).toInt();
    final pcmSamples = List<int>.filled(totalSamples, 0);

    double noteStartTime = 0.0;
    for (int i = 0; i < frequencies.length; i++) {
      final freq = frequencies[i];
      final dur = durations[i];
      final decay = decayRates[i];
      final startIdx = (noteStartTime * sampleRate).toInt();
      final noteSampleCount = ((dur + 0.5) * sampleRate).toInt();

      for (int s = 0; s < noteSampleCount; s++) {
        final targetIdx = startIdx + s;
        if (targetIdx >= totalSamples) break;

        final t = s / sampleRate;
        final env = math.exp(-t * decay);
        // Fundamental
        double wave = math.sin(2 * math.pi * freq * t);
        // Overtones
        if (bellHarmonics) {
          wave += 0.40 * math.sin(2 * math.pi * (freq * 2) * t) * math.exp(-t * (decay * 1.3));
          wave += 0.20 * math.sin(2 * math.pi * (freq * 3) * t) * math.exp(-t * (decay * 1.8));
          wave += 0.10 * math.sin(2 * math.pi * (freq * 4.2) * t) * math.exp(-t * (decay * 2.2));
        } else {
          wave += 0.25 * math.sin(2 * math.pi * (freq * 2) * t) * math.exp(-t * (decay * 1.2));
        }

        final amplitude = 14000.0 * env * wave;
        final current = pcmSamples[targetIdx];
        pcmSamples[targetIdx] = (current + amplitude.toInt()).clamp(-32000, 32000);
      }

      noteStartTime += dur;
    }

    return _buildWavHeaderAndData(pcmSamples, sampleRate);
  }

  /// Synthesizes a soft, cheerful pop/bubble chime in 16-bit PCM mono WAV format.
  static Uint8List _synthesizePopWav({int sampleRate = 22050}) {
    const duration = 0.22;
    final totalSamples = (duration * sampleRate).toInt();
    final pcmSamples = List<int>.filled(totalSamples, 0);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final f = 520.0 + 320.0 * math.sin(t * math.pi / duration);
      final env = math.sin(t * math.pi / duration) * math.exp(-t * 12.0);
      final wave = math.sin(2 * math.pi * f * t) + 0.3 * math.sin(4 * math.pi * f * t);
      final sample = (16000.0 * env * wave).toInt();
      pcmSamples[i] = sample.clamp(-32000, 32000);
    }

    return _buildWavHeaderAndData(pcmSamples, sampleRate);
  }

  /// Encapsulates raw PCM 16-bit mono samples with standard 44-byte RIFF/WAVE header.
  static Uint8List _buildWavHeaderAndData(List<int> samples, int sampleRate) {
    final dataSize = samples.length * 2;
    final buffer = ByteData(44 + dataSize);

    // RIFF chunk descriptor
    buffer.setUint8(0, 0x52); // 'R'
    buffer.setUint8(1, 0x49); // 'I'
    buffer.setUint8(2, 0x46); // 'F'
    buffer.setUint8(3, 0x46); // 'F'
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57);  // 'W'
    buffer.setUint8(9, 0x41);  // 'A'
    buffer.setUint8(10, 0x56); // 'V'
    buffer.setUint8(11, 0x45); // 'E'

    // "fmt " sub-chunk
    buffer.setUint8(12, 0x66); // 'f'
    buffer.setUint8(13, 0x6D); // 'm'
    buffer.setUint8(14, 0x74); // 't'
    buffer.setUint8(15, 0x20); // ' '
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    buffer.setUint16(22, 1, Endian.little);  // NumChannels (1 = mono)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate (SampleRate * 1 channel * 2 bytes)
    buffer.setUint16(32, 2, Endian.little);  // BlockAlign (channels * 2 bytes)
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample (16)

    // "data" sub-chunk
    buffer.setUint8(36, 0x64); // 'd'
    buffer.setUint8(37, 0x61); // 'a'
    buffer.setUint8(38, 0x74); // 't'
    buffer.setUint8(39, 0x61); // 'a'
    buffer.setUint32(40, dataSize, Endian.little);

    var offset = 44;
    for (final s in samples) {
      buffer.setInt16(offset, s, Endian.little);
      offset += 2;
    }

    return buffer.buffer.asUint8List();
  }

  void dispose() {}
}
