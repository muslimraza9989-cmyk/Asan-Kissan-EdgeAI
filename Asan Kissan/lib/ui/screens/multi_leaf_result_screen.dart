import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/disease_info.dart';
import '../../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_indicator.dart';
import '../widgets/disease_recommendation_card.dart';
import '../widgets/grad_cam_painter.dart';

/// Screen displaying a multi-leaf diagnostic breakdown for canopy scans.
class MultiLeafResultScreen extends StatefulWidget {
  final List<Uint8List> leafImages;
  final List<DiagnosisResult> diagnoses;

  const MultiLeafResultScreen({
    super.key,
    required this.leafImages,
    required this.diagnoses,
  });

  @override
  State<MultiLeafResultScreen> createState() => _MultiLeafResultScreenState();
}

class _MultiLeafResultScreenState extends State<MultiLeafResultScreen> {
  final TtsService _tts = TtsService();
  int? _expandedIndex = 0;
  final Map<int, bool> _heatmapToggles = {};

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

  void _speakCanopySummary() {
    if (_tts.isPlaying) {
      _tts.stop();
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Canopy scan report. ${widget.diagnoses.length} leaves analyzed.');
    for (int i = 0; i < widget.diagnoses.length; i++) {
      final d = widget.diagnoses[i];
      buffer.writeln('Leaf number ${i + 1}: ${d.label}, confidence ${d.formattedConfidence}.');
    }

    final activeIndex = _expandedIndex ?? 0;
    if (activeIndex < widget.diagnoses.length) {
      final active = widget.diagnoses[activeIndex];
      buffer.writeln('Details for Leaf ${activeIndex + 1}:');
      buffer.writeln(active.details.description);
      for (final r in active.details.recommendations) {
        buffer.writeln(r);
      }
    }

    _tts.speakDiagnosis(widget.diagnoses[activeIndex]);
  }

  @override
  Widget build(BuildContext context) {
    int infectedCount = 0;
    int healthyCount = 0;
    int uncertainCount = 0;

    for (final d in widget.diagnoses) {
      if (d.isUncertain) {
        uncertainCount++;
      } else if (d.label.toLowerCase().contains('healthy')) {
        healthyCount++;
      } else {
        infectedCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Canopy Disease Report',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _tts.isPlaying ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
              color: _tts.isPlaying ? Colors.lightGreenAccent : Colors.white,
            ),
            tooltip: _tts.isPlaying ? 'Stop Voice' : 'Listen Report',
            onPressed: _speakCanopySummary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Canopy Summary Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.accentEmerald],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Canopy Overview',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.diagnoses.length} Leaves Checked',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildSummaryStat(
                        'Infected',
                        infectedCount.toString(),
                        infectedCount > 0 ? Colors.orangeAccent : Colors.white,
                      ),
                      _buildSummaryStat(
                        'Healthy',
                        healthyCount.toString(),
                        Colors.lightGreenAccent,
                      ),
                      if (uncertainCount > 0)
                        _buildSummaryStat(
                          'Uncertain',
                          uncertainCount.toString(),
                          Colors.amberAccent,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Individual Leaf Diagnoses',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap any leaf to view Grad-CAM activation and specific field remedies.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),

            // Per Leaf Accordion Cards
            for (int i = 0; i < widget.diagnoses.length; i++)
              _buildLeafCard(i, widget.leafImages[i], widget.diagnoses[i]),

            const SizedBox(height: 24),

            // Return button
            SizedBox(
              width: double.infinity,
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
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: Text(
                  'Finish & Return to Home',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String count, Color countColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: countColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeafCard(int index, Uint8List imageBytes, DiagnosisResult result) {
    final isExpanded = _expandedIndex == index;
    final showHeatmap = _heatmapToggles[index] ?? true;

    Color badgeColor = AppTheme.severityHealthy;
    if (result.isUncertain) {
      badgeColor = Colors.amber.shade800;
    } else if (result.details.severity == DiseaseSeverity.high) {
      badgeColor = AppTheme.severityHigh;
    } else if (result.details.severity == DiseaseSeverity.moderate) {
      badgeColor = AppTheme.severityModerate;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isExpanded
            ? const BorderSide(color: AppTheme.primaryGreen, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      imageBytes,
                      width: 54,
                      height: 54,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaf #${index + 1}: ${result.label}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                result.details.severity.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              result.formattedConfidence,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentEmerald,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),

              // Expanded Details
              if (isExpanded) ...[
                const Divider(height: 24),

                // Grad-CAM preview container with square aspect ratio
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(imageBytes, fit: BoxFit.cover),
                        if (showHeatmap && result.hasHeatmap)
                          CustomPaint(
                            painter: GradCamPainter(
                              heatmapData: result.heatmapData!,
                              gridWidth: result.heatmapWidth,
                              gridHeight: result.heatmapHeight,
                              opacity: 0.55,
                            ),
                          ),
                        if (result.hasHeatmap)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _heatmapToggles[index] = !showHeatmap;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: showHeatmap
                                      ? Colors.deepOrange.withValues(alpha: 0.9)
                                      : Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  showHeatmap ? 'Grad-CAM ON' : 'Grad-CAM OFF',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confidence Indicator
                ConfidenceIndicator(confidence: result.confidence),
                const SizedBox(height: 16),

                // Recommendations Card
                DiseaseRecommendationCard(details: result.details),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
