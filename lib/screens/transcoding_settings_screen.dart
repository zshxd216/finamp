import 'dart:io';

import 'package:flutter/material.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/TranscodingSettingsScreen/bitrate_selector.dart';
import '../components/TranscodingSettingsScreen/transcode_switch.dart';
import '../models/finamp_models.dart';
import '../services/finamp_settings_helper.dart';
import '../components/menu_shower_toggleable_list_tile.dart';

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
            Consumer(
              builder: (context, ref, _) {
                final selected = ref.watch(wifiStreamingQualityProvider);
                return SimpleDropdownList<FinampTranscodingStreamingFormats>(
                  title: "Wi‑Fi streaming quality",
                  subtitle: "Choose audio quality for streaming on Wi‑Fi.",
                  options: FinampTranscodingStreamingFormats.values
                      .map(
                        (v) => SimpleDropdownOption(
                          title: _formatStreamingQualityLabel(v) + '   ' + _formatKbpsAndGbPerHour(v),
                          subtitle: _formatStreamingQualitySubtitle(v),
                          value: v,
                        ),
                      )
                      .toList(),
                  selectedValue: selected,
                  onChanged: (v) => ref.read(wifiStreamingQualityProvider.notifier).state = v,
                );
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final selected = ref.watch(celluarStreamingQualityProvider);
                return SimpleDropdownList<FinampTranscodingStreamingFormats>(
                  title: "Cellular streaming quality",
                  subtitle: "Choose audio quality for streaming on mobile networks.",
                  options: FinampTranscodingStreamingFormats.values
                      .map(
                        (v) => SimpleDropdownOption(
                          title: _formatStreamingQualityLabel(v) + '   ' + _formatKbpsAndGbPerHour(v),
                          subtitle: _formatStreamingQualitySubtitle(v),
                          value: v,
                        ),
                      )
                      .toList(),
                  selectedValue: selected,
                  onChanged: (v) => ref.read(celluarStreamingQualityProvider.notifier).state = v,
                );
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final selected = ref.watch(downloadQualityProvider);
                return SimpleDropdownList<FinampTranscodingStreamingFormats>(
                  title: "Download quality",
                  subtitle: "Choose audio quality for downloads (offline listening).",
                  options: FinampTranscodingStreamingFormats.values
                      .map(
                        (v) => SimpleDropdownOption(
                          title: _formatStreamingQualityLabel(v) + '   ' + _formatKbpsAndGbPerHour(v),
                          subtitle: _formatStreamingQualitySubtitle(v),
                          value: v,
                        ),
                      )
                      .toList(),
                  selectedValue: selected,
                  onChanged: (v) => ref.read(downloadQualityProvider.notifier).state = v,
                );
              },
            ),
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

/// Option model for SimpleDropdownList
class SimpleDropdownOption<T> {
  final String title;
  final String subtitle;
  final T value;
  const SimpleDropdownOption({required this.title, required this.subtitle, required this.value});
}

/// Reusable dropdown list component
class SimpleDropdownList<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SimpleDropdownOption<T>> options;
  final T selectedValue;
  final void Function(T) onChanged;
  final Color? cardColor;
  final Color? optionCardColor;

  const SimpleDropdownList({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.cardColor,
    this.optionCardColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseTextColor = Theme.of(context).colorScheme.onPrimaryContainer;
    final optionColor = optionCardColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: cardColor ?? Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: baseTextColor)),
              subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: baseTextColor)),
            ),
            Card(
              color: optionColor,
              child: MenuShowerToggleableListTile(
                title: options.firstWhere((o) => o.value == selectedValue).title,
                subtitle: options.firstWhere((o) => o.value == selectedValue).subtitle,
                menuTitle: 'Select option',
                state: true,
                isLoading: false,
                enabled: true,
                titleStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                subtitleStyle: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                menuCreator: () async {
                  await showChoiceMenu(
                    context: context,
                    title: 'Select option',
                    listEntries: options.map((opt) {
                      return ChoiceListTile(
                        title: opt.title,
                        description: opt.subtitle,
                        icon: Icons.music_note,
                        isSelected: opt.value == selectedValue,
                        disabled: false,
                        onSelect: () {
                          onChanged(opt.value);
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                    subtitle: null,
                  );
                },
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
    final baseTextColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(cardTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: baseTextColor)),
              subtitle: Text(
                cardSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: baseTextColor),
              ),
            ),
            Card(
              color: Theme.of(context).colorScheme.primary,
              child: MenuShowerToggleableListTile(
                title: '$label   $stats',
                subtitle: _formatStreamingQualitySubtitle(transcodeProfile),
                menuTitle: 'Select quality profile',
                state: true,
                isLoading: false,
                enabled: true,
                menuCreator: () async {
                  await showChoiceMenu(
                    context: context,
                    title: 'Select quality profile',
                    listEntries: FinampTranscodingStreamingFormats.values.map((v) {
                      return ChoiceListTile(
                        title: _formatStreamingQualityLabel(v),
                        description: _formatStreamingQualitySubtitle(v),
                        icon: Icons.music_note,
                        isSelected: v == transcodeProfile,
                        disabled: false,
                        onSelect: () {
                          ref.read(celluarStreamingQualityProvider.notifier).state = v;
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                    subtitle: null,
                  );
                },
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
    final baseTextColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(cardTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: baseTextColor)),
              subtitle: Text(
                cardSubtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: baseTextColor),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.primary,
              child: MenuShowerToggleableListTile(
                title: '$label   $stats',
                subtitle: _formatStreamingQualitySubtitle(transcodeProfile),
                menuTitle: 'Select quality profile',
                state: true,
                isLoading: false,
                enabled: true,
                menuCreator: () async {
                  await showChoiceMenu(
                    context: context,
                    title: 'Select quality profile',
                    listEntries: FinampTranscodingStreamingFormats.values.map((v) {
                      return ChoiceListTile(
                        title: _formatStreamingQualityLabel(v),
                        description: _formatStreamingQualitySubtitle(v),
                        icon: Icons.music_note,
                        isSelected: v == transcodeProfile,
                        disabled: false,
                        onSelect: () {
                          ref.read(wifiStreamingQualityProvider.notifier).state = v;
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                    subtitle: null,
                  );
                },
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
    final baseTextColor = Theme.of(context).colorScheme.onPrimaryContainer;
    final nestedTextColor = Theme.of(context).colorScheme.onPrimary;
    final textColor = Theme.of(context).colorScheme.onSurface;
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
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.primary,
                          child: InkWell(
                            onTap: () => onSelected(v),
                            child: ListTile(
                              title: Text(
                                '$label   $stats',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(color: isSelected ? baseTextColor : nestedTextColor),
                              ),
                              subtitle: Text(
                                subtitle,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: isSelected ? baseTextColor : nestedTextColor),
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
