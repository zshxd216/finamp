import 'dart:ui';

extension BlankString on String {
  bool get isBlank => trim().isEmpty;

  bool get isNotBlank => !isBlank;
}

extension NullableEmptyString on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
}

extension NullableBlankString on String? {
  bool get isNullOrBlank => this == null || this!.isBlank;
}

extension NullableJoin on Iterable<String?> {
  /// Joins all non-null elements as String.  If none exist, returns null.
  String? joinNonNull([String separator = ""]) => nonNulls.isEmpty ? null : nonNulls.join(separator);
}

extension StringToColor on String {
  /// Converts a hex string like "#RRGGBB" or "#AARRGGBB" to a [Color]
  ///
  /// Returns null if [hex] is invalid
  Color? toColorOrNull() {
    final hex = replaceFirst('#', '');
    if (hex.length == 6) {
      return _parseColor('FF$hex');
    } else if (hex.length == 8) {
      return _parseColor(hex);
    }
    return null;
  }

  Color? _parseColor(String hex) {
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }
}
