import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Joyful sound effects and cozy background audio service for Mossy.
/// Uses bundled WAV audio assets with instant fallback to synthesized
/// in-memory WAV PCM bytes and native [SystemSound] clicks.
class SoundService {
  static final SoundService instance = SoundService._internal();

  SoundService._internal();

  factory SoundService() => instance;

  bool isMuted = false;
  bool isMusicMuted = false;
  double musicVolume = 0.22;

  AudioPlayer? _bgmPlayer;
  bool _isMusicPlaying = false;
  bool _prefsLoaded = false;

  bool get isMusicPlaying => _isMusicPlaying;

  // Cached in-memory WAV byte buffers for instant offline fallback
  static Uint8List? _unlockChimeBytes;
  static Uint8List? _badgeFanfareBytes;
  static Uint8List? _gardenTapBytes;
  static Uint8List? _celebrationBytes;
  static Uint8List? _cozyLoopBytes;

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

  static Uint8List getCozyBackgroundBytes() {
    return _cozyLoopBytes ??= _synthesizeCozyLoopWav();
  }

  /// Loads persisted sound and music mute preferences from SharedPreferences.
  Future<void> initPreferences() async {
    if (_prefsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      isMusicMuted = prefs.getBool('mossy_music_muted') ?? false;
      isMuted = prefs.getBool('mossy_sound_muted') ?? false;
      _prefsLoaded = true;
    } catch (_) {}
  }

