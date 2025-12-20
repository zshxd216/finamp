import 'package:finamp/components/Shortcuts/music_control_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalShortcutManager extends StatelessWidget {
  final Widget child;

  const GlobalShortcutManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        // Music control shortcuts
        const SingleActivator(LogicalKeyboardKey.space): const TogglePlaybackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): const SkipToNextIntent(),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): const SkipToPreviousIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const SeekForwardIntent(), // Seek +30s
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const SeekBackwardIntent(), // Seek -5s
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): const VolumeUpIntent(), // Vol +5%
        const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): const VolumeDownIntent(), // Vol -5%
        const SingleActivator(LogicalKeyboardKey.keyL, control: true): const ToggleLoopModeIntent(),
      },
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
