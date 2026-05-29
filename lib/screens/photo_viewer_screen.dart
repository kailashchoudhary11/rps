import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../models/photo_item.dart';
import '../services/download_service.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;
  final String eventName;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.eventName,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  bool _isDownloading = false;
  /// 0.0..1.0 when total bytes are known; null when the server didn't
  /// send Content-Length (rare for R2). Null means "show indeterminate".
  double? _downloadProgress;
  String? _errorMessage;
  Timer? _errorClearTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _errorClearTimer?.cancel();
    super.dispose();
  }

  Future<void> _downloadCurrentPhoto() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = null;
      _errorMessage = null;
    });
    _errorClearTimer?.cancel();

    final photo = widget.photos[_currentIndex];

    try {
      await DownloadService.downloadImage(
        photo.downloadUrl,
        photo.name,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _downloadProgress = total > 0 ? received / total : null;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadProgress = null;
      });
      // Silent success — the photo appearing in Gallery is the confirmation.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _downloadProgress = null;
        _errorMessage = 'Download failed';
      });
      _errorClearTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _errorMessage = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            onPressed: _isDownloading ? null : _downloadCurrentPhoto,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Download Photo',
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            pageController: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            builder: (context, index) {
              final photo = widget.photos[index];
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(photo.url),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: 'photo_${photo.eventCode}/${photo.name}',
                ),
              );
            },
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),

          // Bottom photo-info overlay (name + timestamp). Always present.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isDownloading) _buildDownloadProgress(),
                    if (_errorMessage != null) _buildErrorPill(),
                    if (_isDownloading || _errorMessage != null)
                      const SizedBox(height: 12),
                    Text(
                      widget.photos[_currentIndex].name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.photos[_currentIndex].uploadedAt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(widget.photos[_currentIndex].uploadedAt!),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    final percent = _downloadProgress != null
        ? '${(_downloadProgress! * 100).round()}%'
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Downloading${percent.isEmpty ? '…' : ' $percent'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _downloadProgress,
            minHeight: 3,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorPill() {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade300, size: 16),
        const SizedBox(width: 6),
        Text(
          _errorMessage!,
          style: TextStyle(
            color: Colors.red.shade300,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
