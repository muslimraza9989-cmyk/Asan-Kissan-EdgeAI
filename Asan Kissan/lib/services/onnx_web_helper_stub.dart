import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:onnxruntime/onnxruntime.dart';

class WebInferenceResponse {
  final String label;
  final double confidence;
  final int executionTimeMs;
  final int heatmapWidth;
  final int heatmapHeight;
  final List<double>? heatmapData;
  final List<double> rawLogits;

  WebInferenceResponse({
    required this.label,
    required this.confidence,
    required this.executionTimeMs,
    required this.heatmapWidth,
    required this.heatmapHeight,
    this.heatmapData,
    required this.rawLogits,
  });
}

class OnnxWebHelper {
  OrtSession? _session;
  static bool _ortInitialized = false;

  Future<bool> initSession() async {
    try {
      if (!_ortInitialized) {
        OrtEnv.instance.init();
        _ortInitialized = true;
      }

      if (_session != null) {
        return true;
      }

      final sessionOptions = OrtSessionOptions();
      const assetFileName = 'assets/corn_model_with_cam_int8.onnx';

      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      return true;
    } catch (e) {
      debugPrint('Native ONNX Init Error: $e');
      return false;
    }
  }

  Future<WebInferenceResponse?> runInference(
    Float32List pixels,
    int width,
    int height,
    List<String> labels,
  ) async {
    if (_session == null) {
      await initSession();
      if (_session == null) return null;
    }

    final startTime = DateTime.now();
    try {
      final shape = [1, 3, height, width];
      final inputOrt = OrtValueTensor.createTensorWithDataList(pixels, shape);
      final inputName = _session!.inputNames.isNotEmpty ? _session!.inputNames[0] : 'input';
      final inputs = {inputName: inputOrt};
      
      final runOptions = OrtRunOptions();
      final outputs = _session?.run(runOptions, inputs);
      
      inputOrt.release();
      runOptions.release();

      if (outputs == null || outputs.isEmpty) return null;

      // Extract Logits
      final logitsTensor = outputs[0]?.value as List?;
      List<double> logits = [];
      if (logitsTensor != null && logitsTensor.isNotEmpty) {
        var first = logitsTensor[0];
        if (first is List) {
          logits = first.map((e) => (e as num).toDouble()).toList();
        } else {
          logits = logitsTensor.map((e) => (e as num).toDouble()).toList();
        }
      }

      // Extract Heatmap
      List<double>? heatmap;
      int hWidth = 224;
      int hHeight = 224;
      
      if (outputs.length > 1) {
        final heatmapTensor = outputs[1]?.value as List?;
        if (heatmapTensor != null) {
          heatmap = _flattenNestedList(heatmapTensor);
        }
      }

      for (final element in outputs) {
        element?.release();
      }

      if (logits.isEmpty) return null;
      
      // Compute Softmax for primary confidence
      double maxLogit = logits.reduce(max);
      double sumExp = 0.0;
      List<double> exps = [];
      for (double logit in logits) {
        double e = exp((logit - maxLogit).clamp(-20.0, 20.0));
        exps.add(e);
        sumExp += e;
      }
      
      List<double> softmax = exps.map((e) => e / sumExp).toList();
      double maxProb = -1;
      int maxIdx = -1;
      for (int i = 0; i < softmax.length; i++) {
        if (softmax[i] > maxProb) {
          maxProb = softmax[i];
          maxIdx = i;
        }
      }

      final label = (maxIdx >= 0 && maxIdx < labels.length) ? labels[maxIdx] : 'Unknown';
      final execMs = DateTime.now().difference(startTime).inMilliseconds;

      return WebInferenceResponse(
        label: label,
        confidence: maxProb,
        executionTimeMs: execMs,
        heatmapWidth: hWidth,
        heatmapHeight: hHeight,
        heatmapData: heatmap,
        rawLogits: logits,
      );
    } catch (e) {
      debugPrint('Native ONNX Inference Error: $e');
      return null;
    }
  }

  List<double> _flattenNestedList(List list) {
    List<double> flat = [];
    for (var item in list) {
      if (item is List) {
        flat.addAll(_flattenNestedList(item));
      } else {
        flat.add((item as num).toDouble());
      }
    }
    return flat;
  }

  void dispose() {
    try {
      _session?.release();
      _session = null;
    } catch (e) {
      debugPrint('Error disposing OrtSession: $e');
    }
  }
}

