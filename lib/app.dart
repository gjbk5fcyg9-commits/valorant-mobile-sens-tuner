import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sens_tuner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
        ),
      ),
      // 新的官方本地化委托
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // 兼容桥，解决第三方旧包上下文/主题问题
      builder: (context, child) {
        return MaterialUiCompatibilityBridge(child: child!);
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("首页")),
      body: const Center(child: Text("OK")),
    );
  }
}