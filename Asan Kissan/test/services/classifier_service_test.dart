import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sigmoid Multi-Label and OOD Mathematics Tests', () {
    test('Calculates independent sigmoid probabilities correctly', () {
      // Raw Logits for [Northern Blight, Common Rust, Gray Leaf Spot, Healthy]
      final logits = [2.5, 3.2, -1.8, -4.0];

      List<double> sigmoids = [];
      for (final l in logits) {
        final prob = 1.0 / (1.0 + exp(-l));
        sigmoids.add(prob);
      }

      // Sigmoid of 2.5 is ~0.924
      expect(sigmoids[0], closeTo(0.924, 0.01));
      // Sigmoid of 3.2 is ~0.960
      expect(sigmoids[1], closeTo(0.960, 0.01));
      // Sigmoid of -1.8 is ~0.141
      expect(sigmoids[2], closeTo(0.141, 0.01));
      // Sigmoid of -4.0 is ~0.017
      expect(sigmoids[3], closeTo(0.017, 0.01));

      // Both Northern Blight and Common Rust exceed multi-label threshold 0.50
      final detected = <String>[];
      final labels = ['Northern Leaf Blight', 'Common Rust', 'Gray Leaf Spot', 'Healthy'];
      for (int i = 0; i < sigmoids.length; i++) {
        if (labels[i] != 'Healthy' && sigmoids[i] >= 0.50) {
          detected.add(labels[i]);
        }
      }

      expect(detected.length, 2);
      expect(detected, contains('Northern Leaf Blight'));
      expect(detected, contains('Common Rust'));
    });

    test('Identifies Out-of-Distribution (OOD) when all softmax logits are flat/low', () {
      // Low/diffuse logits simulating a photo of a shoe or blurry non-leaf
      final flatLogits = [0.1, 0.2, 0.05, 0.15];

      double maxLogit = flatLogits.reduce(max);
      double sumExp = 0.0;
      List<double> exps = [];
      for (double logit in flatLogits) {
        double e = exp(logit - maxLogit);
        exps.add(e);
        sumExp += e;
      }
      List<double> softmax = exps.map((e) => e / sumExp).toList();
      double topScore = softmax.reduce(max);

      // Top score is around ~0.28, which is below OOD threshold 0.38
      expect(topScore < 0.38, isTrue);
    });
  });
}
