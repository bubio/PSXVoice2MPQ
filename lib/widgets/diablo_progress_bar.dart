import 'package:flutter/material.dart';

class DiabloProgressBar extends StatelessWidget {
  final double? value; // null = indeterminate, 0.0-1.0 = determinate
  final double height;
  final double borderRadius;

  const DiabloProgressBar({
    super.key,
    this.value,
    this.height = 18,
    this.borderRadius = 9,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFF3D2A1A),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: value == null
          ? _IndeterminateProgressBar(height: height, borderRadius: borderRadius)
          : _DeterminateProgressBar(progress: value!, borderRadius: borderRadius),
    );
  }
}

class _DeterminateProgressBar extends StatelessWidget {
  final double progress;
  final double borderRadius;

  const _DeterminateProgressBar({
    required this.progress,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final clampedProgress = progress.clamp(0.0, 1.0);
        final width = constraints.maxWidth * clampedProgress;
        if (width <= 0) return const SizedBox.shrink();

        // Only round the right edge; left edge stays flush with container
        final isComplete = clampedProgress >= 1.0;
        final rightRadius = Radius.circular(borderRadius);
        final leftRadius = isComplete ? rightRadius : Radius.zero;

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.horizontal(
                left: leftRadius,
                right: rightRadius,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: const _TiledProgressImage(),
          ),
        );
      },
    );
  }
}

class _TiledProgressImage extends StatefulWidget {
  const _TiledProgressImage();

  @override
  State<_TiledProgressImage> createState() => _TiledProgressImageState();
}

class _TiledProgressImageState extends State<_TiledProgressImage> {
  ImageInfo? _imageInfo;
  ImageStream? _imageStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  void _resolveImage() {
    final ImageStream newStream = const AssetImage('assets/images/progressbar.png')
        .resolve(createLocalImageConfiguration(context));
    if (newStream.key != _imageStream?.key) {
      _imageStream?.removeListener(ImageStreamListener(_handleImageLoaded));
      _imageStream = newStream;
      newStream.addListener(ImageStreamListener(_handleImageLoaded));
    }
  }

  void _handleImageLoaded(ImageInfo info, bool synchronousCall) {
    setState(() {
      _imageInfo = info;
    });
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(_handleImageLoaded));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_imageInfo == null) {
      return const SizedBox.expand();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _TiledImagePainter(imageInfo: _imageInfo!),
        );
      },
    );
  }
}

class _TiledImagePainter extends CustomPainter {
  final ImageInfo imageInfo;

  _TiledImagePainter({required this.imageInfo});

  @override
  void paint(Canvas canvas, Size size) {
    final img = imageInfo.image;
    final srcHeight = img.height.toDouble();
    final dstHeight = size.height;
    final scale = dstHeight / srcHeight;
    final scaledWidth = img.width * scale;

    final paint = Paint()..filterQuality = FilterQuality.medium;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), srcHeight),
        Rect.fromLTWH(x, 0, scaledWidth, dstHeight),
        paint,
      );
      x += scaledWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _TiledImagePainter oldDelegate) {
    return oldDelegate.imageInfo != imageInfo;
  }
}

class _IndeterminateProgressBar extends StatefulWidget {
  final double height;
  final double borderRadius;

  const _IndeterminateProgressBar({
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_IndeterminateProgressBar> createState() => _IndeterminateProgressBarState();
}

class _IndeterminateProgressBarState extends State<_IndeterminateProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * 0.3;
            final position = _controller.value * (constraints.maxWidth + barWidth) - barWidth;
            return Stack(
              children: [
                Positioned(
                  left: position,
                  top: 0,
                  bottom: 0,
                  width: barWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const _TiledProgressImage(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
