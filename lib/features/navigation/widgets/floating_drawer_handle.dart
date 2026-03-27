import 'package:flutter/material.dart';

/// A small circular handle that opens the app drawer.
///
/// This is intended to be overlaid at a fixed position so it appears on all
/// pages consistently.
class FloatingDrawerHandle extends StatelessWidget {
  const FloatingDrawerHandle({
    super.key,
    required this.onTap,
    this.top = 56,
    this.left = 24,
  });

  final VoidCallback onTap;
  final double top;
  final double left;

  static const Color _accent = Color(0xFFF58220);

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Positioned(
      top: top,
      left: left,
      child: Semantics(
        button: true,
        label: canPop ? 'Back' : 'Open menu',
        child: Tooltip(
          message: canPop ? 'Back' : 'Menu',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canPop ? () => Navigator.of(context).maybePop() : onTap,
              child: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent, width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      canPop ? Icons.arrow_back_rounded : Icons.menu_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 22,
                    ),
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

