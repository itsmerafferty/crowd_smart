import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../config/api_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TourScene — uses GPS coordinates so Street View finds the real panorama
// ─────────────────────────────────────────────────────────────────────────────
class TourScene {
  final String label;
  final String description;
  final String icon;
  final double lat;
  final double lng;
  final double heading; // initial compass heading

  const TourScene({
    required this.label,
    required this.description,
    required this.icon,
    required this.lat,
    required this.lng,
    this.heading = 0,
  });

  /// One Street View tile at a given heading angle
  String tileUrl(double headingDeg) {
    final h = (headingDeg % 360).toStringAsFixed(1);
    return 'https://maps.googleapis.com/maps/api/streetview'
        '?size=640x640'
        '&location=$lat,$lng'
        '&heading=$h'
        '&pitch=0'
        '&fov=90'
        '&radius=50'
        '&key=${ApiConfig.googleMapsApiKey}';
  }

  /// Metadata URL — check if Street View exists before fetching tiles
  String get metaUrl =>
      'https://maps.googleapis.com/maps/api/streetview/metadata'
      '?location=$lat,$lng'
      '&radius=50'
      '&key=${ApiConfig.googleMapsApiKey}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Real GPS coordinates for each Baguio City destination
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, List<TourScene>> _tourScenes = {
  'burnham': [
    TourScene(
      label: 'Boating Lake',       icon: '🚣',
      description: 'The iconic man-made lake at the heart of Burnham Park — paddle boats, picnics and lush greenery.',
      lat: 16.4119, lng: 120.5933, heading: 90,
    ),
    TourScene(
      label: 'Park Grounds',       icon: '🏞️',
      description: 'Wide open lawns popular for morning jogs, bike rentals and family gatherings.',
      lat: 16.4112, lng: 120.5940, heading: 180,
    ),
    TourScene(
      label: 'Rose Garden',        icon: '🌹',
      description: 'Hundreds of rose varieties bloom year-round in this fragrant corner of the park.',
      lat: 16.4105, lng: 120.5927, heading: 45,
    ),
  ],
  'mines_view': [
    TourScene(
      label: 'Mountain Overlook',  icon: '⛰️',
      description: 'A breathtaking panorama of the Cordillera mountains and the valley far below.',
      lat: 16.3988, lng: 120.5960, heading: 270,
    ),
    TourScene(
      label: 'Souvenir Stalls',    icon: '🛍️',
      description: 'Rows of stalls selling woodcarvings, silver jewellery and Baguio pasalubong.',
      lat: 16.3985, lng: 120.5965, heading: 45,
    ),
    TourScene(
      label: 'Valley Vista',       icon: '🌄',
      description: 'On clear days the valley carved by ancient rivers stretches far into the distance.',
      lat: 16.3992, lng: 120.5955, heading: 200,
    ),
  ],
  'mansion': [
    TourScene(
      label: 'Grand Entrance Gate',icon: '🏛️',
      description: 'The iconic wrought-iron gate of The Mansion, summer residence of the Philippine President.',
      lat: 16.4154, lng: 120.5937, heading: 0,
    ),
    TourScene(
      label: 'Garden Grounds',     icon: '🌿',
      description: 'Manicured hedges and flowering gardens surround the presidential estate.',
      lat: 16.4158, lng: 120.5930, heading: 135,
    ),
  ],
  'camp_john_hay': [
    TourScene(
      label: 'Pine Forest Trail',  icon: '🌲',
      description: 'Towering Benguet pines line tranquil trails — fresh pine scent fills the cool air.',
      lat: 16.3963, lng: 120.5779, heading: 90,
    ),
    TourScene(
      label: 'Golf Course',        icon: '⛳',
      description: 'World-class 18-hole course set among scenic pine-covered hills.',
      lat: 16.3950, lng: 120.5770, heading: 200,
    ),
    TourScene(
      label: 'Forest Walk',        icon: '🌳',
      description: 'Peaceful boardwalk paths through old-growth forest inside Camp John Hay.',
      lat: 16.3975, lng: 120.5785, heading: 0,
    ),
  ],
  'good_shepherd': [
    TourScene(
      label: 'Convent & Shop',     icon: '⛪',
      description: 'Famous for handmade ube jam, peanut brittle, strawberry jam and Baguio delicacies.',
      lat: 16.4010, lng: 120.5942, heading: 60,
    ),
  ],
  'session_road': [
    TourScene(
      label: 'Session Road Strip', icon: '🛍️',
      description: 'The heart of Baguio — lined with restaurants, shops and cafés on both sides.',
      lat: 16.4090, lng: 120.5970, heading: 0,
    ),
    TourScene(
      label: 'Street Food Lane',   icon: '🍓',
      description: 'Strawberry taho, corn, Baguio longganisa — best enjoyed on a chilly morning.',
      lat: 16.4095, lng: 120.5975, heading: 180,
    ),
    TourScene(
      label: 'Night Strip',        icon: '🌙',
      description: 'Session Road at night glows with restaurants, live music and Baguio city lights.',
      lat: 16.4085, lng: 120.5965, heading: 90,
    ),
  ],
  'baguio_night_market': [
    TourScene(
      label: 'Night Market',       icon: '🌙',
      description: 'Harrison Road every Friday–Sunday night: ukay-ukay, street food and bargain finds.',
      lat: 16.4080, lng: 120.5960, heading: 270,
    ),
  ],
  'botanical': [
    TourScene(
      label: 'Flower Garden',      icon: '🌺',
      description: 'Native Cordillera plants and flowers in beautifully arranged garden beds.',
      lat: 16.4140, lng: 120.5920, heading: 45,
    ),
    TourScene(
      label: 'Igorot Village',     icon: '🏡',
      description: 'Traditional village exhibit showcasing indigenous Cordillera architecture.',
      lat: 16.4143, lng: 120.5915, heading: 120,
    ),
  ],
};

// ─────────────────────────────────────────────────────────────────────────────
// Spherical panorama painter — GPU-accelerated via ImageShader
// One drawRect call per frame; no per-pixel CPU loop
// ─────────────────────────────────────────────────────────────────────────────
class _SpherePainter extends CustomPainter {
  final ui.Image image;
  final double yaw;
  final double pitch;
  final double fov;

