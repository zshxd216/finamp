import 'dart:io';

import 'package:collection/collection.dart';
import 'package:finamp/components/Buttons/cta_medium.dart';
import 'package:finamp/components/Buttons/simple_button.dart';
import 'package:finamp/components/HomeScreen/home_screen_content.dart';
import 'package:finamp/components/MusicScreen/sort_and_filter_row.dart';
import 'package:finamp/components/SettingsScreen/finamp_settings_dropdown.dart';
import 'package:finamp/components/themed_bottom_sheet.dart';
import 'package:finamp/menus/choice_menu.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/feedback_helper.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/item_by_id_provider.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:flutter/material.dart';
import 'package:finamp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:get_it/get_it.dart';

class HomeScreenSettingsScreen extends StatefulWidget {
  const HomeScreenSettingsScreen({super.key});
  static const routeName = "/settings/home-screen";
  @override
  State<HomeScreenSettingsScreen> createState() => _HomeScreenSettingsScreenState();
}

class _HomeScreenSettingsScreenState extends State<HomeScreenSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homeScreenSettingsTitle),
        actions: [
          FinampSettingsHelper.makeSettingsResetButtonWithDialog(context, FinampSettingsHelper.resetHomeScreenSettings),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 200.0),
        children: [const QuickActionsSelector(), const HomeScreenSectionsSelector()],
      ),
    );
  }
}

class QuickActionsSelector extends ConsumerStatefulWidget {
  const QuickActionsSelector({super.key});

  @override
  ConsumerState<QuickActionsSelector> createState() => _QuickActionsSelectorState();
}

class _QuickActionsSelectorState extends ConsumerState<QuickActionsSelector> {
  bool isAddingAction = false;

