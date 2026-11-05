
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/xtream_service.dart';

class LiveTVScreen extends StatefulWidget {
  final XtreamService service;

  const LiveTVScreen({
    super.key,
    required this.service,
  });

  @override
  State<LiveTVScreen> createState() => _LiveTVScreenState();
}

class _LiveTVScreenState extends State<LiveTVScreen> {
  List<dynamic> categories = [];
  List<dynamic> channels = [];

  String? selectedCategory;
  String selectedName = 'اختر قناة للمشاهدة';

  VideoPlayerController? player;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final result =
          await widget.service.getLiveCategories();

      if (!mounted) return;

      setState(() {
        categories = result;
        loading = false;
      });

      if (result.isNotEmpty) {
        await selectCategory(
          result.first['category_id'].toString(),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'تعذر تحميل التصنيفات';
      });
    }
  }

  Future<void> selectCategory(String id) async {
    setState(() {
      selectedCategory = id;
      loading = true;
      channels = [];
      error = null;
    });

    try {
      final result =
          await widget.service.getLiveStreams(
        categoryId: id,
      );

      if (!mounted) return;

      setState(() {
        channels = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = 'تعذر تحميل القنوات';
      });
    }
  }

  Future<void> playChannel(Map channel) async {
    final streamUrl = widget.service.getLiveUrl(
      channel['stream_id'],
    );

    final oldPlayer = player;
    player = null;

    if (oldPlayer != null) {
      await oldPlayer.dispose();
    }

    if (!mounted) return;

    setState(() {
      selectedName =
          channel['name']?.toString() ?? 'قناة';
      error = null;
    });

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(streamUrl),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
      ),
    );

    player = controller;

    try {
      await controller.initialize();

      if (!mounted || player != controller) return;

      await controller.play();

      if (!mounted || player != controller) return;

      setState(() {});
    } catch (e) {
      if (!mounted || player != controller) return;

      setState(() {
        error =
            'تعذر تشغيل القناة. تحقق من السيرفر أو صيغة البث.';
      });
    }
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = player;

    return Scaffold(
      backgroundColor: const Color(0xFF080D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10172A),
        title: Text(selectedName),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 235,
              color: Colors.black,
              child: controller != null &&
                      controller.value.isInitialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio:
                            controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          if (loading)
                            const CircularProgressIndicator()
                          else
                            const Icon(
                              Icons.live_tv,
                              size: 55,
                              color: Colors.white54,
                            ),
                          const SizedBox(height: 12),
                          Text(
                            error ?? selectedName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),

            if (controller != null &&
                controller.value.isInitialized)
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      if (controller.value.isPlaying) {
                        await controller.pause();
                      } else {
                        await controller.play();
                      }

                      if (mounted) setState(() {});
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'البث المباشر',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenPlayer(
                            controller: controller,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

            const Divider(color: Colors.white12),

            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 125,
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final id =
                            category['category_id'].toString();

                        final selected =
                            selectedCategory == id;

                        return ListTile(
                          autofocus: index == 0,
                          selected: selected,
                          selectedTileColor:
                              const Color(0xFF6548D8),
                          title: Text(
                            category['category_name']
                                    ?.toString() ??
                                'تصنيف',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => selectCategory(id),
                        );
                      },
                    ),
                  ),

                  const VerticalDivider(
                    color: Colors.white12,
                    width: 1,
                  ),

                  Expanded(
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : channels.isEmpty
                            ? Center(
                                child: Text(
                                  error ?? 'لا توجد قنوات',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                itemCount: channels.length,
                                itemBuilder: (context, index) {
                                  final channel = channels[index];

                                  return ListTile(
                                    autofocus: index == 0,
                                    leading: const Icon(
                                      Icons.tv,
                                      color: Color(0xFF947BFF),
                                    ),
                                    title: Text(
                                      channel['name']
                                              ?.toString() ??
                                          'قناة',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    onTap: () =>
                                        playChannel(channel),
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
}

class FullScreenPlayer extends StatelessWidget {
  final VideoPlayerController controller;

  const FullScreenPlayer({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
