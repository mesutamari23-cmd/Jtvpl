import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/xtream_service.dart';

class LiveTvScreen extends StatefulWidget {
  final XtreamService xtreamService;

  const LiveTvScreen({super.key, required this.xtreamService});

  @override
  State<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends State<LiveTvScreen> {
  late final Player player;
  late final VideoController controller;
  
  List<dynamic> categories = [];
  List<dynamic> channels = [];
  String? selectedCategoryId;
  String currentChannelTitle = "اختر قناة للتشغيل";
  bool isLoadingChannels = false;
  bool isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    try {
      player = Player();
      controller = VideoController(player);
      isPlayerInitialized = true;
    } catch (e) {
      isPlayerInitialized = false;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    if (isPlayerInitialized) {
      player.dispose();
    }
    super.dispose();
  }

  void _loadCategories() async {
    final cats = await widget.xtreamService.getLiveCategories();
    if (mounted) {
      setState(() {
        categories = cats;
        if (categories.isNotEmpty) {
          selectedCategoryId = categories.first['category_id'].toString();
          _loadChannels(selectedCategoryId!);
        }
      });
    }
  }

  void _loadChannels(String categoryId) async {
    setState(() => isLoadingChannels = true);
    final chs = await widget.xtreamService.getLiveStreams(categoryId: categoryId);
    if (mounted) {
      setState(() {
        channels = chs;
        isLoadingChannels = false;
      });
    }
  }

  void _playChannel(dynamic channel) {
    if (!isPlayerInitialized) return;
    final streamId = channel['stream_id'];
    final url = widget.xtreamService.buildStreamUrl(streamId);
    setState(() {
      currentChannelTitle = channel['name'] ?? 'قناة بث مباشر';
    });
    player.open(Media(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // مشغل الفيديو العلوي مع معالجة الأخطاء والشاشة السوداء
            Container(
              height: 240,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  isPlayerInitialized
                      ? Video(controller: controller)
                      : const Center(child: Text("جاري تهيئة المشغل...", style: TextStyle(color: Colors.white70))),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: Colors.black54,
                      child: Text(
                        currentChannelTitle,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // قائمة الفئات والقنوات
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 150,
                    color: const Color(0xFF141418),
                    child: categories.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = cat['category_id'].toString() == selectedCategoryId;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: Colors.purple.withOpacity(0.2),
                                title: Text(
                                  cat['category_name'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.purpleAccent : Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedCategoryId = cat['category_id'].toString();
                                  });
                                  _loadChannels(selectedCategoryId!);
                                },
                              );
                            },
                          ),
                  ),
                  const VerticalDivider(width: 1, color: Colors.white10),
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0A0A0C),
                      child: isLoadingChannels
                          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                          : ListView.builder(
                              itemCount: channels.length,
                              itemBuilder: (context, index) {
                                final channel = channels[index];
                                return ListTile(
                                  leading: const Icon(Icons.play_circle_fill, color: Colors.purpleAccent),
                                  title: Text(
                                    channel['name'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  onTap: () => _playChannel(channel),
                                );
                              },
                            ),
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
