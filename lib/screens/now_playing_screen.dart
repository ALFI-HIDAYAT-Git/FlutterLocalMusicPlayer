import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';
import '../widgets/album_art.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<MusicProvider>(
    builder: (context, music, _) {
      final track = music.currentTrack;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sedang diputar'),
          actions: [
            if (track != null)
              IconButton(
                tooltip: music.favoriteIds.contains(track.id)
                    ? 'Hapus dari favorit'
                    : 'Tambah ke favorit',
                onPressed: () => music.toggleFavorite(track),
                icon: Icon(
                  music.favoriteIds.contains(track.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
              ),
          ],
        ),
        body: track == null
            ? const Center(child: Text('Pilih lagu untuk mulai memutar musik.'))
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: Column(
                    children: [
                      const Spacer(),
                      Center(
                        child: AlbumArt(
                          track: track,
                          size: MediaQuery.sizeOf(context).width - 72,
                          animate: true,
                          isPlaying: music.isPlaying,
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${track.artist} · ${track.album}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _PlaybackSlider(
                        position: music.position,
                        duration: music.duration,
                        onSeek: music.seek,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(music.position)),
                          Text(_formatDuration(music.duration)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: music.isShuffling
                                ? 'Matikan acak'
                                : 'Acak lagu',
                            color: music.isShuffling
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            onPressed: music.toggleShuffle,
                            icon: const Icon(Icons.shuffle_rounded),
                          ),
                          IconButton(
                            tooltip: 'Lagu sebelumnya',
                            onPressed: music.skipToPrevious,
                            icon: const Icon(Icons.skip_previous_rounded),
                            iconSize: 36,
                          ),
                          FilledButton(
                            onPressed: music.togglePlayback,
                            style: FilledButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(18),
                            ),
                            child: Icon(
                              music.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 36,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Lagu berikutnya',
                            onPressed: music.skipToNext,
                            icon: const Icon(Icons.skip_next_rounded),
                            iconSize: 36,
                          ),
                          IconButton(
                            tooltip: _repeatTooltip(music.repeatMode),
                            color: music.repeatMode == AudioServiceRepeatMode.none
                                ? null
                                : Theme.of(context).colorScheme.primary,
                            onPressed: music.cycleRepeatMode,
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.repeat_rounded),
                                if (music.repeatMode == AudioServiceRepeatMode.one)
                                  Positioned(
                                    right: -5,
                                    top: -5,
                                    child: Text(
                                      '1',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      );
    },
  );

  String _repeatTooltip(AudioServiceRepeatMode mode) => switch (mode) {
    AudioServiceRepeatMode.one => 'Ulangi satu lagu',
    AudioServiceRepeatMode.all => 'Ulangi semua lagu',
    _ => 'Ulangi nonaktif',
  };

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PlaybackSlider extends StatelessWidget {
  const _PlaybackSlider({
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  @override
  Widget build(BuildContext context) {
    final maximum = duration.inMilliseconds;
    final current = position.inMilliseconds.clamp(0, maximum > 0 ? maximum : 1);
    return Slider(
      value: current.toDouble(),
      max: maximum > 0 ? maximum.toDouble() : 1,
      onChanged: maximum <= 0
          ? null
          : (value) => onSeek(Duration(milliseconds: value.round())),
    );
  }
}
