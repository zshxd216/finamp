import 'dart:async';

import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/services/music_player_background_task.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'music_control_intents.dart';

class MusicControlActions extends StatelessWidget {
  final Widget child;

  const MusicControlActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final queueService = GetIt.instance<QueueService>();

    return StreamBuilder<FinampQueueInfo?>(
      stream: queueService.getQueueStream(),
      initialData: queueService.getQueue(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.currentTrack != null) {
          return _buildActions();
        } else {
          return child;
        }
      },
    );
  }

  Widget _buildActions() {
    final audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();

    return Actions(
      actions: {
        TogglePlaybackIntent: _NonConsumingCallbackAction<TogglePlaybackIntent>(
          onInvoke: (_) {
            if (_isInTextField()) return null;
            unawaited(audioHandler.togglePlayback());
            return null;
          },
        ),
        SkipToNextIntent: CallbackAction<SkipToNextIntent>(
          onInvoke: (_) {
            audioHandler.skipToNext();
            return null;
          },
        ),
        SkipToPreviousIntent: CallbackAction<SkipToPreviousIntent>(
          onInvoke: (_) {
            audioHandler.skipToPrevious();
            return null;
          },
        ),
        SeekForwardIntent: _NonConsumingCallbackAction<SeekForwardIntent>(
          onInvoke: (_) {
            if (_isInTextField()) return null;
            audioHandler.seek(audioHandler.playbackPosition + const Duration(seconds: 30));
            return null;
          },
        ),
        SeekBackwardIntent: _NonConsumingCallbackAction<SeekBackwardIntent>(
          onInvoke: (_) {
            if (_isInTextField()) return null;
            final current = audioHandler.playbackPosition;
            final target = current < const Duration(seconds: 5) ? Duration.zero : current - const Duration(seconds: 5);
            audioHandler.seek(target);
            return null;
          },
        ),
        VolumeUpIntent: _NonConsumingCallbackAction<VolumeUpIntent>(
          onInvoke: (_) {
            if (_isInTextField()) return null;
            final newVolume = (audioHandler.volume + 0.05).clamp(0.0, 1.0);
            audioHandler.setVolume(newVolume);
            return null;
          },
        ),
        VolumeDownIntent: _NonConsumingCallbackAction<VolumeDownIntent>(
          onInvoke: (_) {
            if (_isInTextField()) return null;
            final newVolume = (audioHandler.volume - 0.05).clamp(0.0, 1.0);
            audioHandler.setVolume(newVolume);
            return null;
          },
        ),
      },
      child: child,
    );
  }
}

class _NonConsumingCallbackAction<T extends Intent> extends CallbackAction<T> {
  _NonConsumingCallbackAction({required super.onInvoke});

  @override
  bool consumesKey(T intent) {
    return !_isInTextField();
  }
}

bool _isInTextField() {
  final FocusNode? primaryFocus = FocusManager.instance.primaryFocus;
  if (primaryFocus == null || primaryFocus.context == null) {
    return false;
  }

  final BuildContext? context = primaryFocus.context;
  if (context == null) {
    return false;
  }

  bool isInTextField = false;

  context.visitAncestorElements((Element element) {
    if (element.widget is TextField || element.widget is TextFormField) {
      isInTextField = true;
      return false;
    }
    return true;
  });

  return isInTextField;
}
