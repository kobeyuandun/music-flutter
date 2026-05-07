import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/playlist.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/player_utils.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final double? width;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? (Get.width / 3) - 16;

    return InkWell(
      onTap: () {
        Get.toNamed('/playlist', parameters: {'id': playlist.id});
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image
                  playlist.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: playlist.coverUrl!.replaceFirst('http:', 'https:'),
                          fit: BoxFit.cover,
                          httpHeaders: AppConstants.imageHeaders,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.playlist_play,
                                size: 40, color: Colors.grey),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.playlist_play,
                                size: 40, color: Colors.grey),
                          ),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.playlist_play,
                              size: 40, color: Colors.grey),
                        ),

                  // Play Count Badge
                  if (playlist.playCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              PlayerUtils.formatPlayCount(playlist.playCount),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Title
          Text(
            playlist.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Creator
          Text(
            playlist.creatorName ?? '未知',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
