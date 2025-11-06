import 'dart:io';

import 'package:flutter/material.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/TranscodingSettingsScreen/bitrate_selector.dart';
import '../components/TranscodingSettingsScreen/transcode_switch.dart';
import '../models/finamp_models.dart';
import '../services/finamp_settings_helper.dart';

class TranscodingSettingsScreen extends ConsumerStatefulWidget {
  const TranscodingSettingsScreen({super.key});
  static const routeName = "/settings/transcoding";
  @override
  ConsumerState<TranscodingSettingsScreen> createState() => _TranscodingSettingsScreenState();
}

enum FinampTranscodingStreamingFormats { custom, low, medium, high, veryHigh, noTranscode }

final wifiStreamingQualityProvider = StateProvider<FinampTranscodingStreamingFormats>((ref) {
  return FinampTranscodingStreamingFormats.high;
});
final celluarStreamingQualityProvider = StateProvider<FinampTranscodingStreamingFormats>((ref) {
  return FinampTranscodingStreamingFormats.high;
});
final downloadQualityProvider = StateProvider<FinampTranscodingStreamingFormats>((ref) {
  return FinampTranscodingStreamingFormats.high;
});

final advancedSettings = StateProvider<bool>((ref) {
  return false;
});

class _TranscodingSettingsScreenState extends ConsumerState<TranscodingSettingsScreen> {
  FinampTranscodingStreamingFormats transcodeProfile = FinampTranscodingStreamingFormats.custom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.transcoding),
        actions: [
          FinampSettingsHelper.makeSettingsResetButtonWithDialog(
            context,
            FinampSettingsHelper.resetTranscodingSettings,
          ),
        ],
      ),
      body: ListView(
        children: [
          const AdvancedSettingsSwitch(),

          if (!ref.watch(advancedSettings)) ...[
            const SimpleWiFiStreamingTranscodingFormatDropdownListTile(),
            const SimpleCelluarStreamingTranscodingFormatDropdownListTile(),
            const SimpleDownloadTranscodingFormatDropdownListTile(),
          ],

          if (ref.watch(advancedSettings)) ...[
            const TranscodeSwitch(),
            Divider(),
            // Conditional widgets
            if (ref.watch(finampSettingsProvider.shouldTranscode)) ...[
              const WiFiStreamingTranscodingFormatDropdownListTile(),
              const BitrateSelector(),
              Divider(),
              const CelluarStreamingTranscodingFormatDropdownListTile(),
              const BitrateSelector(),
              Divider(),
            ],

            const DownloadTranscodeEnableDropdownListTile(),
            if (ref.watch(finampSettingsProvider.shouldTranscodeDownloads) != TranscodeDownloadsSetting.never) ...[
              const DownloadTranscodeCodecDropdownListTile(),
              const DownloadBitrateSelector(),
            ]
          ],
        ],
      ),
    );
  }
}

class AdvancedSettingsSwitch extends ConsumerWidget {
  const AdvancedSettingsSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile.adaptive(
      title: Text("Enable advanced settings"),
      subtitle: Text("For advanced users"),
      value: ref.watch(advancedSettings),
      onChanged: (value) => (ref.read(advancedSettings.notifier).state = value),
    );
  }
}

class DownloadBitrateSelector extends ConsumerWidget {
  const DownloadBitrateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcodeProfile = ref.watch(finampSettingsProvider.downloadTranscodingProfile);
    return Column(
      children: [
        ListTile(
          title: Text(AppLocalizations.of(context)!.downloadBitrate),
          subtitle: Text(AppLocalizations.of(context)!.downloadBitrateSubtitle),
        ),
        // We do all of this division/multiplication because Jellyfin wants us to specify bitrates in bits, not kilobits.
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Slider(
              min: 64,
              max: 320,
              value: (transcodeProfile.stereoBitrate / 1000).clamp(64, 320),
              divisions: 8,
              label: transcodeProfile.bitrateKbps,
              onChanged: (value) => FinampSetters.setDownloadTranscodeBitrate((value * 1000).toInt()),
              autofocus: false,
              focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
            ),
            Text(transcodeProfile.bitrateKbps, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ],
    );
  }
}

