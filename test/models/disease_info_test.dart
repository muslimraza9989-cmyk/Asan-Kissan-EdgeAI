import 'package:flutter_test/flutter_test.dart';
import 'package:asan_kissan/models/disease_info.dart';

void main() {
  group('DiseaseInfoRepository Tests', () {
    test('Returns exact details for known diseases', () {
      final rust = DiseaseInfoRepository.getDetailsFor('Common Rust');
      expect(rust.name, 'Common Rust');
      expect(rust.scientificName, 'Puccinia sorghi');
      expect(rust.severity, DiseaseSeverity.moderate);
      expect(rust.recommendations, isNotEmpty);

      final blight = DiseaseInfoRepository.getDetailsFor('Northern Leaf Blight');
      expect(blight.name, 'Northern Leaf Blight');
      expect(blight.severity, DiseaseSeverity.high);

      final healthy = DiseaseInfoRepository.getDetailsFor('Healthy');
      expect(healthy.name, 'Healthy Corn Leaf');
      expect(healthy.severity, DiseaseSeverity.none);
    });

    test('Case-insensitive matching works correctly', () {
      final spot = DiseaseInfoRepository.getDetailsFor('gray leaf spot');
      expect(spot.name, 'Gray Leaf Spot');
      expect(spot.severity, DiseaseSeverity.high);
    });

    test('Generates combined Co-Infection recommendations', () {
      final coInfection = DiseaseInfoRepository.getCoInfectionDetails([
        'Common Rust',
        'Northern Leaf Blight',
      ]);

      expect(coInfection.isCoInfection, isTrue);
      expect(coInfection.name, contains('Common Rust'));
      expect(coInfection.name, contains('Northern Leaf Blight'));
      expect(coInfection.severity, DiseaseSeverity.high);
      expect(coInfection.recommendations.any((r) => r.contains('broad-spectrum')), isTrue);
    });

    test('Returns appropriate advice for uncertain/OOD scans', () {
      final uncertain = DiseaseInfoRepository.getUncertainDetails(
        'Low confidence scan',
      );

      expect(uncertain.severity, DiseaseSeverity.uncertain);
      expect(uncertain.name, contains('Inconclusive'));
      expect(uncertain.recommendations, isNotEmpty);
    });
  });

  group('DiseaseScore & DiagnosisResult Tests', () {
    test('Formats score percentages correctly', () {
      const details = DiseaseDetails(
        name: 'Common Rust',
        scientificName: 'Puccinia sorghi',
        severity: DiseaseSeverity.moderate,
        description: 'Test',
        symptoms: [],
        recommendations: [],
        preventiveMeasures: [],
      );

      const score = DiseaseScore(
        label: 'Common Rust',
        score: 0.942,
        details: details,
      );

      expect(score.formattedScore, '94.2%');
    });
  });
}
