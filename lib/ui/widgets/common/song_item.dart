import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/song.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_utils.dart' as utils;

class SongItem extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool showArtist;
  final bool showAlbum;
  final Widget? trailing;

  const SongItem({
    super.key,
    required this.song,
    this.onTap,
    this.onMoreTap,
    this.showArtist = true,
    this.showAlbum = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Album Art
            if (song.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: song.coverUrl!.replaceFirst('http:', 'https:'),
                    fit: BoxFit.cover,
                    httpHeaders: AppConstants.imageHeaders,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note, size: 24),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note, size: 24),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.music_note, size: 24),
              ),

            const SizedBox(width: 12),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showArtist || showAlbum)
                    const SizedBox(height: 4),
                  if (showArtist)
                    Text(
                      song.artistNames,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Duration
            if (song.duration > 0)
              Text(
                utils.DateUtils.formatDurationMs(song.duration),
                style: Theme.of(context).textTheme.bodySmall,
              ),

            const SizedBox(width: 8),

            // More Button
            if (onMoreTap != null)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: onMoreTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              )
            else if (trailing != null)
              trailing!,
          ],
        ),
      ),
    );
  }
}

class SongItemLeading extends StatelessWidget {
  final int index;
  final bool isPlaying;

  const SongItemLeading({
    super.key,
    required this.index,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Center(
        child: isPlaying
            ? Icon(
                Icons.volume_up,
                color: Theme.of(context).primaryColor,
                size: 20,
              )
            : Text(
                '${index + 1}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
      ),
    );
  }
}

class SongItemWithIndex extends StatelessWidget {
  final Song song;
  final int index;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const SongItemWithIndex({
    super.key,
    required this.song,
    required this.index,
    this.isPlaying = false,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Index
            SongItemLeading(index: index, isPlaying: isPlaying),

            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.w500,
                          color: isPlaying ? Theme.of(context).primaryColor : null,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artistNames,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // More Button
            if (onMoreTap != null)
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: onMoreTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