class DownloadTranscodeEnableDropdownListTile extends ConsumerWidget {
  const DownloadTranscodeEnableDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.downloadTranscodeEnableTitle),
      trailing: DropdownButton<TranscodeDownloadsSetting>(
        value: ref.watch(finampSettingsProvider.shouldTranscodeDownloads),
        items: TranscodeDownloadsSetting.values
            .map(
              (e) => DropdownMenuItem<TranscodeDownloadsSetting>(
                value: e,
                child: Text(AppLocalizations.of(context)!.downloadTranscodeEnableOption(e.name)),
              ),
            )
            .toList(),
        onChanged: FinampSetters.setShouldTranscodeDownloads.ifNonNull,
      ),
    );
  }
}

class DownloadTranscodeCodecDropdownListTile extends ConsumerWidget {
  const DownloadTranscodeCodecDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.downloadTranscodeCodecTitle),
      trailing: DropdownButton<FinampTranscodingCodec>(
        value: ref.watch(finampSettingsProvider.downloadTranscodingProfile).codec,
        items: FinampTranscodingCodec.values
            .where((element) => !Platform.isIOS || element.iosCompatible)
            .where((element) => element != FinampTranscodingCodec.original)
            .map((e) => DropdownMenuItem<FinampTranscodingCodec>(value: e, child: Text(e.name.toUpperCase())))
            .toList(),
        onChanged: FinampSetters.setDownloadTranscodingCodec,
      ),
    );
  }
}

class SimpleDownloadTranscodingFormatDropdownListTile extends ConsumerWidget {
  const SimpleDownloadTranscodingFormatDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcodeProfile = ref.watch(downloadQualityProvider);

