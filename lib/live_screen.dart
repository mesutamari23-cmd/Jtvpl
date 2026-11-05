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

class LiveScreen extends StatefulWidget {
  final XtreamService service;
  const LiveScreen({super.key, required this.service});
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  static const _favCat = Category('__fav__', '⭐ المفضلة');

  List<Category> _cats = [];
  List<MediaItem> _channels = [];
  List<MediaItem> _favs = [];
  List<Epg> _epg = [];
  Category? _cat;
  MediaItem? _current;
  VideoPlayerController? _ctrl;
  bool _loadingList = true, _loadingVideo = false, _full = false, _search = false;
  String? _error;
  String _q = '';
  final _sc = TextEditingController();
  int _token = 0, _retries = 0;

  List<MediaItem> get _shown {
    if (_q.isEmpty) return _channels;
    final q = _q.toLowerCase();
    return _channels.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ctrl?.removeListener(_onVideo);
    _ctrl?.dispose();
    _sc.dispose();
    super.dispose();
  }

  Future<void> _setFull(bool v) async {
    setState(() => _full = v);
    if (v) {
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _zap(int d) {
    final list = _shown;
    if (list.isEmpty || _current == null) return;
    final i = list.indexWhere((c) => c.id == _current!.id);
    if (i < 0) return;
    _play(list[(i + d + list.length) % list.length]);
  }

  Future<void> _toggleFav(MediaItem ch) async {
    await Store.toggleFav('live', ch);
    if (!mounted) return;
    setState(() {
      _favs = Store.favs('live');
      if (_cat?.id == _favCat.id) _channels = List.of(_favs);
    });
  }

  Future<void> _loadCats() async {
    try {
      _favs = Store.favs('live');
      final c = await widget.service.liveCategories();
      if (!mounted) return;
      setState(() => _cats = c);
      if (c.isNotEmpty) {
        await _selectCat(c.first, check: false);
      } else {
        setState(() => _loadingList = false);
      }
      final last = Store.lastLive();
      if (last != null && mounted) _play(last);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingList = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _selectCat(Category c, {bool check = true}) async {
    if (check && isAdult(c.name) && Store.pin != null) {
      if (!await askPin(context)) return;
    }
    if (c.id == _favCat.id) {
      setState(() {
        _cat = c;
        _channels = List.of(_favs);
        _loadingList = false;
      });
      return;
    }
    setState(() {
      _cat = c;
      _loadingList = true;
    });
    try {
      final ch = await widget.service.liveStreams(c.id);
      if (!mounted || _cat?.id != c.id) return;
      setState(() {
        _channels = ch;
        _loadingList = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  // إعادة اتصال تلقائية عند انقطاع البث
  void _onVideo() {
    final c = _ctrl;
    if (c == null || !mounted) return;
    if (c.value.hasError && _current != null && _retries < 3) {
      c.removeListener(_onVideo);
      _retries++;
      final ch = _current!;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _current?.id == ch.id) _play(ch, auto: true);
      });
    }
  }

  Future<void> _play(MediaItem ch, {bool auto = false}) async {
    if (!auto) _retries = 0;
    final token = ++_token;
    final old = _ctrl;
    old?.removeListener(_onVideo);
    setState(() {
      _current = ch;
      _loadingVideo = true;
      _error = null;
      _ctrl = null;
      _epg = [];
    });
    await old?.dispose();

    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.service.liveUrl(ch.id)),
      httpHeaders: const {'User-Agent': kUserAgent},
    );
    try {
      await c.initialize();
      if (token != _token || !mounted) {
        await c.dispose();
        return;
      }
      c.addListener(_onVideo);
      await c.play();
      WakelockPlus.enable();
      Store.saveLast(ch);
      setState(() {
        _ctrl = c;
        _loadingVideo = false;
      });
      _loadEpg(ch);
    } catch (_) {
      await c.dispose();
      if (token == _token && mounted) {
        if (_retries < 3) {
          _retries++;
          setState(() => _error = 'إعادة المحاولة...');
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _current?.id == ch.id && token == _token) {
              _play(ch, auto: true);
            }
          });
        } else {
          setState(() {
            _loadingVideo = false;
            _error = 'تعذر تشغيل القناة';
          });
        }
      }
    }
  }

  Future<void> _loadEpg(MediaItem ch) async {
    try {
      final l = await widget.service.shortEpg(ch.id);
      if (mounted && _current?.id == ch.id) setState(() => _epg = l);
    } catch (_) {}
  }

