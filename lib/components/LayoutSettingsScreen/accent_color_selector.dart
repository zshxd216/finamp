import 'package:finamp/color_schemes.g.dart';
import 'package:finamp/extensions/string.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/extensions/color_extensions.dart';
import 'package:finamp/services/widget_bindings_observer_provider.dart';
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
      trailing: GestureDetector(
        onTap: () => _showAccentColorSheet(context, ref, color),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              color?.toHex() ?? AppLocalizations.of(context)!.defaultWord,
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
      ),
    );
  }

  void _showAccentColorSheet(BuildContext context, WidgetRef ref, Color? previewColor) {
    final controller = TextEditingController(text: previewColor?.toHex());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                void updatePreview(String value) {
                  setState(() => previewColor = value.toColorOrNull());
                }

                void changeColor(Color color) => setState(() {
                  previewColor = color;
                  controller.text = color.toHex();
                });

                final previewTheme = Theme.of(
                  context,
                ).copyWith(colorScheme: getColorScheme(previewColor, ref.read(brightnessProvider)));

                return Theme(
                  data: previewTheme,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      color: previewTheme.colorScheme.surface,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: previewTheme.colorScheme.outline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Text(AppLocalizations.of(context)!.accentColor, style: previewTheme.textTheme.titleLarge),
                        SizedBox(height: 16),
                        Column(
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
                                          final color = controller.text.toColorOrNull();
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
