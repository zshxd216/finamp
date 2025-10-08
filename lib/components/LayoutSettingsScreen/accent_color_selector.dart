import 'package:finamp/l10n/app_localizations.dart';
import 'package:finamp/services/accent_color_helper.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

class AccentColorSelector extends StatefulWidget {
  const AccentColorSelector({super.key});

  @override
  State<AccentColorSelector> createState() => _AccentColorSelectorState();
}

class _AccentColorSelectorState extends State<AccentColorSelector> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Color?>>(
      valueListenable: AccentColorHelper.accentColorListener,
      builder: (context, box, _) {
        final color = box.get(AccentColorHelper.key);
        final isSet = color != null;
        return ListTile(
          title: Text(AppLocalizations.of(context)!.accentColor),
          trailing: Container(
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
          onTap: () => _showAccentColorSheet(context, color),
        );
      },
    );
  }

  void _showAccentColorSheet(BuildContext context, Color? currentColor) {
    final controller = TextEditingController(text: AccentColorHelper.toHex(currentColor));
    Color? previewColor = currentColor ?? Colors.transparent;

    final suggestedColors = [Colors.pink, Colors.teal, Colors.amber, Colors.cyan];

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
                final color = AccentColorHelper.fromHex(value);
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: suggestedColors.map((c) {
                      return GestureDetector(
                        onTap: () {
                          controller.text = AccentColorHelper.toHex(c)!;
                          updatePreview(controller.text);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        ),
                      );
                    }).toList(),
                  ),
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
                          AccentColorHelper.saveAccentColor(null);
                          Navigator.pop(context);
                        },
                        child: Text(AppLocalizations.of(context)!.reset),
                      ),
                      FilledButton(
                        onPressed: previewColor == null
                            ? null
                            : () {
                                final color = AccentColorHelper.fromHex(controller.text);
                                if (color != null) {
                                  AccentColorHelper.saveAccentColor(color);
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
