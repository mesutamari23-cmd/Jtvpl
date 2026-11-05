
import 'package:flutter/material.dart';
import '../services/xtream_service.dart';
import 'live_tv_screen.dart';

class HomeScreen extends StatelessWidget {
  final XtreamService service;
  final Map<String, dynamic> account;

  const HomeScreen({
    super.key,
    required this.service,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF080D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10172A),
        title: const Text(
          'MESUT IPTV',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: const [
          Icon(Icons.account_circle_outlined),
          SizedBox(width: 20),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مرحباً بك 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'حسابك: ${account['username'] ?? 'مشترك'}',
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 30),

                GridView.count(
                  crossAxisCount: width > 700 ? 3 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 1.2,
                  children: [
                    categoryCard(
                      context,
                      'TV Direct',
                      'التلفزيون المباشر',
                      Icons.live_tv_rounded,
                      const Color(0xFF6548D8),
                      true,
                    ),

                    categoryCard(
                      context,
                      'Films',
                      'الأفلام',
                      Icons.movie_rounded,
                      const Color(0xFFB34877),
                      false,
                    ),

                    categoryCard(
                      context,
                      'Séries',
                      'المسلسلات',
                      Icons.video_library_rounded,
                      const Color(0xFF168EAB),
                      false,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6548D8),
                        Color(0xFF202B68),
                      ],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MESUT ENTERTAINMENT',
                        style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'كل الترفيه في مكان واحد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'استمتع بمشاهدة محتواك المفضل',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget categoryCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool enabled,
  ) {
    return InkWell(
      autofocus: enabled,
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        if (enabled) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveTVScreen(
                service: service,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'سيتم إضافة هذا القسم في المرحلة القادمة',
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