  /// Starts the soft, cozy background music loop.
  Future<void> startBackgroundMusic({double? volume}) async {
    await initPreferences();
    if (isMusicMuted) return;

    try {
      final vol = volume ?? musicVolume;
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop).catchError((_) {});
      await _bgmPlayer!.setVolume(vol).catchError((_) {});

      bool played = false;
      try {
        await _bgmPlayer!.play(AssetSource('sounds/cozy_background.wav'), volume: vol);
        played = true;
      } catch (_) {
        played = false;
      }

      if (!played) {
        final bytes = getCozyBackgroundBytes();
        await _bgmPlayer!.play(BytesSource(bytes, mimeType: 'audio/wav'), volume: vol);
      }
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint('[Mossy SoundService] background music error: $e');
    }
  }

  /// Pauses the background music loop.
  Future<void> pauseBackgroundMusic() async {
    _isMusicPlaying = false;
    try {
      await _bgmPlayer?.pause().catchError((_) {});
    } catch (_) {}
  }

  /// Resumes the background music loop if not muted.
  Future<void> resumeBackgroundMusic() async {
    await initPreferences();
    if (isMusicMuted) return;

    if (_bgmPlayer != null) {
      try {
        await _bgmPlayer!.resume().catchError((_) {});
        _isMusicPlaying = true;
      } catch (_) {
        await startBackgroundMusic();
      }
    } else {
      await startBackgroundMusic();
    }
  }

  /// Stops the background music loop.
  Future<void> stopBackgroundMusic() async {
    _isMusicPlaying = false;
    try {
      await _bgmPlayer?.stop().catchError((_) {});
    } catch (_) {}
  }

  /// Sets whether the background music loop is muted and persists the choice.
  Future<void> setMusicMuted(bool muted) async {
    isMusicMuted = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mossy_music_muted', muted);
    } catch (_) {}

    if (muted) {
      await pauseBackgroundMusic();
    } else {
      await startBackgroundMusic();
    }
  }

  /// Toggles the background music loop mute state.
  Future<void> toggleMusic() async {
    await setMusicMuted(!isMusicMuted);
  }

  /// Sets whether sound effects are muted and persists the choice.
  Future<void> setSoundMuted(bool muted) async {
    isMuted = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mossy_sound_muted', muted);
    } catch (_) {}
  }

  /// Toggles the sound effects mute state.
  Future<void> toggleSound() async {
    await setSoundMuted(!isMuted);
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

  /// Plays a joyful chime and triggers haptic vibration when a plant is recognized.
  Future<void> playRecognitionSound() async {
    await _play(
      assetPath: 'sounds/unlock_chime.wav',
      byteGetter: getUnlockChimeBytes,
      haptic: HapticFeedback.mediumImpact,
      volume: 0.95,
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

  /// Synthesizes a warm, kid-friendly cozy nature melody loop (~9.6s) in 16-bit mono WAV format.
  static Uint8List _synthesizeCozyLoopWav({int sampleRate = 22050}) {
    const duration = 9.6;
    final totalSamples = (duration * sampleRate).toInt();
    final pcmSamples = List<int>.filled(totalSamples, 0);

    // Notes: [startTimeInSec, frequencyInHz, velocity]
    final notes = [
      // Bar 1 - Cmaj7 (dew on leaves)
      [0.0, 523.25, 0.9],
      [0.6, 659.25, 0.85],
      [1.2, 783.99, 0.8],
      [1.8, 987.77, 0.75],
      // Bar 2 - Am7 (floating leaf)
      [2.4, 880.00, 0.85],
      [3.0, 783.99, 0.8],
      [3.6, 659.25, 0.8],
      [4.2, 587.33, 0.75],
      // Bar 3 - Fmaj7 (blooming flower)
      [4.8, 698.46, 0.85],
      [5.4, 880.00, 0.85],
      [6.0, 1046.50, 0.8],
      [6.6, 783.99, 0.75],
      // Bar 4 - G -> resolve back to C
      [7.2, 659.25, 0.8],
      [7.8, 587.33, 0.8],
      [8.4, 392.00, 0.75],
      [9.0, 587.33, 0.7],
    ];

    // Synthesize melody notes (music box / kalimba timbre with soft attack and warm decay)
    for (final note in notes) {
      final startTime = note[0];
      final freq = note[1];
      final vel = note[2];
      final startIdx = (startTime * sampleRate).toInt();
      const noteDur = 1.4;
      final noteSamples = (noteDur * sampleRate).toInt();

      for (int s = 0; s < noteSamples; s++) {
        final targetIdx = startIdx + s;
        if (targetIdx >= totalSamples) break;

        final t = s / sampleRate;
        final attack = (t < 0.015) ? (t / 0.015) : 1.0;
        final decay = math.exp(-t * 2.4);
        final env = attack * decay;

        final wave = math.sin(2 * math.pi * freq * t) +
            0.26 * math.sin(4 * math.pi * freq * t) +
            0.08 * math.sin(6 * math.pi * freq * t);

        final amplitude = 5200.0 * vel * env * wave;
        pcmSamples[targetIdx] += amplitude.toInt();
      }
    }

    // Soft background pad/bass drone chords for each bar
    final barRoots = [
      [0.0, 2.4, 130.81, 196.00], // C3, G3
      [2.4, 4.8, 110.00, 164.81], // A2, E3
      [4.8, 7.2, 87.31, 130.81],  // F2, C3
      [7.2, 9.6, 98.00, 146.83],  // G2, D3
    ];

    for (final bar in barRoots) {
      final start = bar[0];
      final end = bar[1];
      final f1 = bar[2];
      final f2 = bar[3];
      final startIdx = (start * sampleRate).toInt();
      final endIdx = (end * sampleRate).toInt();

      for (int i = startIdx; i < endIdx && i < totalSamples; i++) {
        final t = i / sampleRate;
        final barT = t - start;
        const barLen = 2.4;
        double padEnv = 1.0;
        if (barT < 0.25) {
          padEnv = barT / 0.25;
        } else if (barT > barLen - 0.25) {
          padEnv = (barLen - barT) / 0.25;
        }

        final padWave = 0.6 * math.sin(2 * math.pi * f1 * t) +
            0.4 * math.sin(2 * math.pi * f2 * t);
        pcmSamples[i] += (900.0 * padEnv * padWave).toInt();
      }
    }

    // Smooth edge crossfade on the first and last 200 samples to ensure seamless loop
    const edgeSamples = 200;
    for (int i = 0; i < edgeSamples; i++) {
      final fade = i / edgeSamples;
      pcmSamples[i] = (pcmSamples[i] * fade).toInt();
      final endI = totalSamples - 1 - i;
      pcmSamples[endI] = (pcmSamples[endI] * fade).toInt();
    }

    // Clamp samples
    for (int i = 0; i < totalSamples; i++) {
      pcmSamples[i] = pcmSamples[i].clamp(-32000, 32000);
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

  void dispose() {
    _bgmPlayer?.dispose().catchError((_) {});
    _bgmPlayer = null;
    _isMusicPlaying = false;
  }
}