  @override
  Widget build(BuildContext context) {
    final quickActions = ref.watch(finampSettingsProvider.homeScreenConfiguration).actions;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text("Quick Actions*"),
            subtitle: Text("Select and reorder the quick actions displayed on the home screen.*"),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final action = quickActions[index];
              return Padding(
                key: ValueKey(action),
                padding: const EdgeInsets.only(bottom: 8.0, left: 12.0, right: 12.0),
                child: ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  title: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(action.toLocalisedString(context)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  contentPadding: EdgeInsets.only(left: 6.0),
                  leading: ReorderableDragStartListener(
                    index: index,
                    key: ValueKey("handle-quick-action-$action"),
                    child: const Icon(Icons.drag_handle),
                  ),
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SimpleButton.small(text: "Edit Action*", icon: TablerIcons.edit, onPressed: () {}),
                      SimpleButton.small(
                        text: "Remove Action*",
                        icon: TablerIcons.trash,
                        onPressed: () {
                          final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration
                              .copyWith(
                                actions: [...quickActions.sublist(0, index), ...quickActions.sublist(index + 1)],
                              );
                          FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: quickActions.length,
            onReorder: (originalIndex, newIndex) {
              setState(() {
                if (originalIndex < newIndex) newIndex -= 1;
                final action = quickActions[originalIndex];
                final newActions = [...quickActions];
                newActions.removeAt(originalIndex);
                newActions.insert(newIndex, action);
                final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration.copyWith(
                  actions: newActions,
                );
                FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
              });
            },
          ),
          if (isAddingAction)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: FinampSettingsDropdown<FinampQuickAction>(
                dropdownItems: FinampQuickAction.values
                    .where((action) => !quickActions.contains(action))
                    .map((e) => DropdownMenuEntry<FinampQuickAction>(value: e, label: e.toLocalisedString(context)))
                    .toList(),
                selectedValue: FinampQuickAction.values.firstWhere(
                  (action) => !quickActions.contains(action),
                  orElse: () => FinampQuickAction.trackMix,
                ),
                onSelected: (selectedAction) {
                  if (selectedAction != null) {
                    setState(() {
                      isAddingAction = false;
                    });
                    final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration.copyWith(
                      actions: [...quickActions, selectedAction],
                    );
                    FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
                  }
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 16.0, right: 16.0),
            child: CTAMedium(
              text: "Add New Action*",
              icon: TablerIcons.plus,
              onPressed: () {
                setState(() {
                  isAddingAction = true;
                });
              },
              disabled: quickActions.length >= FinampQuickAction.values.length,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreenSectionsSelector extends ConsumerWidget {
  const HomeScreenSectionsSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(finampSettingsProvider.homeScreenConfiguration).sections;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text("Sections*"),
            subtitle: Text("Select and reorder the sections displayed on the home screen.*"),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final section = sections[index];
              return Padding(
                key: ValueKey("section-$section-$index"),
                padding: const EdgeInsets.only(bottom: 8.0, left: 12.0, right: 12.0),
                child: ListTile(
                  tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  title: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: section.itemId != null
                        ? FutureBuilder(
                            future: ref.watch(itemByIdProvider(section.itemId!).future).then((item) => item?.name),
                            builder: (context, asyncSnapshot) {
                              if (asyncSnapshot.data == null) {
                                return Text(section.getTitle(context));
                              }
                              final itemName = asyncSnapshot.data!;
                              return Text("${section.getTitle(context)} '$itemName'*");
                            },
                          )
                        : Text(section.getTitle(context)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                  contentPadding: EdgeInsets.only(left: 6.0),
                  leading: ReorderableDragStartListener(
                    index: index,
                    key: ValueKey("section_$section"),
                    child: const Icon(Icons.drag_handle),
                  ),
                  subtitle: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SimpleButton.small(
                        text: "Edit Section*",
                        icon: TablerIcons.edit,
                        onPressed: () => showHomeScreenSectionConfigurationMenu(context, editingSectionIndex: index),
                      ),
                      SimpleButton.small(
                        text: "Remove Section*",
                        icon: TablerIcons.trash,
                        onPressed: () {
                          FeedbackHelper.feedback(FeedbackType.warning);
                          final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration
                              .copyWith(sections: [...sections.sublist(0, index), ...sections.sublist(index + 1)]);
                          FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: sections.length,
            onReorder: (originalIndex, newIndex) {
              if (originalIndex < newIndex) newIndex -= 1;
              final section = sections[originalIndex];
              final newSections = [...sections];
              newSections.removeAt(originalIndex);
              newSections.insert(newIndex, section);
              final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration.copyWith(
                sections: newSections,
              );
              FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 16.0, right: 16.0),
            child: CTAMedium(
              text: "Add New Section*",
              icon: TablerIcons.plus,
              onPressed: () async {
                final selectedPreset = await showSectionPresetPickerMenu(context);
                if (selectedPreset != null) {
                  final newSectionInfo = HomeScreenSectionConfiguration.fromPreset(selectedPreset);
                  final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration.copyWith(
                    sections: [...sections, newSectionInfo],
                  );
                  FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
                } else if (context.mounted) {
                  showHomeScreenSectionConfigurationMenu(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

void showHomeScreenSectionConfigurationMenu(BuildContext context, {int? editingSectionIndex}) async {
  await showThemedBottomSheet<void>(
    context: context,
    routeName: HomeScreenSectionConfigurationMenu.routeName,
    minDraggableHeight: 0.85,
    buildWrapper: (context, dragController, childBuilder) {
      return HomeScreenSectionConfigurationMenu(
        editingSectionIndex: editingSectionIndex,
        childBuilder: childBuilder,
        dragController: dragController,
      );
    },
  );
}

const Duration homeScreenSectionConfigurationMenuDefaultAnimationDuration = Duration(milliseconds: 500);
const Curve homeScreenSectionConfigurationMenuDefaultInCurve = Curves.easeOutCubic;
const Curve homeScreenSectionConfigurationMenuDefaultOutCurve = Curves.easeInCubic;

class HomeScreenSectionConfigurationMenu extends ConsumerStatefulWidget {
  static const routeName = "/home-screen-section-menu";

  const HomeScreenSectionConfigurationMenu({
    super.key,
    required this.childBuilder,
    required this.dragController,
    this.editingSectionIndex,
  });

  final ScrollBuilder childBuilder;
  final DraggableScrollableController dragController;
  final int? editingSectionIndex;

  @override
  ConsumerState<HomeScreenSectionConfigurationMenu> createState() => _HomeScreenSectionConfigurationMenuState();
}

class _HomeScreenSectionConfigurationMenuState extends ConsumerState<HomeScreenSectionConfigurationMenu>
    with TickerProviderStateMixin {
  double initialSheetExtent = 0.0;
  double inputStep = 0.9;
  double oldExtent = 0.0;

  HomeScreenSectionType? selectedSectionType;
  BaseItemId? selectedCollectionId;
  TabContentType? selectedContentType;
  SortBy? selectedSortBy;
  SortOrder? selectedSortOrder;
  Set<ItemFilter>? selectedFilters;

  List<BaseItemDto> collections = [];

  final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();

  @override
  void initState() {
    super.initState();

    initialSheetExtent = 0.85;
    oldExtent = initialSheetExtent;

    _jellyfinApiHelper
        .getItems(includeItemTypes: [BaseItemDtoType.collection.jellyfinName].join(","), recursive: true)
        .then((result) {
          if (!mounted) return;
          setState(() {
            collections = result ?? [];
          });
        });
  }

  void scrollToExtent(DraggableScrollableController scrollController, double? percentage) {
    var currentSize = scrollController.size;
    if ((percentage != null && currentSize < percentage) || scrollController.size == inputStep) {
      if (MediaQuery.disableAnimationsOf(context)) {
        scrollController.jumpTo(percentage ?? oldExtent);
      } else {
        scrollController.animateTo(
          percentage ?? oldExtent,
          duration: homeScreenSectionConfigurationMenuDefaultAnimationDuration,
          curve: homeScreenSectionConfigurationMenuDefaultInCurve,
        );
      }
    }
    oldExtent = currentSize;
  }

  HomeScreenSectionConfiguration _getCurrentSectionInfo() {
    final sections = ref.watch(finampSettingsProvider.homeScreenConfiguration).sections;
    return HomeScreenSectionConfiguration(
      type:
          selectedSectionType ??
          (widget.editingSectionIndex != null
              ? sections[widget.editingSectionIndex!].type
              : HomeScreenSectionType.tabView),
      itemId: selectedCollectionId,
      contentType:
          selectedContentType ??
          (widget.editingSectionIndex != null
              ? sections[widget.editingSectionIndex!].contentType ?? TabContentType.tracks
              : TabContentType.tracks),
      sortAndFilterConfiguration: SortAndFilterConfiguration(
        sortBy:
            selectedSortBy ??
            (widget.editingSectionIndex != null
                ? ref
                      .watch(finampSettingsProvider.homeScreenConfiguration)
                      .sections[widget.editingSectionIndex!]
                      .sortAndFilterConfiguration
                      .sortBy
                : SortBy.sortName),
        sortOrder:
            selectedSortOrder ??
            (widget.editingSectionIndex != null
                ? ref
                      .watch(finampSettingsProvider.homeScreenConfiguration)
                      .sections[widget.editingSectionIndex!]
                      .sortAndFilterConfiguration
                      .sortOrder
                : SortOrder.ascending),
        filters:
            selectedFilters ??
            (widget.editingSectionIndex != null
                ? ref
                      .watch(finampSettingsProvider.homeScreenConfiguration)
                      .sections[widget.editingSectionIndex!]
                      .sortAndFilterConfiguration
                      .filters
                      .toSet()
                : <ItemFilter>{}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuEntries = _getMenuEntries(context);
    final stackHeight = 40.0;

    return widget.childBuilder(stackHeight, menu(context, menuEntries));
  }

  // Normal track menu entries, excluding headers
  List<Widget> _getMenuEntries(BuildContext context) {
    final sections = ref.watch(finampSettingsProvider.homeScreenConfiguration).sections;
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.max,
        spacing: 4.0,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text("Preview*", style: Theme.of(context).textTheme.bodyMedium),
          ),
          HomeScreenSectionContent(sectionInfo: _getCurrentSectionInfo()),
        ],
      ),
      SizedBox(height: 40.0),
      //TODO add custom section title
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4.0,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text("Section Type*", style: Theme.of(context).textTheme.bodyMedium),
          ),
          FinampSettingsDropdown<HomeScreenSectionType>(
            dropdownItems: HomeScreenSectionType.values
                .map((e) => DropdownMenuEntry<HomeScreenSectionType>(value: e, label: e.toLocalisedString(context)))
                .toList(),
            selectedValue:
                selectedSectionType ??
                (widget.editingSectionIndex != null
                    ? sections[widget.editingSectionIndex!].type
                    : HomeScreenSectionType.tabView),
            onSelected: (selectedActionType) {
              if (selectedActionType != null) {
                setState(() {
                  selectedSectionType = selectedActionType;
                });
              }
            },
          ),
        ],
      ),
      if (selectedSectionType == HomeScreenSectionType.collection) ...[
        SizedBox(height: 24.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4.0,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text("Featured Collection*", style: Theme.of(context).textTheme.bodyMedium),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<BaseItemId>(
                  width: constraints.maxWidth,
                  menuHeight:
                      MediaQuery.sizeOf(context).height *
                      (widget.dragController.isAttached ? widget.dragController.size : initialSheetExtent) *
                      0.25,
                  dropdownMenuEntries: collections
                      .map(
                        (collection) => DropdownMenuEntry<BaseItemId>(
                          value: collection.id,
                          label: collection.name ?? "Unnamed Collection*",
                          enabled: true,
                          style: ButtonStyle(
                            padding: WidgetStateProperty.all<EdgeInsets>(
                              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  initialSelection:
                      selectedCollectionId ??
                      (widget.editingSectionIndex != null
                          ? collections[widget.editingSectionIndex!].id
                          : collections.firstOrNull?.id),
                  enableFilter: true,
                  enableSearch: true,
                  requestFocusOnTap: true,
                  onSelected: (selectedCollection) {
                    if (selectedCollection != null) {
                      setState(() {
                        selectedCollectionId = selectedCollection;
                      });
                    }
                  },
                  textStyle: Theme.of(context).textTheme.bodyMedium,
                  trailingIcon: const Icon(TablerIcons.chevron_down),
                  selectedTrailingIcon: const Icon(TablerIcons.chevron_up),
                  menuStyle: MenuStyle(
                    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    backgroundColor: WidgetStateProperty.all<Color>(
                      Color.alphaBlend(
                        ColorScheme.of(context).onSurface.withOpacity(0.2),
                        ColorScheme.of(context).surface,
                      ),
                    ),
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Color.alphaBlend(
                      ColorScheme.of(context).primary.withOpacity(0.075),
                      ColorScheme.of(context).onSurface.withOpacity(0.1),
                    ),
                    visualDensity: VisualDensity(horizontal: -4.0, vertical: -4.0),
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(left: 8.0),
                  ),
                );
              },
            ),
          ],
        ),
      ],
      if (selectedSectionType == HomeScreenSectionType.tabView) ...[
        SizedBox(height: 24.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4.0,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text("Tab Type*", style: Theme.of(context).textTheme.bodyMedium),
            ),
            FinampSettingsDropdown<TabContentType>(
              dropdownItems: TabContentType.values
                  .whereNot((contentType) => contentType == TabContentType.home)
                  .map((e) => DropdownMenuEntry<TabContentType>(value: e, label: e.toLocalisedString(context)))
                  .toList(),
              selectedValue:
                  selectedContentType ??
                  (widget.editingSectionIndex != null
                      ? sections[widget.editingSectionIndex!].contentType ?? TabContentType.tracks
                      : TabContentType.tracks),
              onSelected: (selectedTabType) {
                if (selectedTabType != null) {
                  setState(() {
                    selectedContentType = selectedTabType;
                  });
                }
              },
            ),
          ],
        ),
      ],
      SizedBox(height: 24.0),
      // sort and filter configuration
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4.0,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text("Sort By*", style: Theme.of(context).textTheme.bodyMedium),
          ),
          SortAndFilterRow(
            tabType: _getCurrentSectionInfo().contentType ?? TabContentType.tracks,
            sortByOverride: _getCurrentSectionInfo().sortAndFilterConfiguration.sortBy,
            sortOrderOverride: _getCurrentSectionInfo().sortAndFilterConfiguration.sortOrder,
            filterOverride: _getCurrentSectionInfo().sortAndFilterConfiguration.filters.toSet(),
            updateSortByOverride: (selectedSortByValue) {
              setState(() {
                selectedSortBy = selectedSortByValue;
              });
            },
            updateSortOrderOverride: (selectedSortOrderValue) {
              setState(() {
                selectedSortOrder = selectedSortOrderValue;
              });
            },
            updateFilterOverride: (newFilters) {
              setState(() {
                selectedFilters = newFilters;
              });
            },
            refreshTab: (_) {},
          ),
        ],
      ),
      SizedBox(height: 24.0),
      CTAMedium(
        text: "Save*",
        icon: TablerIcons.device_floppy,
        onPressed: () {
          //TODO remove preset type when editing section, pre-fill name?
          final newSectionInfo = _getCurrentSectionInfo();
          if (widget.editingSectionIndex != null) {
            final newSections = [...sections];
            newSections[widget.editingSectionIndex!] = newSectionInfo;
            final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration.copyWith(
              sections: newSections,
            );
            FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
          } else {
            final newHomeScreenConfig = FinampSettingsHelper.finampSettings.homeScreenConfiguration.copyWith(
              sections: [...sections, newSectionInfo],
            );
            FinampSetters.setHomeScreenConfiguration(newHomeScreenConfig);
          }
          Navigator.of(context).pop();
        },
      ),
    ];
  }

  // All track menu slivers, including headers
  List<Widget> menu(BuildContext context, List<Widget> menuEntries) {
    return [
      SliverStickyHeader(
        header: Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 8.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2.0,
            children: [Text("Edit Home Screen Section*", style: Theme.of(context).textTheme.titleMedium)],
          ),
        ),
        sliver: MenuMask(
          height: MenuMaskHeight(32.0),
          child: SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList.list(children: _getMenuEntries(context)),
          ),
        ),
      ),
    ];
  }
}

const sectionPresetPickerMenuRouteName = "/section-preset-picker-menu";

Future<HomeScreenSectionPresetType?> showSectionPresetPickerMenu(
  BuildContext context, {
  int? editingSectionIndex,
}) async {
  final List<Widget> menuItems = HomeScreenSectionPresetType.values
      .map<Widget>((presetType) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSections = ref.watch(finampSettingsProvider.homeScreenConfiguration).sections;
            return ChoiceMenuOption(
              title: HomeScreenSectionConfiguration.getTitleForPreset(context: context, presetType: presetType),
              description: HomeScreenSectionConfiguration.getDescriptionForPreset(
                context: context,
                presetType: presetType,
              ),
              badges: [
                // // similar mode is recommended
                // if (preset == RadioMode.similar && radioModeOptionAvailabilityStatus.isAvailable)
                //   Icon(TablerIcons.star, size: 14.0),
              ],
              enabled: true,
              icon: TablerIcons.settings_star,
              isInactive: false,
              isSelected: editingSectionIndex != null && currentSections[editingSectionIndex].presetType == presetType,
              onSelect: () async {
                //TODO ideally rebuild with check and then pop after delay
                // FeedbackHelper.feedback(FeedbackType.selection);
                // await Future<void>.delayed(const Duration(milliseconds: 400));
                // Navigator.of(context).pop(preset);
                if (context.mounted) {
                  FeedbackHelper.feedback(FeedbackType.selection);
                  Navigator.of(context).pop(presetType);
                }
              },
            );
          },
        );
      })
      .followedBy(<Widget>[
        Divider(height: 8.0, thickness: 1.5, indent: 20.0, endIndent: 20.0, radius: BorderRadius.circular(2.0)),
        Consumer(
          builder: (context, ref, child) {
            final currentSections = ref.watch(finampSettingsProvider.homeScreenConfiguration).sections;
            return ChoiceMenuOption(
              title: AppLocalizations.of(context)!.homeScreenSectionCustomSectionTitle,
              description: AppLocalizations.of(context)!.homeScreenSectionCustomSectionDescription,
              icon: TablerIcons.radio_off,
              isSelected: editingSectionIndex != null && currentSections[editingSectionIndex].presetType == null,
              enabled: true,
              onSelect: () async {
                //TODO ideally rebuild with check and then pop after delay
                // FeedbackHelper.feedback(FeedbackType.selection);
                // await Future<void>.delayed(const Duration(milliseconds: 400));
                // if (context.mounted) {
                //   Navigator.of(context).pop();
                // }
                if (context.mounted) {
                  FeedbackHelper.feedback(FeedbackType.selection);
                  Navigator.of(context).pop(null);
                }
              },
            );
          },
        ),
      ])
      .toList();

  return await showThemedBottomSheet<HomeScreenSectionPresetType?>(
    context: context,
    routeName: sectionPresetPickerMenuRouteName,
    minDraggableHeight: 0.25,
    buildSlivers: (context) {
      var menu = [
        SliverStickyHeader(
          header: Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 8.0, left: 16.0, right: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2.0,
              children: [
                Text(
                  AppLocalizations.of(context)!.homeScreenSectionPresetPickerMenuTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          sliver: MenuMask(
            height: MenuMaskHeight(36.0),
            child: SliverList.list(children: menuItems),
          ),
        ),
      ];
      // header + menu entries
      var stackHeight = 42.0 + menuItems.length * ((Platform.isAndroid || Platform.isIOS) ? 72.0 : 64.0);
      return (stackHeight, menu);
    },
  );
}
