import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../models/jellyfin_models.dart';
import '../../services/finamp_settings_helper.dart';
import '../../services/generate_subtitle.dart';
import '../album_image.dart';

const double _itemCollectionCardCoverSize = 120;
const double _itemCollectionCardSpacing = 6;

/// Card content for ItemCollection. You probably shouldn't use this widget directly,
/// use CollectionItem instead.
class ItemCollectionCard extends ConsumerWidget {
  const ItemCollectionCard({super.key, required this.item, this.parentType, this.onTap});

  final BaseItemDto item;
  final String? parentType;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(maxWidth: _itemCollectionCardCoverSize),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: AlbumImage.defaultBorderRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1, // Square aspect ratio for album art
            child: Card(
              margin: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: AlbumImage.defaultBorderRadius,
                child: Stack(
                  children: [
                    AlbumImage(item: item),
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(onTap: onTap),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (ref.watch(finampSettingsProvider.showTextOnGridView)) ...[
            const SizedBox(height: _itemCollectionCardSpacing, width: 1),
            _ItemCollectionCardText(item: item, parentType: parentType),
          ],
        ],
      ),
    );
  }
}

class _ItemCollectionCardText extends ConsumerWidget {
  const _ItemCollectionCardText({required this.item, required this.parentType});

  final BaseItemDto item;
  final String? parentType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = generateSubtitle(
      context: context,
      item: item,
      parentType: parentType,
      artistType: ref.watch(finampSettingsProvider.defaultArtistType),
    );

    return SizedBox(
      height: calculateTextHeight(style: TextTheme.of(context).bodySmall!, lines: 4),
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          // Runs must be horizontal to constrain child width.  Use large
          // spacing to force subtitle to wrap to next run
          spacing: 1000,
          children: [
            Text(
              item.name ?? "Unknown Name",
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// This might calculate the width base on the device width in the future, or something similar
double calculateItemCollectionCardWidth(BuildContext context) {
  return _itemCollectionCardCoverSize;
}

double calculateItemCollectionCardHeight(BuildContext context) {
  return _itemCollectionCardCoverSize +
      (GetIt.instance<ProviderContainer>().read(finampSettingsProvider.showTextOnGridView)
          ? _itemCollectionCardSpacing
          : 0) +
      calculateTextHeight(style: TextTheme.of(context).bodySmall!, lines: 4);
}

double calculateTextHeight({required TextStyle style, required int lines}) {
  return (GetIt.instance<ProviderContainer>().read(finampSettingsProvider.showTextOnGridView)
      ? (style.height ?? 1.0) * (style.fontSize ?? 16) * lines
      : 0);
}
