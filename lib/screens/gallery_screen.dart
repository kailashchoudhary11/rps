import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import '../models/event_model.dart';
import '../models/photo_item.dart';
import '../services/ads_service.dart';
import '../services/api_service.dart';
import 'photo_viewer_screen.dart';

class GalleryScreen extends StatefulWidget {
  final EventModel event;

  const GalleryScreen({super.key, required this.event});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<PhotoItem> _allPhotos = [];
  List<PhotoItem> _filteredPhotos = [];
  bool _isLoading = true;
  String? _errorMessage;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    // Defer the AdMob load until after the first frame paints — keeps the
    // initial gallery render off the main-thread path that the Ads SDK
    // takes during its native-view inflation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadBannerAd();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    final ad = BannerAd(
      adUnitId: AdsService.bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerAdReady = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          // Leave _isBannerAdReady false — the bottomNavigationBar simply
          // won't render, so the gallery looks the same as before ads
          // were added when the network is offline or no fill is available.
        },
      ),
    );
    ad.load();
    _bannerAd = ad;
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final photos = await _apiService.getEventPhotos(widget.event.eventCode);
      if (!mounted) return;
      setState(() {
        _allPhotos = photos;
        _filteredPhotos = photos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredPhotos = _apiService.searchPhotos(_allPhotos, query);
    });
  }

  Widget? _buildBannerSlot() {
    final ad = _bannerAd;
    if (!_isBannerAdReady || ad == null) return null;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: ad.size.height.toDouble(),
        width: ad.size.width.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBannerSlot(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.eventName,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.event.studioName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.orange.shade700,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search photos...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),

          if (!_isLoading && _filteredPhotos.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.grey.shade100,
              child: Text(
                '${_filteredPhotos.length} ${_filteredPhotos.length == 1 ? "photo" : "photos"}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return _buildLoadingGrid();
    if (_errorMessage != null) return _buildErrorState();
    if (_filteredPhotos.isEmpty) return _buildEmptyState();
    return _buildPhotoGrid();
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Failed to load photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPhotos,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No photos found'
                  : 'No photos available',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try a different search term'
                  : 'Photos will appear here once uploaded',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _filteredPhotos.length,
      itemBuilder: (context, index) {
        return _buildThumbnail(_filteredPhotos[index], index);
      },
    );
  }

  Widget _buildThumbnail(PhotoItem photo, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoViewerScreen(
              photos: _filteredPhotos,
              initialIndex: index,
              eventName: widget.event.eventName,
            ),
          ),
        );
      },
      child: Hero(
        tag: 'photo_${photo.eventCode}/${photo.name}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photo.thumbnailUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: Icon(Icons.broken_image, color: Colors.grey.shade400),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
