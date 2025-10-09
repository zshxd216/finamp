import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/color_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccentColorSelector extends ConsumerWidget {
  const AccentColorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ref.watch(finampSettingsProvider.accentColor);
    final isSet = color != null;
    return ListTile(
      title: Text(AppLocalizations.of(context)!.accentColor),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            ColorExtensions.toHex(color) ?? AppLocalizations.of(context)!.defaultWord,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          SizedBox(width: 16),
          Container(
            width: 56,
            height: 32,
            margin: EdgeInsets.fromLTRB(0, 0, 2, 0),
            decoration: BoxDecoration(
              color: color ?? Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSet ? Colors.transparent : Theme.of(context).colorScheme.outline, width: 2),
            ),
            child: !isSet
                ? Icon(Icons.color_lens_outlined, size: 24, color: Theme.of(context).colorScheme.outline)
                : null,
          ),
        ],
      ),
      onTap: () => _showAccentColorSheet(context, ref, color),
    );
  }

  void _showAccentColorSheet(BuildContext context, WidgetRef ref, Color? currentColor) {
    final controller = TextEditingController(text: ColorExtensions.toHex(currentColor));
    Color? previewColor = currentColor ?? Colors.transparent;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: StatefulBuilder(
            builder: (context, setState) {
              void updatePreview(String value) {
                final color = ColorExtensions.fromHex(value);
                setState(() => previewColor = color);
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(AppLocalizations.of(context)!.accentColor, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.hexColorCode,
                      prefixText: "#",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: updatePreview,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: previewColor ?? Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: previewColor == null ? Text(AppLocalizations.of(context)!.invalidColorCode) : null,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          FinampSetters.setAccentColor(null);
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.reset),
                      ),
                      FilledButton(
                        onPressed: previewColor == null
                            ? null
                            : () {
                                final color = ColorExtensions.fromHex(controller.text);
                                if (color != null) {
                                  FinampSetters.setAccentColor(color);
                                  Navigator.pop(context);
                                }
                              },
                        child: Text(AppLocalizations.of(context)!.save),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
