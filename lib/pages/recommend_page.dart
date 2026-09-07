import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/presets.dart';
import '../logic/calibration.dart';
import '../models/sensitivity.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// 推荐页：基于校准结果生成整套灵敏度数值。
class RecommendPage extends StatefulWidget {
  const RecommendPage({super.key});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  late final AppState app = AppState.instance;

  late Map<SensId, int> _values;
  String _reason = '';
  bool _includeGyro = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    final swipe = app.swipe!;
    final gyro = app.gyro;
    final style = app.style ?? PlayStyle.balanced;

    final r = RecommendEngine.recommend(swipe: swipe, gyro: gyro, style: style);
    _includeGyro = r.suggestGyro;
    _reason = r.reason;

    // 以均衡预设为基准，应用缩放系数
    final base = defaultPreset.values;
    final out = <SensId, int>{};
    base.forEach((id, v) {
      final f = switch (id.family) {
        SensFamily.look => r.lookMult,
        SensFamily.fire => r.fireMult,
        SensFamily.gyro => r.gyroMult,
      };
      out[id] = (v * f).round();
    });
    _values = out;
  }

  @override
  Widget build(BuildContext context) {
    final gyroEnabled = _includeGyro && app.hasGyro;
    return Scaffold(
      appBar: AppBar(title: const Text('我的推荐灵敏度')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(),
          const SizedBox(height: 14),
          Text('推荐理由', style: _sectionStyle),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
            child: Text(_reason, style: const TextStyle(color: AppColors.accentText, height: 1.6, fontSize: 13.5)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('包含陀螺仪灵敏度', style: _sectionStyle),
              const Spacer(),
              Switch(
                value: gyroEnabled,
                onChanged: (v) => setState(() {
                  _includeGyro = v;
                  // 未测陀螺仪时保持关闭
                  if (!app.hasGyro) _includeGyro = false;
                }),
              ),
            ],
          ),
          _checklist(gyroEnabled),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(50)),
            onPressed: _copy,
            icon: const Icon(Icons.copy_all),
            label: const Text('复制灵敏度清单'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saveAsCustom,
            child: const Text('保存为自定义预设（可在预设页微调）'),
          ),
          const SizedBox(height: 8),
          Text(
            '操作提示：复制清单后，打开游戏 → 右上角齿轮 → 设置 → 操作/灵敏度设置，逐项填入。灵敏度设置需要一定的游戏体验后微调，建议先在训练场试枪。',
            style: const TextStyle(color: AppColors.dimText, fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  TextStyle get _sectionStyle => const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentText);

  Widget _hero() {
    final swipe = app.swipe!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.panel]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('你的操作画像', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.accentText)),
          const SizedBox(height: 8),
          _stat('手速', '${(swipe.avgNormSpeed).toStringAsFixed(2)} 屏宽/秒',
              RecommendEngine.speedBand(swipe.avgNormSpeed) == 'slow' ? '偏慢（推荐高灵敏度）' : RecommendEngine.speedBand(swipe.avgNormSpeed) == 'fast' ? '偏快（推荐低灵敏度）' : '适中'),
          _stat('稳定度', '${(swipe.stabilityScore * 100).toStringAsFixed(0)}%', '越大越稳'),
          if (app.gyro != null && app.gyro!.hasData)
            _stat('陀螺仪倾向', '峰值 ${app.gyro!.avgPeak.toStringAsFixed(1)} rad/s', '判断你是否适合陀螺仪'),
          const SizedBox(height: 4),
          Text('风格：${(app.style ?? PlayStyle.balanced).label}', style: const TextStyle(color: AppColors.dimText, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String hint) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(color: AppColors.dimText, fontSize: 13))),
          Text(value, style: const TextStyle(color: AppColors.accentText, fontWeight: FontWeight.w600, fontSize: 13.5)),
          const Spacer(),
          Text(hint, style: const TextStyle(color: AppColors.dimText, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _checklist(bool withGyro) {
    final values = _values.entries.where((e) => withGyro || e.key.family != SensFamily.gyro).toList();
    // 分组显示
    final groups = <SensFamily, List<MapEntry<SensId, int>>>{};
    for (final e in values) {
      groups.putIfAbsent(e.key.family, () => []).add(e);
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          for (final entry in groups.entries) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.primary.withValues(alpha: 0.14),
              child: Text(entry.key.label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accentText)),
            ),
            for (final e in entry.value)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key.label, style: const TextStyle(color: AppColors.accentText, fontSize: 13.5))),
                    Text('${e.value}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _copy() async {
    final text = _buildText();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制 ✓ 去游戏设置里粘贴对照填入吧'), duration: Duration(seconds: 2)));
  }

  String _buildText() {
    final buf = StringBuffer();
    buf.writeln('《无畏契约：源能行动》灵敏度推荐（${DateTime.now().month}月${DateTime.now().day}日测量）');
    buf.writeln('');
    final groups = <SensFamily, List<MapEntry<SensId, int>>>{};
    for (final e in _values.entries) {
      groups.putIfAbsent(e.key.family, () => []).add(e);
    }
    groups.forEach((fam, list) {
      if (fam == SensFamily.gyro && !_includeGyro) return;
      buf.writeln('【${fam.label}】');
      for (final e in list) {
        if (fam == SensFamily.gyro && !_includeGyro) continue;
        buf.writeln('  ${e.key.label}：${e.value}');
      }
      buf.writeln('');
    });
    buf.writeln('来源：本工具基于你的滑屏/陀螺仪测量自动生成，仅供参考，请在训练场体验后微调。');
    return buf.toString();
  }

  Future<void> _saveAsCustom() async {
    final preset = SensPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: '我的推荐 ${DateTime.now().month}/${DateTime.now().day}',
      description: '自动生成的个性化推荐${_includeGyro ? "（含陀螺仪）" : "（不含陀螺仪）"}',
      includeGyro: _includeGyro,
      values: _values,
      toggles: const {},
    );
    await app.addCustomPreset(preset);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到预设页 ✓'), duration: Duration(seconds: 2)));
  }
}
