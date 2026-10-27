class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.durationMs,
    required this.albumId,
    required this.folder,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final int durationMs;
  final int albumId;
  final String folder;

  Duration get duration => Duration(milliseconds: durationMs);
}

class MusicPlaylist {
  const MusicPlaylist({required this.name, required this.trackIds});

  final String name;
  final List<String> trackIds;

  Map<String, Object?> toJson() => {'name': name, 'trackIds': trackIds};

  factory MusicPlaylist.fromJson(Map<String, Object?> json) => MusicPlaylist(
    name: json['name']! as String,
    trackIds: (json['trackIds']! as List<Object?>).cast<String>(),
  );
}