  const _SpherePainter({
    required this.image,
    required this.yaw,
    required this.pitch,
    required this.fov,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    // visibleFraction: at fov=π/2 show exactly 1/4 of the 4-tile panorama
    final visibleFraction = fov / (2 * math.pi);
    final sliceW = (imgW * visibleFraction).clamp(1.0, imgW);
    final sliceH = (sliceW * (size.height / size.width)).clamp(1.0, imgH * 2);

    final panoX = (yaw / (2 * math.pi)) * imgW;
    final pitchOffset = (pitch / math.pi) * imgH;
    final panoY = (imgH / 2) + pitchOffset - sliceH / 2;

    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = false;

    final x1 = panoX % imgW;
    final remaining = imgW - x1;

    if (remaining >= sliceW) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(x1, panoY, sliceW, sliceH),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    } else {
      final w1    = remaining;
      final w2    = sliceW - w1;
      final frac1 = w1 / sliceW;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(x1, panoY, w1, sliceH),
        Rect.fromLTWH(0, 0, size.width * frac1, size.height),
        paint,
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, panoY, w2, sliceH),
        Rect.fromLTWH(size.width * frac1, 0, size.width * (1 - frac1), size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpherePainter old) =>
      old.yaw != yaw || old.pitch != pitch ||
      old.fov != fov || old.image != image;

  @override
  bool shouldRebuildSemantics(_SpherePainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// PanoramaScreen
// ─────────────────────────────────────────────────────────────────────────────
class PanoramaScreen extends StatefulWidget {
  final TouristLocation location;
  const PanoramaScreen({super.key, required this.location});

  @override
  State<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends State<PanoramaScreen>
    with TickerProviderStateMixin {

  int    _sceneIndex = 0;
  bool   _autoTour   = false;
  Timer? _autoTourTimer;

  double _yaw        = 0.0;
  double _pitch      = 0.0;
  double _fov        = math.pi / 2;
  double _startFov   = math.pi / 2;
  bool   _autoRotate = true;

  ui.Image? _panoImage;
  bool      _loading = false;
  bool      _failed  = false;
  bool      _isStreetView = false;

  bool _showControls  = true;
  bool _showInfo      = true;
  bool _transitioning = false;

  late AnimationController _rotateCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double>   _fadeAnim;

  static const double _minFov   =  0.4;
  static const double _maxFov   =  1.8;
  static const double _minPitch = -0.6;
  static const double _maxPitch =  0.6;

  List<TourScene> get _scenes =>
      _tourScenes[widget.location.id] ?? [];

  TourScene? get _scene =>
      _scenes.isEmpty ? null : _scenes[_sceneIndex];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 90))
      ..addListener(() {
        if (_autoRotate && _panoImage != null) {
          setState(() => _yaw = _rotateCtrl.value * 2 * math.pi);
        }
      })
      ..repeat();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500), value: 1.0);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);

