
import 'package:flutter/material.dart';
import '../services/xtream_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final url = TextEditingController();
  final user = TextEditingController();
  final pass = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  Future<void> connect() async {
    if (url.text.trim().isEmpty ||
        user.text.trim().isEmpty ||
        pass.text.isEmpty) {
      message('يرجى ملء جميع البيانات');
      return;
    }

    setState(() => loading = true);

    try {
      final service = XtreamService(
        baseUrl: url.text,
        username: user.text.trim(),
        password: pass.text,
      );

      final info = await service.login();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            service: service,
            account: info,
          ),
        ),
      );
    } catch (e) {
      message('فشل الاتصال: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    url.dispose();
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF080D1A),
              Color(0xFF171638),
              Color(0xFF080D1A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.live_tv_rounded,
                    size: 85,
                    color: Color(0xFF947BFF),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'MESUT IPTV',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'عالم الترفيه بين يديك',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 40),

                  inputField(
                    url,
                    'عنوان السيرفر',
                    Icons.dns,
                  ),

                  const SizedBox(height: 16),

                  inputField(
                    user,
                    'اسم المستخدم',
                    Icons.person,
                  ),

                  const SizedBox(height: 16),

                  inputField(
                    pass,
                    'كلمة المرور',
                    Icons.lock,
                    password: true,
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      autofocus: true,
                      onPressed: loading ? null : connect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF7958FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'اتصال بالسيرفر',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'MESUT ENTERTAINMENT',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget inputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool password = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: password && hidePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF947BFF),
        ),
        suffixIcon: password
            ? IconButton(
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
                icon: Icon(
                  hidePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.white70,
                ),
              )
            : null,
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.white70,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
