import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import '../../../core/model/story_model.dart';
import '../../../core/services/auth/auth_manager.dart';

class StoryViewer extends StatefulWidget {
  final UserStories userStories;
  final int initialStoryIndex;

  const StoryViewer({
    super.key,
    required this.userStories,
    this.initialStoryIndex = 0,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late int _currentStoryIndex;
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  Timer? _progressTimer;
  double _progress = 0.0;
  late AnimationController _animationController;
  final AuthManager _authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    _currentStoryIndex = widget.initialStoryIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadStory();
  }

  Future<void> _loadStory() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _progress = 0.0;
    });

    _progressTimer?.cancel();
    
    // Properly dispose of the old controller
    if (_videoController != null) {
      await _videoController!.pause();
      await _videoController!.dispose();
      _videoController = null;
    }

    final story = widget.userStories.stories[_currentStoryIndex];

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(story.videoUrl),
      );
      
      _videoController = controller;

      await controller.initialize();
      
      if (!mounted || _videoController != controller) {
        // Widget was disposed or controller changed during initialization
        await controller.dispose();
        return;
      }
      
      setState(() {
        _isLoading = false;
      });

      await controller.play();
      _startProgressTimer();

      // Use a local reference to avoid issues with controller changes
      void videoListener() {
        if (!mounted || _videoController != controller) return;
        
        if (controller.value.hasError) {
          setState(() {
            _hasError = true;
          });
        }
        
        if (controller.value.position >= controller.value.duration) {
          _nextStory();
        }
      }

      controller.addListener(videoListener);
    } catch (e) {
      print('❌ Error loading story: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _startProgressTimer() {
    final duration = _videoController?.value.duration ?? const Duration(seconds: 60);
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || _videoController == null) {
        timer.cancel();
        return;
      }

      final position = _videoController!.value.position;
      setState(() {
        _progress = position.inMilliseconds / duration.inMilliseconds;
      });
    });
  }

  void _nextStory() {
    if (_currentStoryIndex < widget.userStories.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
      _loadStory();
    } else {
      _closeViewer();
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
      _loadStory();
    }
  }

  void _closeViewer() {
    Navigator.of(context).pop();
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _progressTimer?.cancel();
        } else {
          _videoController!.play();
          _startProgressTimer();
        }
      });
    }
  }

  String? _getUserPhotoUrl() {
    // First try to get from current user's identity
    final identity = _authManager.currentIdentity;
    final userPhoto = identity?.employee?.individual?.photoUrl;
    
    // Return only if it's not null and not empty
    if (userPhoto != null && userPhoto.isNotEmpty) {
      return userPhoto;
    }
    
    // Fallback to story's userPhoto if available and not empty
    if (widget.userStories.userPhoto != null && 
        widget.userStories.userPhoto!.isNotEmpty) {
      return widget.userStories.userPhoto;
    }
    
    return null;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    if (_videoController != null) {
      _videoController!.pause();
      _videoController!.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousStory();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextStory();
          } else {
            _togglePlayPause();
          }
        },
        child: Stack(
          children: [
            if (_videoController != null && _videoController!.value.isInitialized && !_hasError)
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),

            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),

            if (_hasError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48.sp,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load video',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: _loadStory,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(
                            widget.userStories.stories.length,
                            (index) => Expanded(
                              child: Container(
                                height: 2.h,
                                margin: EdgeInsets.symmetric(horizontal: 2.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(1.r),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: index == _currentStoryIndex
                                      ? _progress
                                      : index < _currentStoryIndex
                                          ? 1.0
                                          : 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(1.r),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18.r,
                              backgroundImage: _getUserPhotoUrl() != null
                                  ? NetworkImage(_getUserPhotoUrl()!)
                                  : null,
                              child: _getUserPhotoUrl() == null
                                  ? Icon(Icons.person, size: 20.sp)
                                  : null,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                'Sieves Mobile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _closeViewer,
                              icon: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_videoController != null && !_videoController!.value.isPlaying && !_isLoading)
              Center(
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white.withOpacity(0.8),
                  size: 80.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
