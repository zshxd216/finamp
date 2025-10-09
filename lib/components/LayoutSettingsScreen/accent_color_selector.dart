import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/extensions/color_extensions.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
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
          GestureDetector(
            onTap: () => _showAccentColorSheet(context, ref, color),
            child: Container(
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
          ),
        ],
      ),
    );
  }

  void _showAccentColorSheet(BuildContext context, WidgetRef ref, Color? currentColor) {
    final controller = TextEditingController(text: ColorExtensions.toHex(currentColor));
    Color? previewColor = currentColor;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
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
              StatefulBuilder(
                builder: (context, setState) {
                  void updatePreview(String value) {
                    setState(() => previewColor = ColorExtensions.fromHex(value));
                  }

                  void changeColor(Color color) => setState(() {
                    previewColor = color;
                    controller.text = ColorExtensions.toHex(color)!;
                  });

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(top: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              filled: true,
                              labelText: AppLocalizations.of(context)!.colorCode,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                            ),
                            onChanged: updatePreview,
                          ),
                          ColorPicker(
                            onColorChanged: changeColor,
                            color: previewColor ?? Theme.of(context).colorScheme.primary,
                            pickersEnabled: {
                              ColorPickerType.wheel: true,
                              ColorPickerType.primary: false,
                              ColorPickerType.accent: false,
                            },
                          ),
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
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
