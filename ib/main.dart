
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MesutIPTV());
}

class MesutIPTV extends StatelessWidget {
  const MesutIPTV({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mesut IPTV',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7958FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const LoginScreen(),
    );
  }
}
