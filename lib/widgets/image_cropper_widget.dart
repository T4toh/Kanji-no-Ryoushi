import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
// MatrixUtils is available via material.dart; remove explicit rendering import
import '../services/image_service.dart';

/// Widget modular para recortar una región de una imagen.
/// Devuelve el archivo recortado mediante [onCropped].
class ImageCropperWidget extends StatefulWidget {
  final File imageFile;
  final FutureOr<void> Function(File cropped) onCropped;
  final VoidCallback? onCancel;

  const ImageCropperWidget({
    super.key,
    required this.imageFile,
    required this.onCropped,
    this.onCancel,
  });

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  ui.Image? _intrinsicImage;

  // Transformation controller for InteractiveViewer (zoom/pan)
  final TransformationController _transformationController =
      TransformationController();

  // Selection in image-widget coordinates (untransformed)
  Rect? _selection;
  // Start point for new selection in image-widget coords
  Offset? _startPointImage;
  // For moving selection
  bool _isMoving = false;
  Offset? _lastImagePoint;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _intrinsicImage = frame.image;
    });
  }

  void _onPanStart(
    DragStartDetails details,
    Size imageDisplaySize,
    Offset imageOffset,
  ) {
    final local = details.localPosition;
    if (!_pointInsideImage(local, imageOffset, imageDisplaySize)) return;

    // Map local point to image-widget coords by applying inverse transform
    final imageLocal = local - imageOffset;
    final Matrix4 m = _transformationController.value.clone();
    m.invert();
    final Offset imgPoint = MatrixUtils.transformPoint(m, imageLocal);

    // If inside existing selection, start moving
    if (_selection != null && _selection!.contains(imgPoint)) {
      _isMoving = true;
      _lastImagePoint = imgPoint;
    } else {
      // Start new selection
      _isMoving = false;
      _startPointImage = imgPoint;
      _selection = Rect.fromLTWH(imgPoint.dx, imgPoint.dy, 0, 0);
    }
    setState(() {});
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    Size imageDisplaySize,
    Offset imageOffset,
  ) {
    final local = details.localPosition;
    if (!_pointInsideImage(local, imageOffset, imageDisplaySize)) return;

    final imageLocal = local - imageOffset;
    final Matrix4 m = _transformationController.value.clone();
    m.invert();
    final Offset imgPoint = MatrixUtils.transformPoint(m, imageLocal);

    if (_isMoving && _selection != null && _lastImagePoint != null) {
      final delta = imgPoint - _lastImagePoint!;
      final newRect = _selection!.shift(delta);
      // clamp within image display bounds
      _selection = _clampRectToImage(newRect, imageDisplaySize);
      _lastImagePoint = imgPoint;
    } else if (_startPointImage != null) {
      final left = math.min(_startPointImage!.dx, imgPoint.dx);
      final top = math.min(_startPointImage!.dy, imgPoint.dy);
      final right = math.max(_startPointImage!.dx, imgPoint.dx);
      final bottom = math.max(_startPointImage!.dy, imgPoint.dy);
      _selection = Rect.fromLTWH(left, top, right - left, bottom - top);
    }
    setState(() {});
  }

  void _onPanEnd(DragEndDetails details) {
    _isMoving = false;
    _lastImagePoint = null;
    _startPointImage = null;
  }

  bool _pointInsideImage(Offset p, Offset imageOffset, Size imageSize) {
    return p.dx >= imageOffset.dx &&
        p.dx <= imageOffset.dx + imageSize.width &&
        p.dy >= imageOffset.dy &&
        p.dy <= imageOffset.dy + imageSize.height;
  }

  Rect _clampRectToImage(Rect rect, Size imageSize) {
    final left = rect.left.clamp(0.0, imageSize.width);
    final top = rect.top.clamp(0.0, imageSize.height);
    final right = rect.right.clamp(0.0, imageSize.width);
    final bottom = rect.bottom.clamp(0.0, imageSize.height);
    return Rect.fromLTWH(
      left,
      top,
      (right - left).clamp(0.0, imageSize.width),
      (bottom - top).clamp(0.0, imageSize.height),
    );
  }

  Future<void> _confirmCrop(BoxConstraints constraints) async {
    if (_selection == null || _intrinsicImage == null) return;
    setState(() => _isProcessing = true);

    // Compute displayed image size and mapping
    final widgetW = constraints.maxWidth;
    final widgetH = constraints.maxHeight;
    final imgW = _intrinsicImage!.width.toDouble();
    final imgH = _intrinsicImage!.height.toDouble();

    final scale = math.min(widgetW / imgW, widgetH / imgH);
    final displayW = imgW * scale;
    final displayH = imgH * scale;
    final offsetX = (widgetW - displayW) / 2;
    final offsetY = (widgetH - displayH) / 2;

    // Map selection from widget coords to image pixel coords
    final sel = _selection!;
    final left = ((sel.left - offsetX) / scale).clamp(0, imgW).toDouble();
    final top = ((sel.top - offsetY) / scale).clamp(0, imgH).toDouble();
    final width = (sel.width / scale).clamp(1, imgW - left).toDouble();
    final height = (sel.height / scale).clamp(1, imgH - top).toDouble();

    final cropRect = CropRect(
      left: left,
      top: top,
      width: width,
      height: height,
    );

    try {
      final croppedFile = await ImageService.cropImage(
        widget.imageFile,
        cropRect,
      );
      await widget.onCropped(croppedFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al recortar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_intrinsicImage == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final imgW = _intrinsicImage!.width.toDouble();
        final imgH = _intrinsicImage!.height.toDouble();
        final scale = math.min(
          constraints.maxWidth / imgW,
          constraints.maxHeight / imgH,
        );
        final displayW = imgW * scale;
        final displayH = imgH * scale;
        final offsetX = (constraints.maxWidth - displayW) / 2;
        final offsetY = (constraints.maxHeight - displayH) / 2;
        final imageOffset = Offset(offsetX, offsetY);
        final imageDisplaySize = Size(displayW, displayH);

        return Stack(
          children: [
            // InteractiveViewer para zoom/pan
            Positioned(
              left: imageOffset.dx,
              top: imageOffset.dy,
              width: imageDisplaySize.width,
              height: imageDisplaySize.height,
              child: InteractiveViewer(
                transformationController: _transformationController,
                clipBehavior: Clip.none,
                panEnabled: true,
                scaleEnabled: true,
                minScale: 1.0,
                maxScale: 5.0,
                child: Image.file(widget.imageFile, fit: BoxFit.fill),
              ),
            ),

            // Gesture detector for selection (captures gestures over the whole area)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (d) =>
                    _onPanStart(d, imageDisplaySize, imageOffset),
                onPanUpdate: (d) =>
                    _onPanUpdate(d, imageDisplaySize, imageOffset),
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _CropPainter(selection: _selection),
                ),
              ),
            ),

            // Hint banner
            Positioned(
              left: 16,
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Arrastrá para seleccionar. Arrastrá dentro del cuadro para mover. Pellizcá para hacer zoom.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            // Controls
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : widget.onCancel,
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () => _confirmCrop(constraints),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Recortar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CropPainter extends CustomPainter {
  final Rect? selection;

  _CropPainter({this.selection});

  @override
  void paint(Canvas canvas, Size size) {
    if (selection == null) return;
    final paint = Paint()
      ..color = Colors.black.withAlpha((0.45 * 255).toInt())
      ..style = PaintingStyle.fill;

    // Darken exterior by drawing four rects around selection
    final sel = selection!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, sel.top), paint);
    canvas.drawRect(Rect.fromLTWH(0, sel.top, sel.left, sel.height), paint);
    canvas.drawRect(
      Rect.fromLTWH(sel.right, sel.top, size.width - sel.right, sel.height),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, sel.bottom, size.width, size.height - sel.bottom),
      paint,
    );

    // Border
    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(sel, border);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) =>
      oldDelegate.selection != selection;
}
