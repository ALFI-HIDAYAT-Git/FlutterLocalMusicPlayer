import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import 'album_art.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    required this.track,
    required this.onTap,
    this.removeFromPlaylist,
    super.key,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback? removeFromPlaylist;

  @override
  Widget build(BuildContext context) => Consumer<MusicProvider>(
    builder: (context, music, _) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      leading: AlbumArt(track: track, size: 52),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${track.artist} · ${track.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        tooltip: 'Aksi lagu',
        onSelected: (action) {
          if (action == 'favorite') {
            music.toggleFavorite(track);
          } else if (action == 'remove') {
            removeFromPlaylist?.call();
          } else if (action.startsWith('playlist:')) {
            music.addTrackToPlaylist(action.substring(9), track);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'favorite',
            child: Text(
              music.favoriteIds.contains(track.id)
                  ? 'Hapus dari favorit'
                  : 'Tambah ke favorit',
            ),
          ),
          if (removeFromPlaylist != null)
            const PopupMenuItem(
              value: 'remove',
              child: Text('Hapus dari playlist'),
            ),
          if (music.playlists.isNotEmpty) const PopupMenuDivider(),
          ...music.playlists.map(
            (playlist) => PopupMenuItem(
              value: 'playlist:${playlist.name}',
              child: Text('Tambah ke ${playlist.name}'),
            ),
          ),
          if (music.playlists.isEmpty)
            const PopupMenuItem(
              enabled: false,
              value: 'no-playlist',
              child: Text('Buat playlist untuk menyimpan lagu'),
            ),
        ],
        child: Icon(
          music.favoriteIds.contains(track.id)
              ? Icons.favorite_rounded
              : Icons.more_vert_rounded,
          color: music.favoriteIds.contains(track.id)
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
    ),
  );
}