    return ListTile(
      title: Text("Download Quality"),
      subtitle: Text("Choose the quality of your audio to use when you are in offline mode."),
      trailing: DropdownButton<FinampTranscodingStreamingFormats>(
        value: transcodeProfile,
        items: [
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.custom, child: Text("Select one")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.low, child: Text("Low (64kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.medium, child: Text("Medium (128kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.high, child: Text("High (196kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.veryHigh, child: Text("Very High (256kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.noTranscode, child: Text("No Transcoding")),
        ],
        onChanged: (value) {
          if (value == null) return;
          ref.read(downloadQualityProvider.notifier).state = value;
          switch (value) {
            case FinampTranscodingStreamingFormats.custom:
              break;
            case FinampTranscodingStreamingFormats.low:
              FinampSetters.setShouldTranscodeDownloads(TranscodeDownloadsSetting.always);
              FinampSetters.setDownloadTranscodeBitrate(64 * 1000);
              break;
            case FinampTranscodingStreamingFormats.medium:
              FinampSetters.setShouldTranscodeDownloads(TranscodeDownloadsSetting.always);
              FinampSetters.setDownloadTranscodeBitrate(128 * 1000);
              break;
            case FinampTranscodingStreamingFormats.high:
              FinampSetters.setShouldTranscodeDownloads(TranscodeDownloadsSetting.always);
              FinampSetters.setDownloadTranscodeBitrate(196 * 1000);
              break;
            case FinampTranscodingStreamingFormats.veryHigh:
              FinampSetters.setShouldTranscodeDownloads(TranscodeDownloadsSetting.always);
              FinampSetters.setDownloadTranscodeBitrate(256 * 1000);
              break;
            case FinampTranscodingStreamingFormats.noTranscode:
              FinampSetters.setShouldTranscodeDownloads(TranscodeDownloadsSetting.never);
              break;
          }
          FinampSetters.setDownloadTranscodingCodec(FinampTranscodingCodec.aac);
        },
      ),
    );
  }
}

class SimpleCelluarStreamingTranscodingFormatDropdownListTile extends ConsumerWidget {
  const SimpleCelluarStreamingTranscodingFormatDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcodeProfile = ref.watch(celluarStreamingQualityProvider);

    return ListTile(
      title: Text("Celluar Streamnig Quality"),
      subtitle: Text("Choose the quality of your audio when you are connected to the interenet over celluar network."),
      trailing: DropdownButton<FinampTranscodingStreamingFormats>(
        value: transcodeProfile,
        items: [
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.custom, child: Text("Select one")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.low, child: Text("Low (64kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.medium, child: Text("Medium (128kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.high, child: Text("High (196kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.veryHigh, child: Text("Very High (256kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.noTranscode, child: Text("No Transcoding")),
        ],
        onChanged: (value) {
          if (value == null) return;
          ref.read(celluarStreamingQualityProvider.notifier).state = value;
          switch (value) {
            case FinampTranscodingStreamingFormats.custom:
              break;
            case FinampTranscodingStreamingFormats.low:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(64 * 1000);
              break;
            case FinampTranscodingStreamingFormats.medium:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(128 * 1000);
              break;
            case FinampTranscodingStreamingFormats.high:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(196 * 1000);
              break;
            case FinampTranscodingStreamingFormats.veryHigh:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(256 * 1000);
              break;
            case FinampTranscodingStreamingFormats.noTranscode:
              FinampSetters.setShouldTranscode(false);
              break;
          }
          FinampSetters.setTranscodingStreamingFormat(FinampTranscodingStreamingFormat.aacFragmentedMp4);
        },
      ),
    );
  }
}

class SimpleWiFiStreamingTranscodingFormatDropdownListTile extends ConsumerWidget {
  const SimpleWiFiStreamingTranscodingFormatDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcodeProfile = ref.watch(wifiStreamingQualityProvider);

    return ListTile(
      title: Text("Wi-Fi Streamnig Quality"),
      subtitle: Text("Choose the quality of your audio when you are connected to the interenet over WiFi."),
      trailing: DropdownButton<FinampTranscodingStreamingFormats>(
        value: transcodeProfile,
        items: [
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.custom, child: Text("Select one")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.low, child: Text("Low (64kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.medium, child: Text("Medium (128kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.high, child: Text("High (196kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.veryHigh, child: Text("Very High (256kbps)")),
          DropdownMenuItem(value: FinampTranscodingStreamingFormats.noTranscode, child: Text("No Transcoding")),
        ],
        onChanged: (value) {
          if (value == null) return;
          ref.read(wifiStreamingQualityProvider.notifier).state = value;
          switch (value) {
            case FinampTranscodingStreamingFormats.custom:
              break;
            case FinampTranscodingStreamingFormats.low:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(64 * 1000);
              break;
            case FinampTranscodingStreamingFormats.medium:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(128 * 1000);
              break;
            case FinampTranscodingStreamingFormats.high:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(196 * 1000);
              break;
            case FinampTranscodingStreamingFormats.veryHigh:
              FinampSetters.setShouldTranscode(true);
              FinampSetters.setTranscodeBitrate(256 * 1000);
              break;
            case FinampTranscodingStreamingFormats.noTranscode:
              FinampSetters.setShouldTranscode(false);
              break;
          }
          FinampSetters.setTranscodingStreamingFormat(FinampTranscodingStreamingFormat.aacFragmentedMp4);
        },
      ),
    );
  }
}

class WiFiStreamingTranscodingFormatDropdownListTile extends ConsumerWidget {
  const WiFiStreamingTranscodingFormatDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text("Select Wi-Fi Transcoding formatt"),
      subtitle: Text(AppLocalizations.of(context)!.transcodingStreamingFormatSubtitle),
      trailing: DropdownButton<FinampTranscodingStreamingFormat>(
        value: ref.watch(finampSettingsProvider.transcodingStreamingFormat),
        items: FinampTranscodingStreamingFormat.values
            .map(
              (e) => DropdownMenuItem<FinampTranscodingStreamingFormat>(
                value: e,
                child: Text("${e.codec}+${e.container}".toUpperCase()),
              ),
            )
            .toList(),
        onChanged: FinampSetters.setTranscodingStreamingFormat.ifNonNull,
      ),
    );
  }
}

class CelluarStreamingTranscodingFormatDropdownListTile extends ConsumerWidget {
  const CelluarStreamingTranscodingFormatDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(AppLocalizations.of(context)!.transcodingStreamingFormatTitle),
      subtitle: Text(AppLocalizations.of(context)!.transcodingStreamingFormatSubtitle),
      trailing: DropdownButton<FinampTranscodingStreamingFormat>(
        value: ref.watch(finampSettingsProvider.transcodingStreamingFormat),
        items: FinampTranscodingStreamingFormat.values
            .map(
              (e) => DropdownMenuItem<FinampTranscodingStreamingFormat>(
                value: e,
                child: Text("${e.codec}+${e.container}".toUpperCase()),
              ),
            )
            .toList(),
        onChanged: FinampSetters.setTranscodingStreamingFormat.ifNonNull,
      ),
    );
  }
}
