import 'package:flutter/material.dart';

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
