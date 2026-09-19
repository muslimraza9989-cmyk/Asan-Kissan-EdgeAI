import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/disease_info.dart';

enum TtsState { playing, stopped, paused }

/// Service handling Text-to-Speech voice readouts for agricultural field diagnosis.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _flutterTts = FlutterTts();
  TtsState _state = TtsState.stopped;
  bool _isInitialized = false;

  TtsState get state => _state;
  bool get isPlaying => _state == TtsState.playing;

  VoidCallback? onStateChanged;

  TtsService._internal();

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setSpeechRate(0.48); // Slightly slower for clarity in field
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setStartHandler(() {
        _state = TtsState.playing;
        onStateChanged?.call();
      });

      _flutterTts.setCompletionHandler(() {
        _state = TtsState.stopped;
        onStateChanged?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _state = TtsState.stopped;
        onStateChanged?.call();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS Initialization warning: $e');
    }
  }

  /// Speaks the complete diagnosis result (Diagnosis + Symptoms + Remedies).
  Future<void> speakDiagnosis(DiagnosisResult result) async {
    await init();
    if (_state == TtsState.playing) {
      await stop();
      return;
    }

    final buffer = StringBuffer();

    if (result.isUncertain) {
      buffer.writeln('Diagnostic alert. The photo scan was inconclusive.');
      buffer.writeln(result.details.description);
      buffer.writeln('Recommended actions:');
      for (final rec in result.details.recommendations) {
        buffer.writeln(rec);
      }
    } else if (result.isCoInfection) {
      buffer.writeln('Diagnosis alert: Multiple fungal diseases detected on this corn leaf.');
      for (final d in result.detectedDiseases) {
        buffer.writeln('${d.label}, confidence ${d.formattedScore}.');
      }
      buffer.writeln('Severity status: ${result.details.severity.displayName}.');
      buffer.writeln('Overview: ${result.details.description}.');
      buffer.writeln('Key recommendations:');
      for (final rec in result.details.recommendations) {
        buffer.writeln(rec);
      }
    } else {
      buffer.writeln('Diagnosis result: ${result.label}.');
      buffer.writeln('Confidence level: ${result.formattedConfidence}.');
      buffer.writeln('Severity: ${result.details.severity.displayName}.');
      buffer.writeln('Overview: ${result.details.description}.');
      
      if (result.details.recommendations.isNotEmpty) {
        buffer.writeln('Recommended action:');
        for (final rec in result.details.recommendations) {
          buffer.writeln(rec);
        }
      }
    }

    final text = buffer.toString();
    try {
      _state = TtsState.playing;
      onStateChanged?.call();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Failed to execute TTS speak: $e');
      _state = TtsState.stopped;
      onStateChanged?.call();
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _state = TtsState.stopped;
      onStateChanged?.call();
    } catch (e) {
      debugPrint('TTS Stop error: $e');
    }
  }

  void dispose() {
    stop();
  }
}
