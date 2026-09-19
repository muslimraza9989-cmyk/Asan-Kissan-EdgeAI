import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/disease_info.dart';
import '../services/classifier_service.dart';

/// Provider managing state for ONNX Runtime inference, image selection, multi-leaf analysis, and UI feedback.
class ClassifierProvider extends ChangeNotifier {
  final ClassifierService _classifierService = ClassifierService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _selectedImageBytes;
  DiagnosisResult? _diagnosis;
  List<DiagnosisResult> _multiLeafResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  final List<DiagnosisResult> _history = [];

  // Getters
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  DiagnosisResult? get diagnosis => _diagnosis;
  List<DiagnosisResult> get multiLeafResults => List.unmodifiable(_multiLeafResults);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  List<DiagnosisResult> get history => List.unmodifiable(_history);

  ClassifierProvider() {
    init();
  }

  /// Initializes the underlying ONNX classifier service.
  Future<void> init() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _classifierService.initialize();
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Failed to load ONNX model: ${e.toString()}';
      debugPrint('ClassifierProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Picks raw image bytes from camera or gallery.
  Future<Uint8List?> pickRawImage(ImageSource source) async {
    try {
      _errorMessage = null;
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 92,
      );

      if (pickedFile == null) return null;
      return await pickedFile.readAsBytes();
    } catch (e) {
      _errorMessage = 'Error picking image: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  /// Captures an image and runs single-leaf diagnosis.
  Future<bool> pickAndAnalyzeSingle(ImageSource source) async {
    final bytes = await pickRawImage(source);
    if (bytes == null) return false;
    await analyzeImageBytes(bytes);
    return true;
  }

  /// Analyzes raw image bytes using the ONNX classifier service.
  Future<void> analyzeImageBytes(Uint8List imageBytes) async {
    _selectedImageBytes = imageBytes;
    _isLoading = true;
    _errorMessage = null;
    _diagnosis = null;
    notifyListeners();

    try {
      final result = await _classifierService.classifyImage(imageBytes);
      _diagnosis = result;
      _history.insert(0, result);
    } catch (e) {
      _errorMessage = 'ONNX Inference failed: ${e.toString()}';
      debugPrint('Error analyzing image with ONNX: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Analyzes multiple cropped leaf regions in batch.
  Future<List<DiagnosisResult>> analyzeMultipleRegions(List<Uint8List> regions) async {
    _isLoading = true;
    _errorMessage = null;
    _multiLeafResults = [];
    notifyListeners();

    final List<DiagnosisResult> results = [];
    try {
      for (final regionBytes in regions) {
        final res = await _classifierService.classifyImage(regionBytes);
        results.add(res);
        _history.insert(0, res);
      }
      _multiLeafResults = results;
    } catch (e) {
      _errorMessage = 'Canopy analysis error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return results;
  }

  /// Resets selected image and diagnosis result state.
  void clearSelection() {
    _selectedImageBytes = null;
    _diagnosis = null;
    _multiLeafResults = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _classifierService.dispose();
    super.dispose();
  }
}

