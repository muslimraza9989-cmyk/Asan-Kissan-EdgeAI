import 'package:flutter/foundation.dart';

/// Severity status for the identified corn leaf disease.
enum DiseaseSeverity {
  high,
  moderate,
  none,
  uncertain,
}

extension DiseaseSeverityExtension on DiseaseSeverity {
  String get displayName {
    switch (this) {
      case DiseaseSeverity.high:
        return 'High Severity';
      case DiseaseSeverity.moderate:
        return 'Moderate Risk';
      case DiseaseSeverity.none:
        return 'Healthy / Low Risk';
      case DiseaseSeverity.uncertain:
        return 'Uncertain / Retake';
    }
  }
}

/// Individual disease probability score from multi-label evaluation.
@immutable
class DiseaseScore {
  final String label;
  final double score; // 0.0 to 1.0 (Sigmoid probability)
  final DiseaseDetails details;

  const DiseaseScore({
    required this.label,
    required this.score,
    required this.details,
  });

  String get formattedScore => '${(score * 100).toStringAsFixed(1)}%';
}

/// Agronomic details and recommendations for a disease label.
@immutable
class DiseaseDetails {
  final String name;
  final String scientificName;
  final DiseaseSeverity severity;
  final String description;
  final List<String> symptoms;
  final List<String> recommendations;
  final List<String> preventiveMeasures;
  final bool isCoInfection;

  const DiseaseDetails({
    required this.name,
    required this.scientificName,
    required this.severity,
    required this.description,
    required this.symptoms,
    required this.recommendations,
    required this.preventiveMeasures,
    this.isCoInfection = false,
  });
}

/// Result produced after ONNX model inference.
@immutable
class DiagnosisResult {
  final String label;
  final double confidence; // Primary confidence (0.0 to 1.0)
  final DiseaseDetails details;
  final List<DiseaseScore> detectedDiseases; // All diseases crossing threshold
  final List<DiseaseScore> allScores; // All classes with probabilities
  final bool isCoInfection;
  final bool isUncertain;
  final String? uncertaintyReason;
  final DateTime timestamp;
  final int executionTimeMs;
  final List<double>? heatmapData;
  final int heatmapWidth;
  final int heatmapHeight;
  final List<double> rawLogits;

  const DiagnosisResult({
    required this.label,
    required this.confidence,
    required this.details,
    this.detectedDiseases = const [],
    this.allScores = const [],
    this.isCoInfection = false,
    this.isUncertain = false,
    this.uncertaintyReason,
    required this.timestamp,
    this.executionTimeMs = 0,
    this.heatmapData,
    this.heatmapWidth = 0,
    this.heatmapHeight = 0,
    this.rawLogits = const [],
  });

  /// Formatted confidence score string (e.g. 94.2%).
  String get formattedConfidence => '${(confidence * 100).toStringAsFixed(1)}%';
  
  bool get hasHeatmap =>
      heatmapData != null &&
      heatmapData!.isNotEmpty &&
      heatmapWidth > 0 &&
      heatmapHeight > 0;
}

/// Static repository mapping labels to domain knowledge.
class DiseaseInfoRepository {
  static final Map<String, DiseaseDetails> _database = {
    'Common Rust': const DiseaseDetails(
      name: 'Common Rust',
      scientificName: 'Puccinia sorghi',
      severity: DiseaseSeverity.moderate,
      description:
          'Common Rust is a fungal infection characterized by small, powdery cinnamon-brown pustules on both upper and lower leaf surfaces.',
      symptoms: [
        'Oval to elongate cinnamon-brown pustules',
        'Pustules turn dark brown to black as the plant matures',
        'Chlorotic yellowing around leaf lesions',
      ],
      recommendations: [
        'Apply foliar fungicides (e.g., Strobilurins or Triazoles like Azoxystrobin) at the first sign of infection during early development.',
        'Ensure proper plant spacing to improve air circulation across canopy.',
        'Monitor field weekly, especially when temperatures are 60°F–75°F (16°C–24°C) with high humidity.',
      ],
      preventiveMeasures: [
        'Plant resistant or tolerant corn hybrids.',
        'Practice early planting to avoid peak fungal spore production.',
        'Rotate crops with non-host plants (e.g., soybeans or legumes).',
      ],
    ),
    'Gray Leaf Spot': const DiseaseDetails(
      name: 'Gray Leaf Spot',
      scientificName: 'Cercospora zeae-maydis',
      severity: DiseaseSeverity.high,
      description:
          'Gray Leaf Spot is one of the most destructive yield-limiting fungal leaf diseases in corn, producing distinct rectangular lesions bounded by leaf veins.',
      symptoms: [
        'Small tan spots surrounded by yellow halos in early stages',
        'Rectangular gray-to-brown lesions strictly bounded by leaf veins',
        'Blighted leaves dry out completely when severe',
      ],
      recommendations: [
        'Apply targeted fungicide (such as Pyraclostrobin or Propiconazole) at tasseling (VT) to silking (R1) stages.',
        'Incorporate crop residues into soil post-harvest to accelerate fungal decay.',
        'Avoid overhead irrigation late in the evening to reduce leaf wetness duration.',
      ],
      preventiveMeasures: [
        'Use high-yield hybrids with genetic resistance to Gray Leaf Spot.',
        'Implement 2-year minimum crop rotation away from corn.',
        'Manage residue through conservation tillage practices.',
      ],
    ),
    'Northern Leaf Blight': const DiseaseDetails(
      name: 'Northern Leaf Blight',
      scientificName: 'Exserohilum turcicum',
      severity: DiseaseSeverity.high,
      description:
          'Northern Corn Leaf Blight produces large, cigar-shaped grayish-green lesions that can coalesce and cause significant premature leaf death.',
      symptoms: [
        'Long, elliptical cigar-shaped lesions (1 to 6 inches long)',
        'Lesions transition from grayish-green to tan/pale brown',
        'Dark dusty fungal spores visible inside lesions under humid conditions',
      ],
      recommendations: [
        'Apply registered fungicides if disease affects upper leaves before or during silking.',
        'Promptly destroy infected plant residues after harvest.',
        'Consult local agricultural extension office for region-specific spray thresholds.',
      ],
      preventiveMeasures: [
        'Select resistant corn varieties carrying Ht genes.',
        'Practice field sanitation and crop rotation with non-host crops.',
        'Balance nitrogen fertilization to avoid lush, susceptible foliage.',
      ],
    ),
    'Healthy': const DiseaseDetails(
      name: 'Healthy Corn Leaf',
      scientificName: 'Zea mays (Optimal Health)',
      severity: DiseaseSeverity.none,
      description:
          'The corn leaf shows rich dark green foliage with no detectable symptoms of fungal, bacterial, or environmental leaf blight.',
      symptoms: [
        'Uniform green color across leaf blade',
        'Intact leaf veins without spots, pustules, or chlorotic halos',
        'Vigorous leaf turgor and tissue structure',
      ],
      recommendations: [
        'Maintain balanced N-P-K nutrient application according to soil testing.',
        'Ensure consistent moisture during flowering and grain fill stages.',
        'Continue routine scouting every 7–10 days during peak growing season.',
      ],
      preventiveMeasures: [
        'Keep weed pressure under control around field borders.',
        'Sanitize equipment between field visits to prevent pathogen introduction.',
        'Maintain healthy soil organic matter and beneficial microflora.',
      ],
    ),
  };

