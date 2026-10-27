import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../providers/music_provider.dart';
import '../widgets/album_art.dart';
import '../widgets/mini_player.dart';
import '../widgets/track_tile.dart';
import 'now_playing_screen.dart';
import 'playlist_detail_screen.dart';

enum LibraryCategory { songs, albums, artists, folders }

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Perpustakaan', 'Playlist', 'Favorit'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_pageIndex]),
        actions: [
          if (_pageIndex == 0)
            IconButton(
              tooltip: 'Pindai ulang',
              onPressed: context.read<MusicProvider>().scanLibrary,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: IndexedStack(
        index: _pageIndex,
        children: const [LibraryScreen(), PlaylistsScreen(), FavoritesScreen()],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniPlayer(onOpen: _openNowPlaying),
            NavigationBar(
              selectedIndex: _pageIndex,
              onDestinationSelected: (index) =>
                  setState(() => _pageIndex = index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music_rounded),
                  label: 'Lagu',
                ),
                NavigationDestination(
                  icon: Icon(Icons.queue_music_rounded),
                  label: 'Playlist',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: 'Favorit',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNowPlaying() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const NowPlayingScreen()));
  }
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  LibraryCategory _category = LibraryCategory.songs;
  String? _selectedGroup;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<MusicProvider>(
    builder: (context, music, _) {
      final query = _searchController.text.trim().toLowerCase();
      final searchResults = music.tracks.where((track) {
        return track.title.toLowerCase().contains(query) ||
            track.artist.toLowerCase().contains(query);
      }).toList();
      final isSearching = query.isNotEmpty;
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _selectedGroup = null),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari judul atau artis',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFF1A211D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!isSearching)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: LibraryCategory.values.map((category) {
                  final label = switch (category) {
                    LibraryCategory.songs => 'Semua lagu',
                    LibraryCategory.albums => 'Album',
                    LibraryCategory.artists => 'Artis',
                    LibraryCategory.folders => 'Folder',
                  };
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _category == category,
                      onSelected: (_) => setState(() {
                        _category = category;
                        _selectedGroup = null;
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (music.errorMessage != null)
            _ErrorBanner(
              message: music.errorMessage!,
              actionLabel: music.hasPermission ? 'Coba lagi' : 'Pengaturan',
              onAction: music.hasPermission
                  ? music.scanLibrary
                  : () async {
                      if (!await music.openPermissionSettings() &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Pengaturan aplikasi tidak dapat dibuka.',
                            ),
                          ),
                        );
                      }
                    },
            ),
          Expanded(
            child: music.isScanning
                ? const Center(child: CircularProgressIndicator())
                : music.tracks.isEmpty
                ? _EmptyLibrary(onScan: music.scanLibrary)
                : isSearching
                ? searchResults.isEmpty
                      ? const _EmptyMessage(
                          icon: Icons.search_off_rounded,
                          title: 'Lagu tidak ditemukan',
                          subtitle:
                              'Coba kata kunci judul atau nama artis lain.',
                        )
                      : _TrackList(tracks: searchResults)
                : _buildCategoryContent(music),
          ),
        ],
      );
    },
  );

  Widget _buildCategoryContent(MusicProvider music) {
    if (_category == LibraryCategory.songs) {
      return _TrackList(tracks: music.tracks);
    }
    if (_selectedGroup != null) {
      final groupTracks = music.tracks.where((track) {
        return _groupName(track) == _selectedGroup;
      }).toList();
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedGroup = null),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(_selectedGroup!),
            ),
          ),
          Expanded(child: _TrackList(tracks: groupTracks)),
        ],
      );
    }
    final groups = <String, List<Track>>{};
    for (final track in music.tracks) {
      groups.putIfAbsent(_groupName(track), () => []).add(track);
    }
    final names = groups.keys.toList()
      ..sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );
    return ListView.builder(
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        final groupTracks = groups[name]!;
        return ListTile(
          leading: AlbumArt(track: groupTracks.first, size: 52),
          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${groupTracks.length} lagu'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => setState(() => _selectedGroup = name),
        );
      },
    );
  }

  String _groupName(Track track) => switch (_category) {
    LibraryCategory.albums => track.album,
    LibraryCategory.artists => track.artist,
    LibraryCategory.folders =>
      track.folder.isEmpty ? 'Folder utama' : track.folder,
    LibraryCategory.songs => '',
  };
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: tracks.length,
    itemBuilder: (context, index) => TrackTile(
      track: tracks[index],
      onTap: () {
        context.read<MusicProvider>().playTrack(tracks[index]);
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const NowPlayingScreen()),
        );
      },
    ),
  );
}

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<MusicProvider>(
    builder: (context, music, _) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCreatePlaylistDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Buat playlist'),
            ),
          ),
        ),
        if (music.errorMessage != null)
          _ErrorBanner(message: music.errorMessage!),
        Expanded(
          child: music.playlists.isEmpty
              ? const _EmptyMessage(
                  icon: Icons.queue_music_rounded,
                  title: 'Belum ada playlist',
                  subtitle:
                      'Buat playlist lalu tambahkan lagu dari menu tiap lagu.',
                )
              : ListView.builder(
                  itemCount: music.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = music.playlists[index];
                    final tracks = music.tracksForPlaylist(playlist);
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.queue_music_rounded),
                      ),
                      title: Text(playlist.name),
                      subtitle: Text('${tracks.length} lagu'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'delete') {
                            music.deletePlaylist(playlist.name);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus playlist'),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PlaylistDetailScreen(playlist: playlist),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playlist baru'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(hintText: 'Nama playlist'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Buat'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && context.mounted) {
      await context.read<MusicProvider>().createPlaylist(name);
    }
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) => Consumer<MusicProvider>(
    builder: (context, music, _) => music.favorites.isEmpty
        ? const _EmptyMessage(
            icon: Icons.favorite_border_rounded,
            title: 'Belum ada lagu favorit',
            subtitle:
                'Tandai lagu dengan ikon menu untuk menemukannya di sini.',
          )
        : _TrackList(tracks: music.favorites),
  );
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => _EmptyMessage(
    icon: Icons.music_off_rounded,
    title: 'Belum ada lagu di perangkat',
    subtitle:
        'Simpan file MP3, M4A, atau FLAC secara lokal, lalu pindai ulang.',
    action: FilledButton.icon(
      onPressed: onScan,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Pindai musik'),
    ),
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
        if (onAction != null && actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    ),
  );
}
