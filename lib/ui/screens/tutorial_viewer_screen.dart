import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/tutorial.dart';
import '../widgets/branded_scaffold.dart';

class TutorialViewerScreen extends StatefulWidget {
  final Tutorial tutorial;
  const TutorialViewerScreen({super.key, required this.tutorial});
  @override
  State<TutorialViewerScreen> createState() => _TutorialViewerScreenState();
}

class _TutorialViewerScreenState extends State<TutorialViewerScreen> {
  VideoPlayerController? _video;
  @override
  void initState() {
    super.initState();
    if (widget.tutorial.videoUrl != null && widget.tutorial.videoUrl!.isNotEmpty) {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.tutorial.videoUrl!))
        ..initialize().then((_) { if (mounted) setState(() {}); });
    }
  }
  @override
  void dispose() { _video?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final t = widget.tutorial;
    return BrandedScaffold(
      appBar: AppBar(title: Text(t.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_video != null && _video!.value.isInitialized) ...[
            AspectRatio(aspectRatio: _video!.value.aspectRatio, child: VideoPlayer(_video!)),
            Row(children: [
              IconButton(onPressed: () => setState(() { _video!.value.isPlaying ? _video!.pause() : _video!.play(); }), icon: Icon(_video!.value.isPlaying ? Icons.pause_circle : Icons.play_circle)),
              Text('${(_video!.value.position.inSeconds)}s / ${(_video!.value.duration.inSeconds)}s')
            ])
          ],
          if ((t.imageUrls).isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: PageView(
                children: t.imageUrls.map((u) {
                  final isAsset = !(u.startsWith('http://') || u.startsWith('https://'));
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isAsset ? Image.asset(u, fit: BoxFit.cover) : Image.network(u, fit: BoxFit.cover),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if ((t.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(t.description!),
          ],
        ],
      ),
    );
  }
}
