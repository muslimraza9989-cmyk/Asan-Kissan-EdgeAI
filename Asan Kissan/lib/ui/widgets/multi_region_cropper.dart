import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import '../theme/app_theme.dart';

/// Interactive Region of Interest (ROI) box representing a leaf in the canopy image.
class LeafRoiBox {
  final int id;
  Rect normalizedRect; // [0.0..1.0] normalized coordinates

  LeafRoiBox({
    required this.id,
    required this.normalizedRect,
  });
}

/// Interactive Touch Widget allowing farmers to select 1 to 4 leaves in a canopy photo.
class MultiRegionCropper extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(List<Uint8List> croppedLeafBytes) onCropComplete;

  const MultiRegionCropper({
    super.key,
    required this.imageBytes,
    required this.onCropComplete,
  });

  @override
  State<MultiRegionCropper> createState() => _MultiRegionCropperState();
}

class _MultiRegionCropperState extends State<MultiRegionCropper> {
  final List<LeafRoiBox> _boxes = [];
  int _nextId = 1;
  int? _selectedBoxIndex;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Default initial boxes for canopy
    _boxes.add(
      LeafRoiBox(
        id: _nextId++,
        normalizedRect: const Rect.fromLTWH(0.15, 0.15, 0.40, 0.35),
      ),
    );
    _boxes.add(
      LeafRoiBox(
        id: _nextId++,
        normalizedRect: const Rect.fromLTWH(0.45, 0.50, 0.40, 0.35),
      ),
    );
    _selectedBoxIndex = 0;
  }

  void _addBox() {
    if (_boxes.length >= 4) return;
    setState(() {
      final double offset = (_boxes.length * 0.10) % 0.4;
      _boxes.add(
        LeafRoiBox(
          id: _nextId++,
          normalizedRect: Rect.fromLTWH(0.20 + offset, 0.20 + offset, 0.38, 0.32),
        ),
      );
      _selectedBoxIndex = _boxes.length - 1;
    });
  }

  void _removeBox(int index) {
    if (_boxes.length <= 1) return;
    setState(() {
      _boxes.removeAt(index);
      _selectedBoxIndex = _boxes.isNotEmpty ? 0 : null;
    });
  }

  Future<void> _processCrops() async {
    setState(() => _isProcessing = true);
    try {
      final decoded = img.decodeImage(widget.imageBytes);
      if (decoded == null) {
        throw Exception('Failed to decode image.');
      }
      final baked = img.bakeOrientation(decoded);

      final List<Uint8List> crops = [];
      for (final box in _boxes) {
        final norm = box.normalizedRect;
        final x = (norm.left * baked.width).round().clamp(0, baked.width - 1);
        final y = (norm.top * baked.height).round().clamp(0, baked.height - 1);
        final w = (norm.width * baked.width).round().clamp(10, baked.width - x);
        final h = (norm.height * baked.height).round().clamp(10, baked.height - y);

        final croppedImg = img.copyCrop(baked, x: x, y: y, width: w, height: h);
        final jpgBytes = Uint8List.fromList(img.encodeJpg(croppedImg, quality: 90));
        crops.add(jpgBytes);
      }

      widget.onCropComplete(crops);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping leaves: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select Leaves to Analyze',
          style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_boxes.length < 4)
            IconButton(
              icon: const Icon(Icons.add_box_rounded),
              tooltip: 'Add Leaf Region',
              onPressed: _addBox,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.lightMint,
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: AppTheme.primaryGreen, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Drag or adjust focus boxes to target up to 4 individual leaves.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        color: Colors.black,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              widget.imageBytes,
                              fit: BoxFit.contain,
                            ),
                            // Render ROI boxes
                            for (int i = 0; i < _boxes.length; i++)
                              _buildRoiBoxWidget(
                                i,
                                _boxes[i],
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Region management bar & Analyze button
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                      onPressed: _boxes.length < 4 ? _addBox : null,
                      icon: const Icon(Icons.add, color: AppTheme.primaryGreen),
                      label: Text(
                        'Add Leaf (${_boxes.length}/4)',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _processCrops,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.analytics_rounded, size: 20),
                      label: Text(
                        _isProcessing
                            ? 'Processing...'
                            : 'Analyze ${_boxes.length} Leaves',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoiBoxWidget(
    int index,
    LeafRoiBox box,
    double parentW,
    double parentH,
  ) {
    final isSelected = _selectedBoxIndex == index;
    final left = (box.normalizedRect.left * parentW).clamp(0.0, parentW - 40.0);
    final top = (box.normalizedRect.top * parentH).clamp(0.0, parentH - 40.0);
    final width = (box.normalizedRect.width * parentW).clamp(40.0, parentW - left);
    final height = (box.normalizedRect.height * parentH).clamp(40.0, parentH - top);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => setState(() => _selectedBoxIndex = index),
        onPanUpdate: (details) {
          setState(() {
            _selectedBoxIndex = index;
            final dNormX = details.delta.dx / parentW;
            final dNormY = details.delta.dy / parentH;

            final newLeft = (box.normalizedRect.left + dNormX).clamp(0.0, 1.0 - box.normalizedRect.width);
            final newTop = (box.normalizedRect.top + dNormY).clamp(0.0, 1.0 - box.normalizedRect.height);

            box.normalizedRect = Rect.fromLTWH(
              newLeft,
              newTop,
              box.normalizedRect.width,
              box.normalizedRect.height,
            );
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.amberAccent : Colors.lightGreenAccent,
              width: isSelected ? 2.5 : 1.8,
            ),
            color: (isSelected ? Colors.amber : Colors.lightGreen)
                .withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              // Badge header
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber.shade800 : AppTheme.primaryGreen,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Leaf #${box.id}',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Delete button if > 1 box
              if (_boxes.length > 1)
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _removeBox(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
