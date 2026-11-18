import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../data/presets.dart';
import '../models/sensitivity.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// 预设库：浏览内置方案 + 自定义预设（来自推荐保存），支持展开数值与复制。
class PresetsPage extends StatefulWidget {
  const PresetsPage({super.key});

  @override
  State<PresetsPage> createState() => _PresetsPageState();
}

class _PresetsPageState extends State<PresetsPage> {
  final Set<String> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final app = AppState.instance;
    return SafeArea(
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final customs = app.customPresets;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('预设方案库', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                '内置参考方案（公开社区数值整理）与你在推荐页保存的自定义方案。点击可展开完整数值，支持一键复制。',
                style: TextStyle(color: AppColors.dimText, height: 1.5, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('内置方案'),
              for (final p in builtinPresets) _presetCard(p, custom: false),
              const SizedBox(height: 10),
              const _SectionLabel('我的自定义方案'),
              if (customs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
                  child: const Center(
                    child: Text('暂无自定义方案\n去「校准」完成测量，在推荐页点"保存为自定义预设"',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.dimText, height: 1.6)),
                  ),
                )
              else
                for (final p in customs) _presetCard(p, custom: true),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _presetCard(SensPreset preset, {required bool custom}) {
    final isExpanded = _expanded.contains(preset.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() {
              if (isExpanded) {
                _expanded.remove(preset.id);
              } else {
                _expanded.add(preset.id);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: preset.isDefault ? AppColors.primary : AppColors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(preset.isDefault ? '推荐' : custom ? '自定义' : '参考',
                        style: TextStyle(color: preset.isDefault ? Colors.white : AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(preset.name, style: const TextStyle(color: AppColors.accentText, fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(preset.description, style: const TextStyle(color: AppColors.dimText, fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.dimText),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0x22333333)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                children: [
                  for (final fam in SensFamily.families) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(fam.label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                    for (final e in preset.values.entries.where((x) => x.key.family == fam))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text(e.key.label, style: const TextStyle(color: AppColors.accentText, fontSize: 12.5))),
                            Text('${e.value}', style: const TextStyle(color: AppColors.dimText, fontSize: 12.5, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                  if (preset.toggles.isNotEmpty)
                    for (final t in preset.toggles.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Expanded(child: Text(t.key.label, style: const TextStyle(color: AppColors.accentText, fontSize: 12.5))),
                            Text(t.value ? '开' : '关', style: const TextStyle(color: AppColors.dimText, fontSize: 12.5)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: preset.toChecklistText()));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制 ✓'), duration: Duration(seconds: 1)));
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('复制'),
                  ),
                  const Spacer(),
                  if (custom)
                    TextButton.icon(
                      onPressed: () async {
                        await AppState.instance.removeCustomPreset(preset.id);
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('删除'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.dimText),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: const TextStyle(color: AppColors.accentText, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5)),
    );
  }
}
