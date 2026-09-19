import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/disease_info.dart';
import '../../providers/classifier_provider.dart';
import '../../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_indicator.dart';
import '../widgets/disease_recommendation_card.dart';
import '../widgets/grad_cam_painter.dart';
import '../widgets/image_source_modal.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showHeatmap = true;
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _tts.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClassifierProvider>(
      builder: (context, provider, child) {
        final imageBytes = provider.selectedImageBytes;
        final result = provider.diagnosis;
        final error = provider.errorMessage;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Diagnosis Results',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (result != null)
                IconButton(
                  icon: Icon(
                    _tts.isPlaying
                        ? Icons.volume_up_rounded
                        : Icons.volume_mute_rounded,
                    color: _tts.isPlaying
                        ? Colors.lightGreenAccent
                        : Colors.white,
                  ),
                  tooltip: _tts.isPlaying ? 'Stop Voice' : 'Listen Diagnosis',
                  onPressed: () {
                    _tts.speakDiagnosis(result);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Clear & Retake',
                onPressed: () {
                  _tts.stop();
                  provider.clearSelection();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          body: _buildBody(context, provider, imageBytes, result, error),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ClassifierProvider provider,
    dynamic imageBytes,
    DiagnosisResult? result,
    String? error,
  ) {
    if (error != null) {
      return _buildErrorView(context, error);
    }

    if (imageBytes == null || result == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              size: 64,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No image selected for analysis.',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Return to Home'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. OOD / Uncertainty Alert Banner
          if (result.isUncertain) _buildUncertaintyBanner(context, result),

          // 2. Co-Infection Multi-Label Banner
          if (result.isCoInfection) _buildCoInfectionBanner(context, result),

          // 3. Leaf Image Preview Card with Grad-CAM Heatmap Overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1.0, // 1:1 Aspect ratio strictly matches 224x224 crop & heatmap
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                    ),

                    // Grad-CAM Jet Colormap Heatmap Overlay
                    if (_showHeatmap && result.hasHeatmap)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GradCamPainter(
                            heatmapData: result.heatmapData!,
                            gridWidth: result.heatmapWidth,
                            gridHeight: result.heatmapHeight,
                            opacity: 0.55,
                          ),
                        ),
                      ),

                    // Grad-CAM Toggle Button Badge
                    if (result.hasHeatmap)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _showHeatmap = !_showHeatmap;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _showHeatmap
                                  ? Colors.deepOrange.withValues(alpha: 0.9)
                                  : Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _showHeatmap
                                      ? Icons.local_fire_department_rounded
                                      : Icons.local_fire_department_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _showHeatmap
                                      ? 'Grad-CAM ON'
                                      : 'Grad-CAM OFF',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Analyzed Status Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.center_focus_strong,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Preserved Aspect Ratio',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Voice Readout CTA Pill
          Center(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: _tts.isPlaying
                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                    : Colors.white,
                side: BorderSide(
                  color: _tts.isPlaying
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => _tts.speakDiagnosis(result),
              icon: Icon(
                _tts.isPlaying ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                color: AppTheme.primaryGreen,
                size: 22,
              ),
              label: Text(
                _tts.isPlaying ? 'Stop Voice Readout' : 'Listen Voice Diagnosis',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 5. Confidence Gauge Meter
          ConfidenceIndicator(confidence: result.confidence),
          const SizedBox(height: 14),

          // 6. Multi-Label Class Probability Breakdown
          if (result.allScores.isNotEmpty) _buildMultiLabelScores(result),
          const SizedBox(height: 16),

          // Latency
          Center(
            child: Text(
              'Inference Latency: ${result.executionTimeMs} ms',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 7. Agronomic Disease Details & Recommendation Card
          DiseaseRecommendationCard(details: result.details),
          const SizedBox(height: 24),

          // 8. Bottom Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 1.8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    _tts.stop();
                    provider.clearSelection();
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  label: Text(
                    'Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    _tts.stop();
                    ImageSourceModal.show(
                      context,
                      onSourceSelected: (source) async {
                        await provider.pickAndAnalyzeSingle(source);
                      },
                    );
                  },
                  icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                  label: Text(
                    'Scan Another',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUncertaintyBanner(BuildContext context, DiagnosisResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade400, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Confidence / Out-of-Distribution',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.uncertaintyReason ??
                      'The model detected an unclear leaf pattern. Please retake a well-lit, close-up photo.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoInfectionBanner(BuildContext context, DiagnosisResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.coronavirus_rounded, color: AppTheme.severityHigh, size: 24),
              const SizedBox(width: 10),
              Text(
                'Co-Infection Alert!',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.severityHigh,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Multiple diseases detected simultaneously on this foliage:',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.detectedDiseases.map((d) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '${d.label} (${d.formattedScore})',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.severityHigh,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiLabelScores(DiagnosisResult result) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multi-Label Pathogen Probabilities',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            for (final s in result.allScores)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.label,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          s.formattedScore,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: s.score >= 0.50
                                ? AppTheme.primaryGreen
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: s.score.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          s.score >= 0.50
                              ? AppTheme.primaryGreen
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.severityHigh,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Diagnostic Error',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Provider.of<ClassifierProvider>(context, listen: false)
                    .clearSelection();
                Navigator.pop(context);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
