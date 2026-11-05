import 'package:flutter/material.dart';
import '../services/xtream_service.dart';
import 'live_tv_screen.dart';

class HomeScreen extends StatelessWidget {
  final XtreamService xtreamService;

  const HomeScreen({super.key, required this.xtreamService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        backgroundColor: Colors.purpleAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Text("حساب نشط (Xtream User)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 40),

              // Glassmorphism Dashboard Cards
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        title: 'TV Direct',
                        subtitle: 'البث المباشر والقنوات',
                        icon: Icons.tv,
                        color: Colors.redAccent.withOpacity(0.85),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LiveTvScreen(xtreamService: xtreamService),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        title: 'Films',
                        subtitle: 'مكتبة الأفلام',
                        icon: Icons.videocam,
                        color: Colors.lightGreen.withOpacity(0.85),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCategoryCard(
                        context,
                        title: 'Séries',
                        subtitle: 'المسلسلات والعروض',
                        icon: Icons.movie_creation,
                        color: Colors.teal.withOpacity(0.85),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Info Bar / Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.qr_code_scanner, size: 30, color: Colors.purpleAccent),
                        SizedBox(width: 12),
                        Text("شاهد في أي مكان! امسح الكود لتحميل التطبيق على هاتفك"),
                      ],
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: 2)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                Icon(icon, size: 48, color: Colors.white),
              ],
            )
          ],
        ),
      ),
    );
  }
}
