import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import '../services/audio_player_handler.dart';

class MusicProvider extends ChangeNotifier {
  MusicProvider(this.audioHandler);

  static const _favoritesKey = 'favorite_track_ids';
  static const _playlistsKey = 'custom_playlists';

  final AudioPlayerHandler audioHandler;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  List<Track> _tracks = [];
  List<MusicPlaylist> _playlists = [];
  final Set<String> _favoriteIds = {};
  Track? _currentTrack;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isScanning = false;
  bool _hasPermission = false;
  bool _isShuffling = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  String? _errorMessage;
  SharedPreferences? _preferences;

  List<Track> get tracks => List.unmodifiable(_tracks);
  List<MusicPlaylist> get playlists => List.unmodifiable(_playlists);
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Track> get favorites =>
      _tracks.where((track) => _favoriteIds.contains(track.id)).toList();
  Track? get currentTrack => _currentTrack;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isScanning => _isScanning;
  bool get hasPermission => _hasPermission;
  bool get isShuffling => _isShuffling;
  AudioServiceRepeatMode get repeatMode => _repeatMode;
  String? get errorMessage => _errorMessage;
  bool get hasScanned => _preferences != null;

  Future<void> initialize() async {
    try {
      _preferences = await SharedPreferences.getInstance();
      final savedFavorites =
          _preferences!.getStringList(_favoritesKey) ?? const <String>[];
      _favoriteIds.addAll(savedFavorites);
      final encodedPlaylists = _preferences!.getString(_playlistsKey);
      if (encodedPlaylists != null) {
        final decoded = jsonDecode(encodedPlaylists);
        if (decoded is! List) {
          throw const FormatException('Data playlist tidak valid.');
        }
        _playlists = decoded
            .map(
              (item) => MusicPlaylist.fromJson(
                Map<String, Object?>.from(item as Map),
              ),
            )
            .toList();
      }
      await scanLibrary();
      _listenToPlayer();
    } on FormatException catch (error) {
      _errorMessage = 'Data playlist lokal tidak dapat dibaca: $error';
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Gagal memuat data aplikasi: $error';
      notifyListeners();
    }
  }

