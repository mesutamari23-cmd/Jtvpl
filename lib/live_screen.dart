import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'xtream_service.dart';

class LiveScreen extends StatefulWidget {
  final XtreamService service;
  const LiveScreen({super.key, required this.service});
  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  List<LiveCategory> _cats = [];
  List<LiveChannel> _channels = [];
  LiveCategory? _cat;
  LiveChannel? _current;
  VideoPlayerController? _ctrl;
  bool _loadingList = true, _loadingVideo = false;
  String? _error;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _loadCats() async {
    try {
      final c = await widget.service.liveCategories();
      if (!mounted) return;
      setState(() => _cats = c);
      if (c.isNotEmpty) await _selectCat(c.first);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingList = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _selectCat(LiveCategory c) async {
    setState(() {
      _cat = c;
      _loadingList = true;
    });
    try {
      final ch = await widget.service.liveStreams(c.id);
      if (!mounted || _cat != c) return;
      setState(() {
        _channels = ch;
        _loadingList = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingList = false);
    }
  }

  Future<void> _play(LiveChannel ch) async {
    final token = ++_token;
    final old = _ctrl;
    setState(() {
      _current = ch;
      _loadingVideo = true;
      _error = null;
      _ctrl = null;
    });
    await old?.dispose();

    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.service.liveUrl(ch.id)),
      httpHeaders: const {'User-Agent': 'VLC/3.0.18 LibVLC/3.0.18'},
    );
    try {
      await c.initialize();
      if (token != _token || !mounted) {
        await c.dispose();
        return;
      }
      await c.play();
      setState(() {
        _ctrl = c;
        _loadingVideo = false;
      });
    } catch (_) {
      await c.dispose();
      if (token == _token && mounted) {
        setState(() {
          _loadingVideo = false;
          _error = 'تعذر تشغيل القناة';
        });
      }
    }
  }

  Widget _player() {
    if (_loadingVideo) {
      return const Center(child: CircularProgressIndicator());
    }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final videoH = min(size.width * 9 / 16, size.height * 0.42);

    return Scaffold(
      appBar: AppBar(
        title: Text(_current?.name ?? 'TV Direct'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Container(
            height: videoH,
            width: double.infinity,
            color: Colors.black,
            child: Center(child: _player()),
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: min(150, size.width * 0.32),
                  child: ListView.builder(
                    itemCount: _cats.length,
                    itemBuilder: (_, i) {
                      final c = _cats[i];
                      return ListTile(
                        dense: true,
                        selected: c == _cat,
                        selectedTileColor: Colors.white12,
                        title: Text(c.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => _selectCat(c),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _loadingList
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _channels.length,
                          itemBuilder: (_, i) {
                            final ch = _channels[i];
                            return ListTile(
                              selected: ch.id == _current?.id,
                              selectedTileColor: Colors.white12,
                              leading: SizedBox(
                                width: 44,
                                child: ch.icon.isEmpty
                                    ? const Icon(Icons.tv_rounded)
                                    : Image.network(ch.icon,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.tv_rounded)),
                              ),
                              title: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
    );
  }
}
