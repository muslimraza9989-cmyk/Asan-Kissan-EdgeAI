import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/disease_info.dart';
import '../theme/app_theme.dart';

/// Card widget displaying severity badge, description, symptoms, and agronomic remedies.
class DiseaseRecommendationCard extends StatelessWidget {
  final DiseaseDetails details;

  const DiseaseRecommendationCard({
    super.key,
    required this.details,
  });

  Color get _severityColor {
    switch (details.severity) {
      case DiseaseSeverity.high:
        return AppTheme.severityHigh;
      case DiseaseSeverity.moderate:
        return AppTheme.severityModerate;
      case DiseaseSeverity.none:
        return AppTheme.severityHealthy;
      case DiseaseSeverity.uncertain:
        return Colors.grey.shade600;
    }
  }

  IconData get _severityIcon {
    switch (details.severity) {
      case DiseaseSeverity.high:
        return Icons.error_outline;
      case DiseaseSeverity.moderate:
        return Icons.warning_amber_rounded;
      case DiseaseSeverity.none:
        return Icons.check_circle_outline;
      case DiseaseSeverity.uncertain:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Severity Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.name,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        details.scientificName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _severityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _severityIcon,
                        size: 16,
                        color: _severityColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        details.severity.displayName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _severityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // Description
            Text(
              'Overview',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              details.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Symptoms
            _buildSection(
              context: context,
              title: 'Key Field Symptoms',
              icon: Icons.search_outlined,
              iconColor: Colors.amber.shade800,
              items: details.symptoms,
            ),
            const SizedBox(height: 20),

            // Recommended Actionable Remedies
            _buildSection(
              context: context,
              title: 'Recommended Actionable Remedies',
              icon: Icons.healing_outlined,
              iconColor: AppTheme.primaryGreen,
              items: details.recommendations,
            ),
            const SizedBox(height: 20),

            // Preventive Measures
            _buildSection(
              context: context,
              title: 'Long-term Preventive Measures',
              icon: Icons.shield_outlined,
              iconColor: Colors.blue.shade700,
              items: details.preventiveMeasures,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: iconColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textDark,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
