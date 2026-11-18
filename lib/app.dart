import 'package:material_ui/material_ui.dart';

import 'pages/home_page.dart';
import 'pages/calibrate_page.dart';
import 'pages/presets_page.dart';
import 'pages/about_page.dart';
import 'theme.dart';

void main() {
  runApp(const SensTunerApp());
}

class SensTunerApp extends StatelessWidget {
  const SensTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '灵敏度调校助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.panel,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: AppColors.accentText, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
        cardTheme: const CardThemeData(color: AppColors.panel, elevation: 0, margin: EdgeInsets.symmetric(vertical: 6)),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [HomePage(), CalibratePage(), PresetsPage(), AboutPage()],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.panel,
        selectedIndex: _index,
        indicatorColor: AppColors.primary.withValues(alpha: 0.25),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.speed_outlined), selectedIcon: Icon(Icons.speed), label: '校准'),
          NavigationDestination(icon: Icon(Icons.tune_outlined), selectedIcon: Icon(Icons.tune), label: '预设'),
          NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label: '说明'),
        ],
      ),
    );
  }
}
