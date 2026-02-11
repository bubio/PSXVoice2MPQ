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
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;

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
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/button_bg.png'),
                centerSlice: const Rect.fromLTRB(10, 8, 100, 20),
                fit: BoxFit.fill,
                colorFilter: _isPressed
                    ? const ColorFilter.mode(Colors.black26, BlendMode.darken)
                    : _isHovered
                    ? const ColorFilter.mode(Colors.white10, BlendMode.lighten)
                    : null,
              ),
            ),
            child: Center(
              child: Padding(
                padding: widget.padding,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamilyFallback: Theme.of(context).textTheme.bodyMedium?.fontFamilyFallback,
                    shadows: const [
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
    );
  }
}
