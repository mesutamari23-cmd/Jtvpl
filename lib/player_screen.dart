import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'theme.dart';
import 'models.dart';
import 'store.dart';
import 'utils.dart';
import 'xtream_service.dart';

class PlayerScreen extends StatefulWidget {
  final List<PlayItem> items;
  final int index;
  const PlayerScreen({super.key, required this.items, this.index = 0});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _c;
  late int _i = widget.index;
  bool _ready = false, _show = true, _ended = false;
  String? _err;
  Timer? _hide, _saveTimer;
  int _tok = 0;
  double _speed = 1;
  BoxFit _fit = BoxFit.contain;

  PlayItem get _item => widget.items[_i];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());
    _load();
  }

  @override
  void dispose() {
    _saveProgress();
    _hide?.cancel();
    _saveTimer?.cancel();
    WakelockPlus.disable();
    _c?.removeListener(_onTick);
    _c?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    final old = _c;
    final token = ++_tok;
    setState(() {
      _ready = false;
      _err = null;
      _ended = false;
      _c = null;
    });
    old?.removeListener(_onTick);
    await old?.dispose();

    final c = VideoPlayerController.networkUrl(Uri.parse(_item.url),
        httpHeaders: const {'User-Agent': kUserAgent});
    try {
      await c.initialize();
      if (!mounted || token != _tok) {
        await c.dispose();
        return;
      }
      final saved = Store.position(_item.key);
      final dur = c.value.duration.inMilliseconds;
      if (saved > 5000 && saved < dur - 15000) {
        await c.seekTo(Duration(milliseconds: saved));
      }
      await c.setPlaybackSpeed(_speed);
      c.addListener(_onTick);
      await c.play();
      setState(() {
        _c = c;
        _ready = true;
      });
      _autoHide();
    } catch (_) {
      await c.dispose();
      if (mounted && token == _tok) setState(() => _err = 'تعذر تشغيل الفيديو');
    }
  }

  void _onTick() {
    final c = _c;
    if (c == null || !mounted) return;
    final v = c.value;
    if (!_ended &&
        v.duration.inMilliseconds > 0 &&
        v.position >= v.duration - const Duration(milliseconds: 500)) {
      _ended = true;
      _saveProgress();
      _next();
      return;
    }
    setState(() {});
  }

  void _saveProgress() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    Store.saveProgress(
        _item, c.value.position.inMilliseconds, c.value.duration.inMilliseconds);
  }

  void _next() {
    if (_i + 1 < widget.items.length) {
      _i++;
      _load();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_i > 0) {
      _saveProgress();
      _i--;
      _load();
    }
  }

  void _autoHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 4), () {
      if (mounted && (_c?.value.isPlaying ?? false)) setState(() => _show = false);
    });
  }

  void _toggleUi() {
    setState(() => _show = !_show);
    if (_show) _autoHide();
  }

  void _playPause() {
    final c = _c;
    if (c == null) return;
    c.value.isPlaying ? c.pause() : c.play();
    setState(() => _show = true);
    _autoHide();
  }

  void _seek(int seconds) {
    final c = _c;
    if (c == null) return;
    final v = c.value;
    var t = v.position + Duration(seconds: seconds);
    if (t < Duration.zero) t = Duration.zero;
    if (t > v.duration) t = v.duration;
    c.seekTo(t);
    setState(() => _show = true);
    _autoHide();
  }

  void _cycleSpeed() {
    const speeds = [1.0, 1.25, 1.5, 2.0, 0.75];
    final n = speeds[(speeds.indexOf(_speed) + 1) % speeds.length];
    _speed = n;
    _c?.setPlaybackSpeed(n);
    setState(() {});
    _autoHide();
  }

  void _cycleFit() {
    setState(() {
      _fit = _fit == BoxFit.contain
          ? BoxFit.cover
          : _fit == BoxFit.cover
              ? BoxFit.fill
              : BoxFit.contain;
    });
    _autoHide();
  }

  Widget _video() {
    final c = _c;
    if (_err != null) {
      return Center(child: Text(_err!, style: const TextStyle(color: Colors.white70)));
    }
    if (c == null || !_ready) return const Center(child: CircularProgressIndicator());
    final s = c.value.size;
    if (s.width <= 0 || s.height <= 0) {
      return Center(child: AspectRatio(aspectRatio: 16 / 9, child: VideoPlayer(c)));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: _fit,
        child: SizedBox(width: s.width, height: s.height, child: VideoPlayer(c)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _c?.value;
    final total = max(1, v?.duration.inMilliseconds ?? 1);
    final pos = min(v?.position.inMilliseconds ?? 0, total).toDouble();
    final multi = widget.items.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.mediaRewind) {
            _seek(-10);
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.arrowRight ||
              k == LogicalKeyboardKey.mediaFastForward) {
            _seek(10);
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.select ||
              k == LogicalKeyboardKey.enter ||
              k == LogicalKeyboardKey.mediaPlayPause) {
            _playPause();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleUi,
          child: Stack(
            children: [
              Positioned.fill(child: _video()),
              if (_ready && (v?.isBuffering ?? false))
                const Center(child: CircularProgressIndicator()),
              if (_show) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Text(_item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              Text(mmss(v?.position ?? Duration.zero),
                                  style: const TextStyle(fontSize: 12)),
                              Expanded(
                                child: Slider(
                                  activeColor: kGold,
                                  value: pos,
                                  max: total.toDouble(),
                                  onChanged: _ready
                                      ? (x) => _c?.seekTo(Duration(milliseconds: x.toInt()))
                                      : null,
                                ),
                              ),
                              Text(mmss(v?.duration ?? Duration.zero),
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _cycleSpeed,
                              child: Text('${_speed}x'),
                            ),
                            const SizedBox(width: 8),
                            if (multi)
                              IconButton(
                                iconSize: 32,
                                icon: const Icon(Icons.skip_previous_rounded),
                                onPressed: _i > 0 ? _prev : null,
                              ),
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.replay_10_rounded),
                              onPressed: () => _seek(-10),
                            ),
                            IconButton(
                              iconSize: 52,
                              color: kGold,
                              icon: Icon((v?.isPlaying ?? false)
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded),
                              onPressed: _playPause,
                            ),
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.forward_10_rounded),
                              onPressed: () => _seek(10),
                            ),
                            if (multi)
                              IconButton(
                                iconSize: 32,
                                icon: const Icon(Icons.skip_next_rounded),
                                onPressed: _i + 1 < widget.items.length ? _next : null,
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.aspect_ratio_rounded),
                              onPressed: _cycleFit,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
