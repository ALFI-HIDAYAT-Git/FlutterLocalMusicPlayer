import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../models/track.dart';

class AlbumArt extends StatefulWidget {
  const AlbumArt({
    required this.track,
    this.size = 56,
    this.animate = false,
    this.isPlaying = false,
    super.key,
  });

  final Track track;
  final double size;
  final bool animate;
  final bool isPlaying;

  @override
  State<AlbumArt> createState() => _AlbumArtState();
}

class _AlbumArtState extends State<AlbumArt>
    with SingleTickerProviderStateMixin {
  AnimationController? _rotationController;

  @override
  void initState() {
    super.initState();
    _syncRotation();
  }

  @override
  void didUpdateWidget(covariant AlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.isPlaying != widget.isPlaying) {
      _syncRotation();
    }
  }

  void _syncRotation() {
    if (!widget.animate) {
      _rotationController?.dispose();
      _rotationController = null;
      return;
    }
    _rotationController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.isPlaying) {
      _rotationController!.repeat();
    } else {
      _rotationController!.stop();
    }
  }

  @override
  void dispose() {
    _rotationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(widget.size * .12),
      child: QueryArtworkWidget(
        id: widget.track.albumId,
        type: ArtworkType.ALBUM,
        artworkWidth: widget.size,
        artworkHeight: widget.size,
        artworkFit: BoxFit.cover,
        nullArtworkWidget: _placeholder(context),
      ),
    );
    if (!widget.animate) return image;
    return RotationTransition(
      turns: _rotationController!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * .5),
        child: image,
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    width: widget.size,
    height: widget.size,
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      Icons.graphic_eq_rounded,
      size: widget.size * .4,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}
