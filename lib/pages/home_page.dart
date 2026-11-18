import 'package:material_ui/material_ui.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'calibrate_page.dart';
import 'recommend_page.dart';

/// 首页：流程引导 + 状态总览。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              Text('灵敏度调校助手', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 4),
              const Text(
                '无畏契约：源能行动\n全自动测量你的操作习惯 → 推荐最贴手的灵敏度',
                style: TextStyle(color: AppColors.dimText, height: 1.5),
              ),
              const SizedBox(height: 20),
              _stepCard(
                context,
                step: 'STEP 1',
                title: '校准测量',
                desc: '滑动测试手速，可选陀螺仪测试，30 秒完成',
                icon: Icons.speed,
                trailing: app.hasSwipe ? '✓ 已完成' : '未完成',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalibratePage())),
              ),
              _stepCard(
                context,
                step: 'STEP 2',
                title: '选择风格',
                desc: app.style == null ? '稳架枪 / 均衡 / 激进跟枪，尚未选择' : '当前：${app.style!.label}',
                icon: Icons.person_outline,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalibratePage())),
              ),
              _stepCard(
                context,
                step: 'STEP 3',
                title: '生成推荐',
                desc: '得到整套滑屏 / 开火 / 陀螺仪数值，对照填入游戏',
                icon: Icons.auto_awesome,
                enabled: app.readyToRecommend,
                onTap: app.readyToRecommend
                    ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendPage()))
                    : null,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D5A80).withValues(alpha: 0.5)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, color: Color(0xFF5C8DFF), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '合规声明：本工具只做测量与数值推荐，所有参数由你在游戏设置中手动填入。不读取游戏内存、不模拟触控、不与游戏进程交互。',
                        style: TextStyle(color: AppColors.dimText, fontSize: 12.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stepCard(
    BuildContext context, {
    required String step,
    required String title,
    required String desc,
    required IconData icon,
    String? trailing,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Card(
      child: ListTile(
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: enabled ? AppColors.primary : AppColors.dimText),
        ),
        title: Text('$step · $title', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentText)),
        subtitle: Text(desc, style: const TextStyle(color: AppColors.dimText, fontSize: 12.5)),
        trailing: trailing != null
            ? Text(trailing, style: const TextStyle(fontSize: 12))
            : const Icon(Icons.chevron_right, color: AppColors.dimText),
        onTap: onTap,
      ),
    );
  }
}
