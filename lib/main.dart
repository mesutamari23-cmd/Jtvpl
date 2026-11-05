import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'store.dart';
import 'xtream_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  runApp(const MesutApp());
}

class MesutApp extends StatelessWidget {
  const MesutApp({super.key});

  @override
  Widget build(BuildContext context) {
    final acc = Store.active;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mesut IPTV',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(primary: kViolet, secondary: kGold),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, elevation: 0, centerTitle: true),
        chipTheme: ChipThemeData(
          selectedColor: kViolet,
          backgroundColor: Colors.white10,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: acc == null
          ? const LoginScreen()
          : HomeScreen(service: XtreamService.fromAccount(acc)),
    );
  }
}