  Future<void> scanLibrary() async {
    if (_isScanning) return;
    _isScanning = true;
    _hasPermission = false;
    _errorMessage = null;
    notifyListeners();
    try {
      if (!Platform.isAndroid) {
        throw UnsupportedError(
          'Pemindaian media saat ini hanya tersedia di Android.',
        );
      }
      var audioStatus = await Permission.audio.status;
      if (!audioStatus.isGranted) {
        audioStatus = await Permission.audio.request();
      }
      var storageStatus = audioStatus.isGranted
          ? audioStatus
          : await Permission.storage.status;
      if (!storageStatus.isGranted && !audioStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      _hasPermission = audioStatus.isGranted || storageStatus.isGranted;
      if (!_hasPermission) {
        _tracks = [];
        final permissionPermanentlyDenied =
            audioStatus.isPermanentlyDenied ||
            audioStatus.isRestricted ||
            storageStatus.isPermanentlyDenied ||
            storageStatus.isRestricted;
        _errorMessage = permissionPermanentlyDenied
            ? 'Izin audio ditolak permanen. Aktifkan izin Musik dan audio melalui Pengaturan.'
            : 'Izin Musik dan audio diperlukan untuk memindai lagu.';
        return;
      }

      final results = await _audioQuery.querySongs();
      final found =
          results
              .where((song) {
                final extension = path.extension(song.data).toLowerCase();
                return const {'.mp3', '.m4a', '.flac'}.contains(extension);
              })
              .map(
                (song) => Track(
                  id: song.id.toString(),
                  title: song.title.trim().isEmpty ? 'Tanpa judul' : song.title,
                  artist: song.artist?.trim().isNotEmpty == true
                      ? song.artist!
                      : 'Artis tidak diketahui',
                  album: song.album?.trim().isNotEmpty == true
                      ? song.album!
                      : 'Album tidak diketahui',
                  path: song.data,
                  durationMs: song.duration ?? 0,
                  albumId: song.albumId ?? 0,
                  folder: path.basename(path.dirname(song.data)),
                ),
              )
              .toList()
            ..sort(
              (first, second) => first.title.toLowerCase().compareTo(
                second.title.toLowerCase(),
              ),
            );
      _tracks = found;
    } catch (error) {
      _errorMessage = 'Pemindaian musik gagal: $error';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<bool> openPermissionSettings() => openAppSettings();

  Future<void> playTrack(Track track, {List<Track>? queue}) async {
    final tracksToPlay = queue ?? _tracks;
    final index = tracksToPlay.indexWhere((item) => item.id == track.id);
    if (index < 0) {
      _errorMessage = 'Lagu ini tidak tersedia di antrean pemutaran.';
      notifyListeners();
      return;
    }
    await _playTracks(tracksToPlay, index);
  }

  Future<void> _playTracks(List<Track> tracks, int index) async {
    try {
      await audioHandler.playTracks(tracks, index);
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Lagu tidak dapat diputar: $error';
    }
    notifyListeners();
  }

  Future<void> togglePlayback() async {
    try {
      if (_isPlaying) {
        await audioHandler.pause();
      } else {
        await audioHandler.play();
      }
    } catch (error) {
      _errorMessage = 'Kontrol pemutaran gagal: $error';
      notifyListeners();
    }
  }

  Future<void> skipToNext() => audioHandler.skipToNext();
  Future<void> skipToPrevious() => audioHandler.skipToPrevious();
  Future<void> seek(Duration value) => audioHandler.seek(value);

  Future<void> toggleShuffle() async {
    await audioHandler.toggleShuffle();
  }

  Future<void> cycleRepeatMode() async {
    await audioHandler.cycleRepeatMode();
  }

  Future<void> toggleFavorite(Track track) async {
    if (!_favoriteIds.add(track.id)) _favoriteIds.remove(track.id);
    await _persistCollections();
    notifyListeners();
  }

  Future<void> createPlaylist(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) return;
    if (_playlists.any(
      (playlist) => playlist.name.toLowerCase() == name.toLowerCase(),
    )) {
      _errorMessage = 'Nama playlist tersebut sudah digunakan.';
      notifyListeners();
      return;
    }
    _playlists = [..._playlists, MusicPlaylist(name: name, trackIds: const [])];
    await _persistCollections();
    notifyListeners();
  }

  Future<void> deletePlaylist(String name) async {
    _playlists = _playlists.where((playlist) => playlist.name != name).toList();
    await _persistCollections();
    notifyListeners();
  }

  Future<void> addTrackToPlaylist(String name, Track track) async {
    _updatePlaylist(name, (ids) {
      if (!ids.contains(track.id)) ids.add(track.id);
    });
    await _persistCollections();
    notifyListeners();
  }

  Future<void> removeTrackFromPlaylist(String name, Track track) async {
    _updatePlaylist(name, (ids) => ids.remove(track.id));
    await _persistCollections();
    notifyListeners();
  }

  List<Track> tracksForPlaylist(MusicPlaylist playlist) {
    final byId = {for (final track in _tracks) track.id: track};
    return playlist.trackIds.map((id) => byId[id]).whereType<Track>().toList();
  }

  void _updatePlaylist(String name, void Function(List<String>) update) {
    _playlists = _playlists.map((playlist) {
      if (playlist.name != name) return playlist;
      final ids = [...playlist.trackIds];
      update(ids);
      return MusicPlaylist(name: playlist.name, trackIds: ids);
    }).toList();
  }

  Future<void> _persistCollections() async {
    try {
      final preferences = _preferences;
      if (preferences == null) {
        throw StateError('Penyimpanan lokal belum siap.');
      }
      await preferences.setStringList(_favoritesKey, _favoriteIds.toList());
      await preferences.setString(
        _playlistsKey,
        jsonEncode(_playlists.map((playlist) => playlist.toJson()).toList()),
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = 'Gagal menyimpan playlist dan favorit: $error';
    }
  }

  void _listenToPlayer() {
    _subscriptions.add(
      audioHandler.mediaItem.listen((item) {
        final id = item?.id;
        _currentTrack = null;
        for (final track in _tracks) {
          if (track.path == id) {
            _currentTrack = track;
            break;
          }
        }
        notifyListeners();
      }),
    );
    _subscriptions.add(
      audioHandler.playbackState.listen(
        (state) {
          _isPlaying = state.playing;
          _isShuffling = state.shuffleMode == AudioServiceShuffleMode.all;
          _repeatMode = state.repeatMode;
          notifyListeners();
        },
        onError: (Object error) {
          _errorMessage = 'Terjadi kesalahan pada pemutar: $error';
          notifyListeners();
        },
      ),
    );
    _subscriptions.add(
      audioHandler.positionStream.listen((value) {
        _position = value;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      audioHandler.durationStream.listen((value) {
        _duration = value ?? Duration.zero;
        notifyListeners();
      }),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
