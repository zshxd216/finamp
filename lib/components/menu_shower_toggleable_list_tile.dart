import 'package:finamp/components/themed_bottom_sheet.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

class MenuShowerToggleableListTile extends ConsumerWidget {
  const MenuShowerToggleableListTile({
    super.key,
    required this.title,
    required this.menuCreator,
    required this.menuTitle,
    this.subtitle,
    this.leading,
    this.icon,
    required this.state,
    this.trailing,
    this.isLoading = false,
    this.enabled = true,
    this.confirmationFeedback = true,
    this.titleStyle,
    this.subtitleStyle,
  });
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  final String title;
  final String? subtitle;
  final String menuTitle;
  final Widget? leading;
  final IconData? icon;
  final Widget? trailing;
  final bool state;
  final bool isLoading;
  final bool enabled;
  final bool confirmationFeedback;
  final Future<void> Function() menuCreator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
      child: Container(
        decoration: ShapeDecoration(
          color: themeColor.withOpacity(state ? 0.3 : 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.only(bottom: 6.0),
        child: ListTile(
          enableFeedback: true,
          enabled: enabled,
          leading: leading,
          title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
          subtitle: subtitle != null
              ? Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: subtitleStyle)
              : null,
          trailing: (icon != null || trailing != null)
              ? Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      height: 48.0,
                      width: 16.0,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: VerticalDivider(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                          thickness: 1.5,
                          indent: 8.0,
                          endIndent: 8.0,
                          width: 1.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 12.0),
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : trailing ?? Icon(icon, size: 36.0, color: themeColor),
                    ),
                  ],
                )
              : null,
          onTap: isLoading
              ? null
              : () async {
                  FeedbackHelper.feedback(FeedbackType.selection);
                  await menuCreator();
                },
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 0,
          visualDensity: const VisualDensity(horizontal: -4.0, vertical: -4.0),
        ),
      ),
    );
  }
}

const choiceMenuRouteName = "/choice-menu";

Future<void> showChoiceMenu({
  required BuildContext context,
  required String title,
  required List<ChoiceListTile> listEntries,
  String? subtitle,
  bool usePlayerTheme = true,
}) async {
  final queueService = GetIt.instance<QueueService>();

  FeedbackHelper.feedback(FeedbackType.selection);

  await showThemedBottomSheet(
    context: context,
    item: null,
    routeName: choiceMenuRouteName,
    minDraggableHeight: 0.2,
    buildSlivers: (context) {
      var menu = [
        SliverStickyHeader(
          header: Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 8.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.0,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null) Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          sliver: MenuMask(
            height: MenuMaskHeight(36.0),
            child: ChoiceMenuChoiceList(listEntries: listEntries),
          ),
        ),
      ];
      var stackHeight = MediaQuery.heightOf(context) * 0.15 + listEntries.length * 60.0;
      return (stackHeight, menu);
    },
  );
}

class ChoiceMenuChoiceList extends StatelessWidget {
  const ChoiceMenuChoiceList({super.key, required this.listEntries});

  final List<ChoiceListTile> listEntries;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final choice = listEntries[index];
        return choice;
      }, childCount: listEntries.length),
    );
  }
}

class ChoiceListTile extends StatelessWidget {
  const ChoiceListTile({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.disabled,
    this.description,
    this.onSelect,
  });

  final String title;
  final String? description;
  final IconData icon;
  final bool isSelected;
  final void Function()? onSelect;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(right: 2.0),
        child: Icon(icon, size: 32.0, color: ColorScheme.of(context).primary),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.clip),
      subtitle: description != null
          ? Text(
              description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      trailing: isSelected
          ? Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Icon(TablerIcons.check, size: 32.0, color: ColorScheme.of(context).primary),
            )
          : null,
      onTap: () async {
        onSelect?.call();
      },
      enabled: true,
    );
  }
}
