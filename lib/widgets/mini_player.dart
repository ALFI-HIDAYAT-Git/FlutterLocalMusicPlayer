import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';
import 'album_art.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Consumer<MusicProvider>(
    builder: (context, music, _) {
      final track = music.currentTrack;
      if (track == null) return const SizedBox.shrink();
      final totalMs = music.duration.inMilliseconds;
      final currentMs = music.position.inMilliseconds.clamp(
        0,
        totalMs > 0 ? totalMs : 1,
      );
      return Material(
        color: const Color(0xFF202A24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: totalMs > 0 ? currentMs / totalMs : 0,
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
            ListTile(
              onTap: onOpen,
              contentPadding: const EdgeInsets.only(left: 12, right: 4),
              leading: AlbumArt(track: track, size: 42),
              title: Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: music.isPlaying ? 'Jeda' : 'Putar',
                    onPressed: music.togglePlayback,
                    icon: Icon(
                      music.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Lagu berikutnya',
                    onPressed: music.skipToNext,
                    icon: const Icon(Icons.skip_next_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
