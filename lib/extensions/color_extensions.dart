import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

extension AtContrast on Color {
  static const double _tolerance = 0.05;

  static final _atContrastLogger = Logger("AtContrast");

  // Contrast calculations
  double contrastRatio(num a, num b) {
    final ratio = (a + 0.05) / (b + 0.05);
    return ratio >= 1 ? ratio : 1 / ratio;
  }

  Color atContrast(double targetContrast, Color background, bool lighter) {
    final backgroundLuminance = background.computeLuminance();

    HSLColor hslColor = HSLColor.fromColor(this);

    double contrast = contrastRatio(computeLuminance(), backgroundLuminance);

    double minLightness = 0.0;
    double maxLightness = 1.0;
    double diff = contrast.abs() - targetContrast.abs();
    int steps = 0;
    int maxSteps = 25;

    // If diff is negative, we need more contrast.
    while (diff < -_tolerance && steps < maxSteps) {
      steps++;
      // print("contrast: $steps $diff");
      if (diff.isNegative) {
        if (lighter) {
          minLightness = hslColor.lightness;
        } else {
          maxLightness = hslColor.lightness;
        }

        final lightDiff = lighter ? maxLightness - minLightness : minLightness - maxLightness;

        hslColor = hslColor.withLightness(hslColor.lightness + lightDiff / 2);
      }

      contrast = contrastRatio(hslColor.toColor().computeLuminance(), backgroundLuminance);

      diff = (contrast.abs() - targetContrast.abs());
    }

    _atContrastLogger.info("Calculated contrast in $steps steps");

    return hslColor.toColor();
  }
}

extension ColorToHex on Color {
  /// Converts a [Color] to a hex string.
  ///
  /// Example: Color(0xFF2196F3) to "2196F3" or "FF2196F3"
  ///
  /// Note: the toARGB32 method used here might be imprecise on
  /// different platforms because of floating-point math
  String toHex({bool includeAlpha = false}) {
    final value = toARGB32();
    final hex = value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return includeAlpha ? '#$hex' : '#${hex.substring(2)}';
  }
}
