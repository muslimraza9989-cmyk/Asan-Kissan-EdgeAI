import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Animated radial confidence gauge component.
class ConfidenceIndicator extends StatelessWidget {
  final double confidence; // Range 0.0 to 1.0

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
  });

  Color get _scoreColor {
    if (confidence >= 0.70) return AppTheme.accentEmerald;
    if (confidence >= 0.50) return AppTheme.severityModerate;
    return AppTheme.severityHigh;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (confidence * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _scoreColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _scoreColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: confidence,
                  strokeWidth: 6,
                  backgroundColor: _scoreColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Icon(
                    confidence >= 0.70
                        ? Icons.verified
                        : confidence >= 0.50
                            ? Icons.info_outline
                            : Icons.warning_amber_rounded,
                    color: _scoreColor,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Model Confidence',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    percentage,
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                  Text(
                    '%',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
