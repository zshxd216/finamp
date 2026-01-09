import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/music_player_background_task.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

enum IconPosition { start, end }

class SimpleButton extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final IconData icon;
  final IconPosition? iconPosition;
  final double iconSize;
  final Color? iconColor;
  final Color? textColor;
  final FontWeight? fontWeight;
  final void Function() onPressed;
  final void Function()? onPressedSecondary;
  final bool disabled;

  /// fades the button out, while keeping it enabled
  /// used for representing state while also allowing interaction that can yield more information about the state (e.g. lyrics button)
  final bool inactive;

  const SimpleButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.onPressedSecondary,
    this.textColor,
    this.fontWeight,
    this.iconPosition = IconPosition.start,
    this.iconSize = 20.0,
    this.iconColor,
    this.disabled = false,
    this.inactive = false,
  }) : textStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.normal);

  const SimpleButton.small({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.onPressedSecondary,
    this.textColor,
    this.fontWeight,
    this.iconPosition = IconPosition.start,
    this.iconSize = 16.0,
    this.iconColor,
    this.disabled = false,
    this.inactive = false,
  }) : textStyle = const TextStyle(fontSize: 12, fontWeight: FontWeight.normal);

  @override
  Widget build(BuildContext context) {
    final contents = [
      Icon(icon, size: iconSize, color: (disabled || inactive) ? iconColor?.withOpacity(0.5) : iconColor, weight: 1.5),
      Text(
        text,
        style: TextStyle(
          color: (disabled || inactive)
              ? Theme.of(context).disabledColor
              : (textColor != null)
              ? textColor
              : Theme.of(context).textTheme.bodyMedium!.color!,
          fontSize: textStyle.fontSize,
          fontWeight: (fontWeight != null) ? fontWeight : textStyle.fontWeight,
        ),
        textAlign: TextAlign.center,
      ),
    ];

    return Tooltip(
      message: disabled ? "$text (Disabled)" : text,
      child: GestureDetector(
        onLongPress: () {
          if (onPressedSecondary != null) {
            FeedbackHelper.feedback(FeedbackType.selection);
            onPressedSecondary!();
          }
        },
        onSecondaryTap: () {
          if (onPressedSecondary != null) {
            FeedbackHelper.feedback(FeedbackType.selection);
            onPressedSecondary!();
          }
        },
        child: TextButton(
          onPressed: disabled ? null : onPressed,
          style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
            ),
            backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 6.0,
            children: iconPosition == IconPosition.start ? contents : contents.reversed.toList(),
          ),
        ),
      ),
    );
  }
}