    if (_scene != null) _loadScene(_scene!);
  }

  @override
  void dispose() {
    _autoTourTimer?.cancel();
    _rotateCtrl.dispose();
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ── Image loading ──────────────────────────────────────────────────────────
  Future<void> _loadScene(TourScene scene) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
      _panoImage = null;
      _isStreetView = false;
    });

    // Step 1: check metadata to see if Street View coverage exists
    final hasCoverage = await _checkMeta(scene.metaUrl);
    debugPrint('[Pano] ${scene.label} coverage=$hasCoverage');

    if (hasCoverage) {
      // 4 tiles × 90° FOV = perfect 360° strip
      final offsets = [0.0, 90.0, 180.0, 270.0];
      final rawTiles = await Future.wait(
        offsets.map((o) => _fetchBytes(scene.tileUrl(scene.heading + o))),
      );

      final valid = rawTiles.where((b) => b != null).length;
      debugPrint('[Pano] tiles loaded: $valid/4');

      if (valid == 4) {
        final List<ui.Image> imgs = [];
        for (final bytes in rawTiles) {
          final codec = await ui.instantiateImageCodec(bytes!);
          final frame = await codec.getNextFrame();
          imgs.add(frame.image);
        }
        final stitched = await _stitch(imgs, 640, 640);
        if (!mounted) return;
        setState(() {
          _panoImage = stitched;
          _loading = false;
          _isStreetView = true;
        });
        return;
      }
    }

    // Step 3: fallback to Unsplash wide photo
    debugPrint('[Pano] using Unsplash fallback');
    final fallbackUrl = _fallbackFor(widget.location.id, _sceneIndex);
    final bytes = await _fetchBytes(fallbackUrl);
    if (bytes != null) {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _panoImage = frame.image;
        _loading = false;
        _isStreetView = false;
      });
    } else {
      if (mounted) setState(() { _loading = false; _failed = true; });
    }
  }

  /// Returns true if Street View metadata says status == "OK"
  Future<bool> _checkMeta(String url) async {
    try {
      final client   = HttpClient();
      final request  = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 8));
      final body     = await utf8.decodeStream(response);
      client.close();
      debugPrint('[Pano] meta body: $body');
      return body.contains('"status" : "OK"') || body.contains('"status":"OK"');
    } catch (e) {
      debugPrint('[Pano] meta error: $e');
      return false;
    }
  }

  Future<Uint8List?> _fetchBytes(String url) async {
    try {
      final client   = HttpClient();
      final request  = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        client.close();
        return null;
      }
      final bytes = await consolidateHttpClientResponseBytes(response);
      client.close();
      debugPrint('[Pano] fetched ${bytes.length} bytes from $url');
      return bytes;
    } catch (e) {
      debugPrint('[Pano] fetch error: $e');
      return null;
    }
  }

  Future<ui.Image> _stitch(List<ui.Image> tiles, int tw, int th) async {
    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    final paint    = Paint();
    for (int i = 0; i < tiles.length; i++) {
      canvas.drawImageRect(
        tiles[i],
        Rect.fromLTWH(0, 0, tw.toDouble(), th.toDouble()),
        Rect.fromLTWH((i * tw).toDouble(), 0, tw.toDouble(), th.toDouble()),
        paint,
      );
    }
    return recorder.endRecording().toImage(tw * tiles.length, th);
  }

  // ── Scene switching ────────────────────────────────────────────────────────
  Future<void> _goToScene(int index) async {
    if (index == _sceneIndex || _transitioning || _scenes.isEmpty) return;
    setState(() { _transitioning = true; _showInfo = false; });
    await _fadeCtrl.reverse();
    setState(() {
      _sceneIndex = index;
      _yaw = 0; _pitch = 0; _fov = math.pi / 2; _autoRotate = true;
    });
    _rotateCtrl.repeat();
    await _loadScene(_scenes[index]);
    if (!mounted) return;
    await _fadeCtrl.forward();
    setState(() { _transitioning = false; _showInfo = true; });
  }

  void _nextScene() => _goToScene((_sceneIndex + 1) % _scenes.length);
  void _prevScene() => _goToScene((_sceneIndex - 1 + _scenes.length) % _scenes.length);

  void _toggleAutoTour() {
    setState(() => _autoTour = !_autoTour);
    if (_autoTour) {
      _autoTourTimer = Timer.periodic(const Duration(seconds: 10), (_) => _nextScene());
    } else {
      _autoTourTimer?.cancel();
    }
  }

  // ── Gestures ───────────────────────────────────────────────────────────────
  void _onScaleStart(ScaleStartDetails d) {
    _autoRotate = false;
    _rotateCtrl.stop();
    _startFov = _fov;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      // Pinch = zoom
      _fov = (_startFov / d.scale).clamp(_minFov, _maxFov);
      // Pan sensitivity scales with FOV (wider = faster pan)
      final sens = (_fov / (math.pi * 2)) * 3.5;
      _yaw   = _yaw - d.focalPointDelta.dx * sens;
      _pitch = (_pitch + d.focalPointDelta.dy * sens).clamp(_minPitch, _maxPitch);
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onScaleEnd: (_) {},
        child: Stack(fit: StackFit.expand, children: [
          FadeTransition(opacity: _fadeAnim, child: _buildSphere()),
          _vignette(),
          if (_showControls && _showInfo && _scene != null) _buildInfo(),
          if (_showControls) _buildTopBar(),
          if (_showControls && _scenes.length > 1) _buildBottomNav(),
          if (_showControls && _scenes.length > 1) ...[_arrow(true), _arrow(false)],
          _compass(),
          if (_loading) _buildLoader(),
        ]),
      ),
    );
  }

  // ── Sphere ─────────────────────────────────────────────────────────────────
  Widget _buildSphere() {
    if (_failed || _panoImage == null) return _buildFallbackWidget();
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SpherePainter(
          image: _panoImage!, yaw: _yaw, pitch: _pitch, fov: _fov),
        size: Size.infinite,
      ),
    );
  }

  Widget _vignette() => IgnorePointer(
    child: Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center, radius: 1.1,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
        ),
      ),
    ),
  );

  // ── Info card ──────────────────────────────────────────────────────────────
  Widget _buildInfo() {
    final s = _scene!;
    return Positioned(
      left: 14, bottom: _scenes.length > 1 ? 96 : 20,
      right: MediaQuery.of(context).size.width * 0.28,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 5, runSpacing: 4, children: [
            _badge('Scene ${_sceneIndex + 1}/${_scenes.length}', widget.location.statusColor),
            if (_isStreetView) _badge('📍 Street View', Colors.blue),
            if (_autoTour)     _badge('▶ AUTO', Colors.green),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text(s.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(s.label,
                style: const TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)]))),
          ]),
          const SizedBox(height: 4),
          Text(s.description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, height: 1.4)),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
  );

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() => Positioned(
    top: 0, left: 0, right: 0,
    child: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent])),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12, right: 12, bottom: 14),
      child: Row(children: [
        _iconBtn(Icons.arrow_back, () => Navigator.pop(context)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.threesixty, color: Colors.white60, size: 12),
            SizedBox(width: 4),
            Text('360° Virtual Tour',
                style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 0.8)),
          ]),
          Text(widget.location.name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ])),
        _labelBtn(Icons.rotate_right, 'Rotate', _autoRotate, () {
          setState(() => _autoRotate = !_autoRotate);
          if (_autoRotate) _rotateCtrl.repeat();
        }),
        const SizedBox(width: 6),
        _labelBtn(
          _autoTour ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          _autoTour ? 'Stop' : 'Tour', _autoTour, _toggleAutoTour,
          activeColor: Colors.green,
        ),
        const SizedBox(width: 6),
        _iconBtn(Icons.crop_free,
            () => setState(() { _yaw = 0; _pitch = 0; _fov = math.pi / 2; })),
      ]),
    ),
  );

  // ── Bottom scene nav ───────────────────────────────────────────────────────
  Widget _buildBottomNav() => Positioned(
    bottom: 0, left: 0, right: 0,
    child: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent])),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 10,
          left: 12, right: 12, top: 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Drag · Pinch to zoom · Tap arrows to switch',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 9)),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, shrinkWrap: true,
            itemCount: _scenes.length,
            itemBuilder: (_, i) {
              final sel = i == _sceneIndex;
              return GestureDetector(
                onTap: () => _goToScene(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: EdgeInsets.symmetric(horizontal: sel ? 12 : 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? widget.location.statusColor.withValues(alpha: 0.85)
                        : Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: sel ? Colors.white54 : Colors.white24,
                        width: sel ? 1.5 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_scenes[i].icon, style: const TextStyle(fontSize: 15)),
                    if (sel) ...[
                      const SizedBox(width: 5),
                      Text(_scenes[i].label,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    ),
  );

  // ── Arrows ─────────────────────────────────────────────────────────────────
  Widget _arrow(bool left) => Positioned(
    top: 0, bottom: 0,
    left: left ? 0 : null, right: left ? null : 0,
    child: GestureDetector(
      onTap: left ? _prevScene : _nextScene,
      child: Container(
        width: 44, color: Colors.transparent,
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Opacity(
            opacity: 0.35 + _pulseCtrl.value * 0.3,
            child: Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30)),
              child: Icon(
                  left ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    ),
  );

  // ── Compass ────────────────────────────────────────────────────────────────
  Widget _compass() => Positioned(
    top: MediaQuery.of(context).padding.top + 58, right: 12,
    child: IgnorePointer(
      child: AnimatedOpacity(
        opacity: _showControls ? 0.85 : 0.2,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
              color: Colors.black54, shape: BoxShape.circle,
              border: Border.all(color: Colors.white24)),
          child: Transform.rotate(
            angle: -_yaw,
            child: const Icon(Icons.navigation, color: Color(0xFFE53935), size: 18),
          ),
        ),
      ),
    ),
  );

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoader() => Container(
    color: Colors.black87,
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (_scene != null) Text(_scene!.icon, style: const TextStyle(fontSize: 52)),
      const SizedBox(height: 20),
      const SizedBox(width: 30, height: 30,
          child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)),
      const SizedBox(height: 14),
      Text(_scene != null ? 'Loading ${_scene!.label}…' : 'Loading…',
          style: const TextStyle(color: Colors.white60, fontSize: 12)),
      const SizedBox(height: 4),
      const Text('Fetching Street View panorama…',
          style: TextStyle(color: Colors.white30, fontSize: 10)),
    ])),
  );

  // ── Gradient fallback ──────────────────────────────────────────────────────
  Widget _buildFallbackWidget() {
    final colors = _gradientFor(widget.location.category);
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_scene?.icon ?? widget.location.emoji,
            style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text(_scene?.label ?? widget.location.name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(_scene?.description ?? widget.location.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24)),
          child: const Text('No Street View available at this spot',
              style: TextStyle(color: Colors.white54, fontSize: 11)),
        ),
      ])),
    );
  }

  List<Color> _gradientFor(String cat) {
    switch (cat) {
      case 'Park': case 'Nature':       return [const Color(0xFF1a3a52), const Color(0xFF2d6a4f)];
      case 'Viewpoint':                 return [const Color(0xFF0d1b2a), const Color(0xFF1b4f72)];
      case 'Heritage':                  return [const Color(0xFF2c1810), const Color(0xFF7d3c1e)];
      case 'Recreation':                return [const Color(0xFF0a2239), const Color(0xFF52796f)];
      case 'Market': case 'Commercial': return [const Color(0xFF1a0a2e), const Color(0xFF6a0572)];
      default:                          return [const Color(0xFF1a2a4a), const Color(0xFF2d5a8e)];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _iconBtn(IconData icon, VoidCallback fn) => GestureDetector(
    onTap: fn,
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(9)),
      child: Icon(icon, color: Colors.white, size: 17),
    ),
  );

  Widget _labelBtn(IconData icon, String label, bool active, VoidCallback fn,
      {Color activeColor = const Color(0xFF2196F3)}) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active ? activeColor.withValues(alpha: 0.22) : Colors.black54,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: active ? activeColor : Colors.transparent),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: active ? activeColor : Colors.white60, size: 12),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
                color: active ? activeColor : Colors.white60,
                fontSize: 10, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback Unsplash photos per destination / scene index
// ─────────────────────────────────────────────────────────────────────────────
String _fallbackFor(String id, int sceneIndex) {
  const fallbacks = <String, List<String>>{
    'burnham':            ['https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1600',
                           'https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=1600',
                           'https://images.unsplash.com/photo-1490750967868-88df5691cc33?w=1600'],
    'mines_view':         ['https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1600',
                           'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1600',
                           'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=1600'],
    'mansion':            ['https://images.unsplash.com/photo-1564507592333-c60657eea523?w=1600',
                           'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=1600'],
    'camp_john_hay':      ['https://images.unsplash.com/photo-1448375240586-882707db888b?w=1600',
                           'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=1600',
                           'https://images.unsplash.com/photo-1542273917363-3b1817f69a2d?w=1600'],
    'good_shepherd':      ['https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=1600'],
    'session_road':       ['https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=1600',
                           'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=1600',
                           'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=1600'],
    'baguio_night_market':['https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=1600'],
    'botanical':          ['https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=1600',
                           'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=1600'],
  };
  final list = fallbacks[id] ?? ['https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1600'];
  return list[sceneIndex.clamp(0, list.length - 1)];
}
