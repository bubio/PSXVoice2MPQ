import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class DiabloButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const DiabloButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width,
    this.height = 32,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  State<DiabloButton> createState() => _DiabloButtonState();
}

class _DiabloButtonState extends State<DiabloButton> {
  static const _background = AssetImage('assets/images/button_bg.png');
  static const _centerSlice = Rect.fromLTRB(10, 8, 100, 20);

  bool _isPressed = false;
  bool _isHovered = false;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  late final _imageListener = ImageStreamListener((info, _) {
    setState(() {
      _imageInfo?.dispose();
      _imageInfo = info;
    });
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = _background.resolve(createLocalImageConfiguration(context));
    if (stream.key != _imageStream?.key) {
      _imageStream?.removeListener(_imageListener);
      _imageStream = stream..addListener(_imageListener);
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageListener);
    _imageInfo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final imageInfo = _imageInfo;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: CustomPaint(
            painter: imageInfo == null
                ? null
                : _NineSlicePainter(
                    image: imageInfo.image,
                    scale: imageInfo.scale,
                    centerSlice: _centerSlice,
                    colorFilter: _isPressed
                        ? const ColorFilter.mode(
                            Colors.black26,
                            BlendMode.darken,
                          )
                        : _isHovered
                        ? const ColorFilter.mode(
                            Colors.white10,
                            BlendMode.lighten,
                          )
                        : null,
                  ),
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Center(
                child: Padding(
                  padding: widget.padding,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 1,
                        ),
                      ],
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws [image] as a nine-slice that never shrinks the image.
///
/// Impeller garbles the top and bottom edges when it draws the image scaled
/// down (DecorationImage.centerSlice does this for buttons narrower than
/// the image), so a middle cell that would shrink is cropped from the
/// center of its slice instead. [centerSlice] is in logical pixels, so
/// resolution variants (2.0x/ assets) use the same slice.
class _NineSlicePainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Rect centerSlice;
  final ColorFilter? colorFilter;

  _NineSlicePainter({
    required this.image,
    required this.scale,
    required this.centerSlice,
    required this.colorFilter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final w = image.width / scale;
    final h = image.height / scale;
    final c = centerSlice;

    // Grid lines of the 3x3 cells on the button
    final dstX = [0.0, c.left, size.width - (w - c.right), size.width];
    final dstY = [0.0, c.top, size.height - (h - c.bottom), size.height];
    final srcX = _sourceSpans(c.left, c.right, w, dstX[2] - dstX[1]);
    final srcY = _sourceSpans(c.top, c.bottom, h, dstY[2] - dstY[1]);

    // Filter the assembled button as one layer; filtering each cell would
    // also tint the anti-aliased seams between cells into visible lines.
    // The clip keeps the filter from tinting the rest of the window.
    final filter = colorFilter;
    if (filter != null) {
      final bounds = Offset.zero & size;
      canvas.save();
      canvas.clipRect(bounds);
      canvas.saveLayer(bounds, Paint()..colorFilter = filter);
    }
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(
            srcX[col].$1 * scale,
            srcY[row].$1 * scale,
            srcX[col].$2 * scale,
            srcY[row].$2 * scale,
          ),
          Rect.fromLTRB(dstX[col], dstY[row], dstX[col + 1], dstY[row + 1]),
          paint,
        );
      }
    }
    if (filter != null) {
      canvas.restore();
      canvas.restore();
    }
  }

  /// Source spans of the three cells along one axis. The middle span is
  /// cropped around its center to [dstMiddle] when it would otherwise shrink,
  /// starting on a whole pixel so the crop is not resampled.
  static List<(double, double)> _sourceSpans(
    double start,
    double end,
    double length,
    double dstMiddle,
  ) {
    final excess = (end - start) - dstMiddle;
    if (excess <= 0) return [(0, start), (start, end), (end, length)];
    final cropStart = (start + excess / 2).floorToDouble();
    return [(0, start), (cropStart, cropStart + dstMiddle), (end, length)];
  }

  @override
  bool shouldRepaint(_NineSlicePainter oldDelegate) =>
      image != oldDelegate.image ||
      scale != oldDelegate.scale ||
      centerSlice != oldDelegate.centerSlice ||
      colorFilter != oldDelegate.colorFilter;
}
