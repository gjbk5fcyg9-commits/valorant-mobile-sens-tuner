import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// 说明页：玩法介绍 + 灵敏度科普 + 合规声明。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('使用说明', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const _Section('这套工具怎么用', [
            '1. 去「校准」页，在滑动区像游戏里转视角那样划 6 次；',
            '2. 想连陀螺仪灵敏度一起调就按住按钮转动手腕 6 段（可选）；',
            '3. 选一个接近你打法的风格；',
            '4. 点「生成我的灵敏度推荐」，复制清单；',
            '5. 打开游戏：设置 → 操作设置，逐项对照填入；',
            '6. 进训练场打几梭子，回推荐页按手感用「自定义微调」校准一次，越用越准。',
          ]),
          const _Section('灵敏度到底怎么理解', [
            '滑屏灵敏度：手指划过的距离映射到镜头转动的角度。越高越"跟手"，但高过头会因手指抖动导致准星乱跳。',
            '开火灵敏度：按住开火时镜头的灵敏度，一般比滑屏低，帮助压枪不抖。',
            '陀螺仪灵敏度：转动手机带动镜头。手机物理转动精度远高于手指，跟枪更细腻，适合玩久了形成"手碗协同"的玩家。',
            '没有唯一正确的灵敏度，只有"适合你手部习惯的灵敏度"——这正是本工具测量并推荐的依据。',
          ]),
          const _Section('数据与隐私', [
            '所有测量数据仅保存在手机本地（SharedPreferences），不上传任何服务器，无需联网。',
            '校准数据只在本机用于计算推荐，可随时在系统设置里清除应用数据。',
          ]),
          const _Section('合规声明', [
            '本工具是灵敏度数值计算器：测量你的操作习惯 → 输出一套可手动填入游戏设置的数值清单。',
            '它不读取游戏内存、不注入代码、不模拟触控、不修改任何游戏文件，不与被测游戏进程发生任何交互。',
            '请在游戏官方允许的范围内使用；游戏内最终以实际设置为准，数值因人而异仅供参考。',
          ]),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              '灵敏度调校助手 v1.0.0\n开源项目 · 与 Riot Games / 腾讯无隶属关系',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dimText, fontSize: 12, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.lines);
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.accentText, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(line, style: const TextStyle(color: AppColors.dimText, fontSize: 13, height: 1.55)),
            ),
        ],
      ),
    );
  }
}
