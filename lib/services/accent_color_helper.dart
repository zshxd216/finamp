import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:hive_ce_flutter/adapters.dart';

/// A helper class for persisting and retrieving the app's accent color
///
/// - The accent color is stored as a **hex string** (e.g. `"FF2196F3"`)
class AccentColorHelper {
  static const key = "AccentColor";

  static ValueListenable<Box<Color?>> get accentColorListener => Hive.box<Color?>(key).listenable(keys: [key]);

  static void saveAccentColor([Color? color]) {
    Hive.box<Color?>(key).put(key, color);
  }

  /// Converts a [Color] to a hex string.
  ///
  /// Example: Color(0xFF2196F3) → "2196F3"
  static String? toHex(Color? color, {bool includeAlpha = false}) {
    if (color == null) return null;
    final a = ((color.a * 255.0).round() & 0xFF);
    final r = ((color.r * 255.0).round() & 0xFF);
    final g = ((color.g * 255.0).round() & 0xFF);
    final b = ((color.b * 255.0).round() & 0xFF);

    final alpha = a.toRadixString(16).padLeft(2, '0');
    final red = r.toRadixString(16).padLeft(2, '0');
    final green = g.toRadixString(16).padLeft(2, '0');
    final blue = b.toRadixString(16).padLeft(2, '0');

    return '${includeAlpha ? alpha : ''}$red$green$blue'.toUpperCase();
  }

  /// Converts a hex string ("#FFFFFF", or "FFFFFF") to a [Color].
  static Color? fromHex(String? hex) {
    if (hex == null) return null;

    hex = hex.replaceAll('#', '');

    if (hex.length != 6 && hex.length != 8) return null;

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
