import 'package:finamp/components/Shortcuts/music_control_actions.dart';
import 'package:finamp/components/Shortcuts/music_control_intents.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalShortcutManager extends StatelessWidget {
  final Widget child;

  const GlobalShortcutManager({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.space): const TogglePlaybackIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): const SkipToNextIntent(),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): const SkipToPreviousIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): const SeekForwardIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): const SeekBackwardIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): const VolumeUpIntent(),
        const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): const VolumeDownIntent(),
      },
      child: MusicControlActions(child: child),
    );
  }
}
