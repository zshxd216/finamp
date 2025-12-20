import 'dart:async';

import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/music_player_background_task.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TogglePlaybackIntent extends Intent {
  const TogglePlaybackIntent();
}

class SkipToNextIntent extends Intent {
  const SkipToNextIntent();
}

class SkipToPreviousIntent extends Intent {
  const SkipToPreviousIntent();
}

class SeekForwardIntent extends Intent {
  const SeekForwardIntent();
}

class SeekBackwardIntent extends Intent {
  const SeekBackwardIntent();
}

class VolumeUpIntent extends Intent {
  const VolumeUpIntent();
}

class VolumeDownIntent extends Intent {
  const VolumeDownIntent();
}

Map<Type, Action<Intent>> getMusicControlActions() {
  final audioHandler = GetIt.instance<MusicPlayerBackgroundTask>();

  return {
    TogglePlaybackIntent: _NonConsumingCallbackAction<TogglePlaybackIntent>(
      onInvoke: (_) {
        unawaited(audioHandler.togglePlayback());
        return null;
      },
    ),
    SkipToNextIntent: _CustomCallbackAction<SkipToNextIntent>(
      onInvoke: (_) {
        audioHandler.skipToNext();
        GlobalSnackbar.message((context) => AppLocalizations.of(context)!.skipToNextTrackButtonTooltip);
        return null;
      },
    ),
    SkipToPreviousIntent: _CustomCallbackAction<SkipToPreviousIntent>(
      onInvoke: (_) {
        audioHandler.skipToPrevious();
        GlobalSnackbar.message((context) => AppLocalizations.of(context)!.skipToPreviousTrackButtonTooltip);
        return null;
      },
    ),
    SeekForwardIntent: _NonConsumingCallbackAction<SeekForwardIntent>(
      onInvoke: (_) {
        audioHandler.seek(audioHandler.playbackPosition + const Duration(seconds: 30));
        return null;
      },
    ),
    SeekBackwardIntent: _NonConsumingCallbackAction<SeekBackwardIntent>(
      onInvoke: (_) {
        final current = audioHandler.playbackPosition;
        final target = current < const Duration(seconds: 5) ? Duration.zero : current - const Duration(seconds: 5);
        audioHandler.seek(target);
        return null;
      },
    ),
    VolumeUpIntent: _NonConsumingCallbackAction<VolumeUpIntent>(
      onInvoke: (_) {
        final newVolume = (audioHandler.volume + 0.05).clamp(0.0, 1.0);
        audioHandler.setVolume(newVolume);
        return null;
      },
    ),
    VolumeDownIntent: _NonConsumingCallbackAction<VolumeDownIntent>(
      onInvoke: (_) {
        final newVolume = (audioHandler.volume - 0.05).clamp(0.0, 1.0);
        audioHandler.setVolume(newVolume);
        return null;
      },
    ),
  };
}

class _CustomCallbackAction<T extends Intent> extends CallbackAction<T> {
  _CustomCallbackAction({required super.onInvoke});

  @override
  Object? invoke(T intent) {
    if (GetIt.instance<QueueService>().getQueue().currentTrack == null) return null;
    return super.invoke(intent);
  }
}

class _NonConsumingCallbackAction<T extends Intent> extends _CustomCallbackAction<T> {
  _NonConsumingCallbackAction({required super.onInvoke});

  @override
  bool consumesKey(T intent) {
    return !_isInTextField();
  }

  @override
  Object? invoke(T intent) {
    if (_isInTextField()) return null;
    return super.invoke(intent);
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
