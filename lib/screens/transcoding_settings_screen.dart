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

enum FinampTranscodingStreamingFormats { low, medium, high, veryHigh, noTranscode }

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

String _formatStreamingQualityLabel(FinampTranscodingStreamingFormats value) {
  switch (value) {
    case FinampTranscodingStreamingFormats.low:
      return "Low";
    case FinampTranscodingStreamingFormats.medium:
      return "Medium";
    case FinampTranscodingStreamingFormats.high:
      return "High";
    case FinampTranscodingStreamingFormats.veryHigh:
      return "Very high";
    case FinampTranscodingStreamingFormats.noTranscode:
      return "Original";
  }
}

String _formatStreamingQualitySubtitle(FinampTranscodingStreamingFormats value) {
  switch (value) {
    case FinampTranscodingStreamingFormats.low:
      return "Good for small data plans";
    case FinampTranscodingStreamingFormats.medium:
      return "Balanced quality and data usage";
    case FinampTranscodingStreamingFormats.high:
      return "High quality audio";
    case FinampTranscodingStreamingFormats.veryHigh:
      return "Best quality — use on Wi-Fi";
    case FinampTranscodingStreamingFormats.noTranscode:
      return "Play original file without transcoding";
  }
}

int _kbpsForStreamingFormat(FinampTranscodingStreamingFormats value) {
  switch (value) {
    case FinampTranscodingStreamingFormats.low:
      return 64;
    case FinampTranscodingStreamingFormats.medium:
      return 128;
    case FinampTranscodingStreamingFormats.high:
      return 196;
    case FinampTranscodingStreamingFormats.veryHigh:
      return 256;
    case FinampTranscodingStreamingFormats.noTranscode:
      return 0;
  }
}

String _formatKbpsAndGbPerHour(FinampTranscodingStreamingFormats value) {
  final kbps = _kbpsForStreamingFormat(value);
  if (value == FinampTranscodingStreamingFormats.noTranscode) {
    return '???kbps · ???GB/h';
  }
  // bytes per hour = kbps * 1000 (bits/s) * 3600 (s) / 8 (bits/byte) = kbps * 450000
  final gbPerHour = kbps * 450000 / 1e9;
  return '${kbps}kbps · ${gbPerHour.toStringAsFixed(2)}GB/h';
}

class _TranscodingSettingsScreenState extends ConsumerState<TranscodingSettingsScreen> {
  FinampTranscodingStreamingFormats transcodeProfile = FinampTranscodingStreamingFormats.high;

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
            ],
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
    final label = _formatStreamingQualityLabel(transcodeProfile);
  final cardTitle = "Download quality";
  final cardSubtitle = "Choose audio quality for downloads (offline listening).";
        final stats = _formatKbpsAndGbPerHour(transcodeProfile);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox.shrink(),
                ListTile(
                  title: Text(
                    cardTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
              subtitle: Text(
                cardSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.secondary,
              child: ListTile(
                title: Text(
                  '$label   $stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
                ),
                subtitle: Text(
                  _formatStreamingQualitySubtitle(transcodeProfile),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
                ),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
                  isScrollControlled: true,
                  builder: (ctx) => StreamingQualityModal(
                    selected: transcodeProfile,
                    onSelected: (v) {
                      ref.read(downloadQualityProvider.notifier).state = v;
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleCelluarStreamingTranscodingFormatDropdownListTile extends ConsumerWidget {
  const SimpleCelluarStreamingTranscodingFormatDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcodeProfile = ref.watch(celluarStreamingQualityProvider);
    final label = _formatStreamingQualityLabel(transcodeProfile);
  final cardTitle = "Cellular streaming quality";
  final cardSubtitle = "Choose audio quality for streaming on mobile networks.";
  final stats = _formatKbpsAndGbPerHour(transcodeProfile);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                cardTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              subtitle: Text(
                cardSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            Card(
              color: Theme.of(context).colorScheme.secondary,
              child: ListTile(
                title: Text(
                  '$label   $stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
                ),
                subtitle: Text(
                  _formatStreamingQualitySubtitle(transcodeProfile),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
                ),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
                  isScrollControlled: true,
                  builder: (ctx) => StreamingQualityModal(
                    selected: transcodeProfile,
                    onSelected: (v) {
                      ref.read(celluarStreamingQualityProvider.notifier).state = v;
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleWiFiStreamingTranscodingFormatDropdownListTile extends ConsumerWidget {
  const SimpleWiFiStreamingTranscodingFormatDropdownListTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transcodeProfile = ref.watch(wifiStreamingQualityProvider);
    final label = _formatStreamingQualityLabel(transcodeProfile);
  final cardTitle = "Wi‑Fi streaming quality";
  final cardSubtitle = "Choose audio quality for streaming on Wi‑Fi.";
    final stats = _formatKbpsAndGbPerHour(transcodeProfile);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                cardTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              subtitle: Text(
                cardSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.secondary,
              child: ListTile(
                title: Text(
                  '$label   $stats',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
                ),
                subtitle: Text(
                  _formatStreamingQualitySubtitle(transcodeProfile),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSecondary),
                ),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
                  isScrollControlled: true,
                  builder: (ctx) => StreamingQualityModal(
                    selected: transcodeProfile,
                    onSelected: (v) {
                      ref.read(wifiStreamingQualityProvider.notifier).state = v;
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable modal widget that lists streaming quality options.
class StreamingQualityModal extends StatelessWidget {
  final FinampTranscodingStreamingFormats selected;
  final void Function(FinampTranscodingStreamingFormats) onSelected;
  final ScrollController? scrollController;

  const StreamingQualityModal({super.key, required this.selected, required this.onSelected, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodySmall!.color!;
    return SafeArea(
      child: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Material(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: textColor, borderRadius: BorderRadius.circular(4.0)),
                  ),
                ),
                // title
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Center(
                    child: Text(
                      'Select quality profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const Divider(height: 1),
                // options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    children: FinampTranscodingStreamingFormats.values.map((v) {
                      final label = _formatStreamingQualityLabel(v);
                      final stats = _formatKbpsAndGbPerHour(v);
                      final subtitle = _formatStreamingQualitySubtitle(v);
                      final isSelected = v == selected;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Card(
                          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceVariant,
                          child: InkWell(
                            onTap: () => onSelected(v),
                            child: ListTile(
                              title: Text(
                                '$label   $stats',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimaryContainer 
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              subtitle: Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isSelected 
                                    ? Theme.of(context).colorScheme.onPrimaryContainer 
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
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
