import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../controllers/theory_controller.dart';
import '../model/lesson_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  final TheoryController theoryController = Get.find<TheoryController>();
  bool _isLoading = true;
  late AnimationController _animController;
  bool _isCompleted = false;
  bool _isYoutube = false;

  @override
  void initState() {
    super.initState();

    // Animation cho nút hoàn thành
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    // Kiểm tra lesson đã hoàn thành chưa
    _isCompleted = theoryController.isCompleted(widget.lesson.title);

    // Khởi tạo video player
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final videoUrl = widget.lesson.videoUrl;

    if (videoUrl == null || videoUrl.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId != null) {
      // YouTube
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    } else {
      // Video bình thường
      try {
        _videoController = VideoPlayerController.network(videoUrl);
        await _videoController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController!.value.aspectRatio,
        );
      } catch (e) {
        debugPrint("Error loading video: $e");
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    _animController.dispose();
    super.dispose();
  }

  // Widget video player
  Widget _buildVideoPlayer() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_isYoutube && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
      );
    } else if (_chewieController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Chewie(controller: _chewieController!),
        ),
      );
    } else {
      return const Center(child: Text("Không thể phát video"));
    }
  }

  // Widget hiển thị content items (text, image)
  Widget _buildContentItem(ContentItem item) {
    switch (item.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            item.value,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        );
      case 'image':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(item.value, fit: BoxFit.cover),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Toggle hoàn thành lesson
  void _toggleCompletion() async {
    if (_isCompleted) return;

    await theoryController.toggleComplete(
      lessonTitle: widget.lesson.title,
      lessonId: widget.lesson.id,
      subjectId: widget.lesson.subjectId ?? 0, // ✅ tránh null
    );

    if (mounted) setState(() => _isCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: widget.lesson.title,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.lesson.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _buildVideoPlayer(),

            const SizedBox(height: 20),

            ...widget.lesson.contents.map(_buildContentItem).toList(),

            const SizedBox(height: 24),

            ScaleTransition(
              scale: _animController,
              child: ElevatedButton.icon(
                onPressed: _isCompleted ? null : _toggleCompletion,
                icon: Icon(
                  _isCompleted ? Icons.check_circle : Icons.done_all_outlined,
                ),
                label: Text(
                  _isCompleted ? "Đã hoàn thành" : "Đánh dấu hoàn thành",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCompleted ? Colors.green : primaryGreen,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