  /// Gets details for a single label.
  static DiseaseDetails getDetailsFor(String label) {
    final normalized = label.trim().toLowerCase();
    for (final entry in _database.entries) {
      if (entry.key.toLowerCase() == normalized ||
          normalized.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return DiseaseDetails(
      name: label,
      scientificName: 'Unknown / Non-Corn Pathogen',
      severity: DiseaseSeverity.uncertain,
      description:
          'Detected condition: "$label". Image may be out-of-distribution or ambiguous.',
      symptoms: const ['Atypical or unclear leaf lesion patterning.'],
      recommendations: const [
        'Retake photo with camera focused closely on a single clear corn leaf.',
        'Avoid heavy sunlight glare, blurriness, or non-crop objects in frame.',
      ],
      preventiveMeasures: const [
        'Consult local agronomic extension office with physical plant sample.',
      ],
    );
  }

  /// Generates a combined diagnostic recommendation for co-infections.
  static DiseaseDetails getCoInfectionDetails(List<String> diseaseNames) {
    final nameStr = diseaseNames.join(' & ');
    final List<String> combinedSymptoms = [];
    final List<String> combinedRecs = [];
    final List<String> combinedPrev = [];

    for (final name in diseaseNames) {
      final detail = getDetailsFor(name);
      combinedSymptoms.addAll(detail.symptoms);
      combinedPrev.addAll(detail.preventiveMeasures);
    }

    // Add broad-spectrum combination recommendations
    combinedRecs.add(
      'Apply a broad-spectrum premix fungicide combining a Strobilurin (QoI) and a Triazole (DMI), e.g. Azoxystrobin + Propiconazole, to treat both pathogens simultaneously.',
    );
    combinedRecs.add(
      'Spray during early morning or late afternoon when canopy humidity is low and wind is calm.',
    );
    combinedRecs.add(
      'Re-scout the field 7–10 days after application to verify lesion halt.',
    );

    return DiseaseDetails(
      name: 'Co-Infection: $nameStr',
      scientificName: 'Multiple Pathogens Present',
      severity: DiseaseSeverity.high,
      description:
          'Multiple fungal diseases ($nameStr) have been detected on this corn leaf simultaneously. Co-infections accelerate foliage death and require broad-spectrum intervention.',
      symptoms: combinedSymptoms.toSet().toList(),
      recommendations: combinedRecs,
      preventiveMeasures: combinedPrev.toSet().toList(),
      isCoInfection: true,
    );
  }

  /// Returns diagnostic advice for an uncertain or out-of-distribution scan.
  static DiseaseDetails getUncertainDetails(String reason) {
    return DiseaseDetails(
      name: 'Inconclusive / Low Confidence',
      scientificName: 'Indeterminate Foliage',
      severity: DiseaseSeverity.uncertain,
      description: reason,
      symptoms: const [
        'Insufficient lesion clarity or uncharacteristic color spectrum.',
        'Image may contain non-corn background, heavy shadows, or motion blur.',
      ],
      recommendations: const [
        'Hold camera steady, approximately 15–20 cm from the affected leaf.',
        'Ensure the leaf fills at least 70% of the camera viewfinder.',
        'Wipe camera lens and avoid direct sun glare or deep shadows.',
      ],
      preventiveMeasures: const [
        'Ensure good natural lighting when photographing crops in the field.',
      ],
    );
  }
}

