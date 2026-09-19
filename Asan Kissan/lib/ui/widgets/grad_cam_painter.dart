import 'package:flutter/material.dart';

/// Jet Colormap CustomPainter for rendering Grad-CAM disease lesion activation heatmaps.
class GradCamPainter extends CustomPainter {
  final List<double> heatmapData;
  final int gridWidth;
  final int gridHeight;
  final double opacity;

  GradCamPainter({
    required this.heatmapData,
    required this.gridWidth,
    required this.gridHeight,
    this.opacity = 0.40, // 40% semi-transparent overlay
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heatmapData.isEmpty || gridWidth <= 0 || gridHeight <= 0) return;

    // Downsample factor to reduce drawRect calls from 50,176 to just 784.
    // This strictly prevents the massive DisplayList memory spike that causes OOM crashes.
    const int step = 8;
    final int newWidth = gridWidth ~/ step;
    final int newHeight = gridHeight ~/ step;
    
    final cellW = size.width / newWidth;
    final cellH = size.height / newHeight;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < newHeight; y++) {
      for (int x = 0; x < newWidth; x++) {
        
        // Average the activation values in the block
        double sum = 0.0;
        int count = 0;
        for (int dy = 0; dy < step; dy++) {
          for (int dx = 0; dx < step; dx++) {
            final origY = y * step + dy;
            final origX = x * step + dx;
            if (origY < gridHeight && origX < gridWidth) {
              final index = origY * gridWidth + origX;
              if (index < heatmapData.length) {
                sum += heatmapData[index];
                count++;
              }
            }
          }
        }
        
        final val = count > 0 ? (sum / count).clamp(0.0, 1.0) : 0.0;

        // Only render visible activation regions above low background noise threshold
        if (val > 0.10) {
          paint.color = _jetColor(val, opacity * (val.clamp(0.2, 1.0)));
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5),
            paint,
          );
        }
      }
    }
  }

  /// Maps a normalized activation value [0..1] to Jet Colormap RGB values.
  Color _jetColor(double v, double alpha) {
    v = v.clamp(0.0, 1.0);
    final r = (1.5 - (v * 4.0 - 3.0).abs()).clamp(0.0, 1.0);
    final g = (1.5 - (v * 4.0 - 2.0).abs()).clamp(0.0, 1.0);
    final b = (1.5 - (v * 4.0 - 1.0).abs()).clamp(0.0, 1.0);

    return Color.fromRGBO(
      (r * 255).round(),
      (g * 255).round(),
      (b * 255).round(),
      alpha,
    );
  }

  @override
  bool shouldRepaint(covariant GradCamPainter oldDelegate) {
    return oldDelegate.heatmapData != heatmapData ||
        oldDelegate.gridWidth != gridWidth ||
        oldDelegate.gridHeight != gridHeight ||
        oldDelegate.opacity != opacity;
  }
}
