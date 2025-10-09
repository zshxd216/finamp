import 'package:finamp/services/feedback_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IconButtonWithSemantics extends ConsumerWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? color;
  final String label;
  final VisualDensity? visualDensity;

  const IconButtonWithSemantics({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
    this.color,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: label,
      excludeSemantics: true, // replace child semantics with custom semantics
      container: true,
      child: IconTheme(
        data: IconThemeData(color: color ?? IconTheme.of(context).color, size: 24),
        child: IconButton(
          tooltip: label,
          icon: Icon(icon),
          visualDensity: visualDensity ?? VisualDensity.compact,
          onPressed: () {
            var callback = onPressed;
            if (callback != null) {
              callback();
              FeedbackHelper.feedback(FeedbackType.selection);
            }
          },
        ),
      ),
    );
  }
}
