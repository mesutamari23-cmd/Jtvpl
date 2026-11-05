import 'dart:ui';
import 'package:flutter/material.dart';
import 'xtream_service.dart';
import 'live_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final XtreamService service;
  const HomeScreen({super.key, required this.service});

  void _soon(BuildContext c) => ScaffoldMessenger.of(c)
      .showSnackBar(const SnackBar(content: Text('قريباً')));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF241459), Color(0xFF0A0E1F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _GlassCard(
                        title: 'TV Direct',
                        icon: Icons.live_tv_rounded,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => LiveScreen(service: service))),
                      ),
                      _GlassCard(
                        title: 'Films',
                        icon: Icons.movie_rounded,
                        onTap: () => _soon(context),
                      ),
                      _GlassCard(
                        title: 'Séries',
                        icon: Icons.video_library_rounded,
                        onTap: () => _soon(context),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.black38,
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(service.username,
                          overflow: TextOverflow.ellipsis,
                          textDirection: TextDirection.ltr),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await XtreamService.clear();
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => const LoginScreen()));
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('خروج'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _GlassCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Colors.white.withOpacity(0.08),
              child: InkWell(
                onTap: onTap,
                focusColor: const Color(0xFFD4AF37).withOpacity(0.35),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 52, color: const Color(0xFFD4AF37)),
                      const SizedBox(height: 12),
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
