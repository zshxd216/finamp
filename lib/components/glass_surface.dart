import 'dart:ui';

import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    Key? key,
    this.child,
    this.blurSigma = 20,
    this.opacity = 0.2,
    this.borderRadius,
    this.borderColor,
  }) : super(key: key);

  final Widget? child;
  final double blurSigma;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? BorderRadius.zero;
    final backgroundColor = Theme.of(context)
        .colorScheme
        .surface
        .withOpacity(opacity.clamp(0.0, 1.0));

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma,
          sigmaY: blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: borderColor ??
                  Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.08),
            ),
          ),
          child: child ?? const SizedBox.expand(),
        ),
      ),
    );
  }
}
