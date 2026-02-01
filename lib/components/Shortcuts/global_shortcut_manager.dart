import 'package:finamp/components/Shortcuts/music_control_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:finamp/utils/platform_helper.dart';

class GlobalShortcuts {
  static final Map<Intent, LogicalKeySet> _raw = {
    const TogglePlaybackIntent(): LogicalKeySet(LogicalKeyboardKey.space),
    const SkipToNextIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN),
    const SkipToPreviousIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyP),
    const SeekForwardIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight),
    const SeekBackwardIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft),
    const VolumeUpIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowUp),
    const VolumeDownIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowDown),
    const ToggleLoopModeIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyL),
    const TogglePlaybackOrderIntent(): LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
  };

  static Map<LogicalKeySet, Intent> get shortcutMap => _raw.map((intent, keySet) => MapEntry(keySet, intent));

  static String getDisplay(Type intentType) {
    final entry = _raw.entries.cast<MapEntry<Intent, LogicalKeySet>?>().firstWhere(
      (e) => e!.key.runtimeType == intentType,
      orElse: () => null,
    );

    if (entry == null) return '';
    final keys = entry.value.keys;
    final parts = <String>[];

    // Modifiers
    if (keys.contains(LogicalKeyboardKey.control)) parts.add(ShortcutKeyDisplay.primaryModifier);
    if (keys.contains(LogicalKeyboardKey.shift)) parts.add(ShortcutKeyDisplay.shift);
    if (keys.contains(LogicalKeyboardKey.alt)) parts.add(ShortcutKeyDisplay.alt);

    // Trigger Key
    final trigger = keys.firstWhere(
      (k) => !{
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.alt,
      }.contains(k),
    );

    parts.add(_formatKey(trigger));
    return parts.join('+');
  }

  static String _formatKey(LogicalKeyboardKey k) {
    if (k == LogicalKeyboardKey.arrowUp) return "↑";
    if (k == LogicalKeyboardKey.arrowDown) return "↓";
    if (k == LogicalKeyboardKey.arrowLeft) return "←";
    if (k == LogicalKeyboardKey.arrowRight) return "→";
    if (k == LogicalKeyboardKey.space) return "Space";
    return k.keyLabel.toUpperCase();
  }
}

class GlobalShortcutManager extends StatelessWidget {
  final Widget child;

  const GlobalShortcutManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: GlobalShortcuts.shortcutMap,
      child: Actions(
        actions: {
          ...getMusicControlActions(),
          // Other actions can be added here
        },
        child: child,
      ),
    );
  }
}
