import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'logic/providers.dart';
import 'views/incident_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: PulseSyncApp(),
    ),
  );
}

class PulseSyncApp extends ConsumerWidget {
  const PulseSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'PulseSync Dispatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.light,
          primary: const Color(0xFFD32F2F),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
          backgroundColor: Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          elevation: 1.5,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFD32F2F),
          unselectedItemColor: Colors.black54,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F141A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5252),
          brightness: Brightness.dark,
          primary: const Color(0xFFFF5252),
          surface: const Color(0xFF19202A),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 1,
          backgroundColor: Color(0xFF141A22),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: const Color(0xFF19202A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF141A22),
          selectedItemColor: Color(0xFFFF5252),
          unselectedItemColor: Colors.white60,
        ),
      ),
      themeMode: themeMode,
      home: const IncidentListScreen(),
    );
  }
}