  Widget _player() {
    if (_loadingVideo) return const Center(child: CircularProgressIndicator());
    if (_ctrl != null && _ctrl!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _ctrl!.value.aspectRatio == 0 ? 16 / 9 : _ctrl!.value.aspectRatio,
        child: VideoPlayer(_ctrl!),
      );
    }
    return Center(
      child: Text(_error ?? 'اختر قناة للتشغيل',
          style: const TextStyle(color: Colors.white54)),
    );
  }

  Widget _epgStrip() {
    if (_epg.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final cur = _epg.firstWhere(
      (e) => e.start.isBefore(now) && e.end.isAfter(now),
      orElse: () => _epg.first,
    );
    final idx = _epg.indexOf(cur);
    final next = idx + 1 < _epg.length ? _epg[idx + 1] : null;
    final total = cur.end.difference(cur.start).inSeconds;
    final p = total <= 0
        ? 0.0
        : (now.difference(cur.start).inSeconds / total).clamp(0.0, 1.0);

    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: Colors.redAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${cur.title}  (${hm(cur.start)} - ${hm(cur.end)})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: p, minHeight: 2, color: kGold),
          if (next != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('التالي: ${next.title} (${hm(next.start)})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.white60)),
            ),
        ],
      ),
    );
  }

  Widget _fullView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: (_, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          final k = e.logicalKey;
          if (k == LogicalKeyboardKey.arrowUp) {
            _zap(-1);
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.arrowDown) {
            _zap(1);
            return KeyEventResult.handled;
          }
          if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter) {
            _setFull(false);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _setFull(false),
          child: Stack(
            children: [
              SizedBox.expand(child: Center(child: _player())),
              if (_current != null)
                Positioned(
                  top: 16,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: Text(_current!.name),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: _search
          ? TextField(
              controller: _sc,
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                  hintText: 'ابحث عن قناة...', border: InputBorder.none),
            )
          : Text(_current?.name ?? 'TV Direct', overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          icon: Icon(_search ? Icons.close_rounded : Icons.search_rounded),
          onPressed: () => setState(() {
            _search = !_search;
            _q = '';
            _sc.clear();
          }),
        ),
      ],
    );
  }

  Widget _normalView() {
    final size = MediaQuery.of(context).size;
    final videoH = min(size.width * 9 / 16, size.height * 0.40);
    final cats = [_favCat, ..._cats];
    final shown = _shown;

    return Scaffold(
      appBar: _appBar(),
      body: Container(
        decoration: kBgGradient,
        child: Column(
          children: [
            Container(
              height: videoH,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  Center(child: _player()),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, size: 30),
                      onPressed: () => _setFull(true),
                    ),
                  ),
                ],
              ),
            ),
            _epgStrip(),
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: min(150, size.width * 0.32),
                    child: ListView.builder(
                      itemCount: cats.length,
                      itemBuilder: (_, i) {
                        final c = cats[i];
                        final locked = Store.pin != null && isAdult(c.name);
                        return ListTile(
                          dense: true,
                          selected: c.id == _cat?.id,
                          selectedColor: kGold,
                          selectedTileColor: Colors.white12,
                          title: Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: locked ? const Icon(Icons.lock_rounded, size: 14) : null,
                          onTap: () => _selectCat(c),
                        );
                      },
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _loadingList
                        ? const Center(child: CircularProgressIndicator())
                        : shown.isEmpty
                            ? const Center(
                                child: Text('لا توجد قنوات',
                                    style: TextStyle(color: Colors.white54)))
                            : ListView.builder(
                                itemCount: shown.length,
                                itemBuilder: (_, i) {
                                  final ch = shown[i];
                                  final fav = _favs.any((f) => f.id == ch.id);
                                  return ListTile(
                                    selected: ch.id == _current?.id,
                                    selectedColor: kGold,
                                    selectedTileColor: Colors.white12,
                                    leading: SizedBox(
                                      width: 44,
                                      child: ch.image.isEmpty
                                          ? const Icon(Icons.tv_rounded)
                                          : Image.network(ch.image,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(Icons.tv_rounded)),
                                    ),
                                    title: Text(ch.name,
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    trailing: IconButton(
                                      icon: Icon(
                                        fav ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: fav ? kGold : Colors.white54,
                                      ),
                                      onPressed: () => _toggleFav(ch),
                                    ),
                                    onTap: () => _play(ch),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_full,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setFull(false);
      },
      child: _full ? _fullView() : _normalView(),
    );
  }
}
