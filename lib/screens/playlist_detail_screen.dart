import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../widgets/track_tile.dart';
import 'now_playing_screen.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({required this.playlist, super.key});

  final MusicPlaylist playlist;

  @override
  Widget build(BuildContext context) => Consumer<MusicProvider>(
    builder: (context, music, _) {
      final currentPlaylist = music.playlists.firstWhere(
        (item) => item.name == playlist.name,
        orElse: () => playlist,
      );
      final tracks = music.tracksForPlaylist(currentPlaylist);
      return Scaffold(
        appBar: AppBar(title: Text(playlist.name)),
        body: tracks.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Playlist ini masih kosong. Tambahkan lagu dari menu pada daftar lagu.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: FilledButton.icon(
                      onPressed: () {
                        music.playTrack(tracks.first, queue: tracks);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NowPlayingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Putar semua'),
                    ),
                  ),
                  for (final track in tracks)
                    TrackTile(
                      track: track,
                      onTap: () {
                        music.playTrack(track, queue: tracks);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NowPlayingScreen(),
                          ),
                        );
                      },
                      removeFromPlaylist: () =>
                          music.removeTrackFromPlaylist(playlist.name, track),
                    ),
                ],
              ),
      );
    },
  );
}
