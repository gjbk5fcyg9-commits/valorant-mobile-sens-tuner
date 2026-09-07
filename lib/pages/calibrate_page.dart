import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../logic/calibration.dart';
import '../models/sensitivity.dart';
import '../state/app_state.dart';
import '../theme.dart' show AppColors;
import 'recommend_page.dart';

/// 校准页：滑屏采样 + 陀螺仪采样 + 风格选择。
class CalibratePage extends StatefulWidget {
  const CalibratePage({super.key});

  @override
  State<CalibratePage> createState() => _CalibratePageState();
}

class _CalibratePageState extends State<CalibratePage> {
  final _swipe = <SwipeSample>[];
  bool _recording = false;

  final _gyroPeaks = <double>[];
  final _axis = <double>[0, 0, 0];
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _segPeak = 0;
  bool _gyroActive = false;

  static const targetSamples = 6;

  @override
  void initState() {
    super.initState();
    _restoreFromState();
  }

  void _restoreFromState() {
    final s = AppState.instance;
    _swipe.clear();
    final sp = s.swipe;
    if (sp != null) {
      _swipe.addAll(sp.samples);
    }
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    super.dispose();
  }

  // ---------------- 滑屏采样 ----------------

  void _onPointerDown(PointerDownEvent e) {
    if (_recording || _swipe.length >= targetSamples) return;
    _recording = true;
    _lastPos = e.localPosition;
    _lastTime = e.timeStamp;
    _segDist = 0;
    _peakSpeed = 0;
  }

  Offset _lastPos = Offset.zero;
  Duration _lastTime = Duration.zero;
  double _segDist = 0;
  double _peakSpeed = 0;

  void _onPointerMove(PointerMoveEvent e) {
    if (!_recording) return;
    final dt = e.timeStamp - _lastTime;
    final d = (e.localPosition - _lastPos).distance;
    if (dt.inMilliseconds >= 16 && dt.inMilliseconds > 0) {
      final v = d / dt.inMilliseconds * 1000; // px/s
      if (v > _peakSpeed) _peakSpeed = v;
    }
    _segDist += d;
    _lastPos = e.localPosition;
    _lastTime = e.timeStamp;
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_recording) return;
    _recording = false;
    final duration = (e.timeStamp - _lastTime).inMilliseconds.toDouble().clamp(30.0, 5000.0).toDouble();
    final speed = _segDist / math.max(duration, 1.0) * 1000; // avg px/s
    // 太短/太慢的滑动不算有效
    if (_segDist > 60 && duration > 40 && duration < 3000) {
      setState(() {
        _swipe.add(SwipeSample(
          distancePx: _segDist,
          durationMs: duration,
          peakSpeedPxPerSec: _peakSpeed,
          avgSpeedPxPerSec: speed,
        ));
      });
      if (_swipe.length >= targetSamples) _commitSwipe();
    }
  }

  Future<void> _commitSwipe() async {
    final size = MediaQuery.of(context).size;
    await AppState.instance.setSwipe(SwipeProfile(samples: List.of(_swipe), screenWidthPx: size.width, screenHeightPx: size.height));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('滑屏采样完成 ✓'), duration: Duration(seconds: 1)));
  }

  void _resetSwipe() {
    setState(_swipe.clear);
  }

  // ---------------- 陀螺仪采样 ----------------

  Future<void> _gyroStart() async {
    _gyroPeaks.clear();
    _axis
      ..clear()
      ..addAll([0, 0, 0]);
    _segPeak = 0;
    setState(() => _gyroActive = true);
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval).listen((e) {
      if (!_gyroActive) return;
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      if (mag > _segPeak) _segPeak = mag;
      _axis[0] = math.max(_axis[0], e.x.abs());
      _axis[1] = math.max(_axis[1], e.y.abs());
      _axis[2] = math.max(_axis[2], e.z.abs());
    });
  }

  void _gyroEnd() {
    if (!_gyroActive) return;
    _gyroActive = false;
    if (_segPeak > 0.05) {
      setState(() => _gyroPeaks.add(_segPeak));
    }
    _segPeak = 0;
    if (_gyroPeaks.length >= targetSamples) {
      AppState.instance.setGyro(GyroProfile(samples: List.of(_gyroPeaks), axisSpeeds: List.of(_axis)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('陀螺仪采样完成 ✓'), duration: Duration(seconds: 1)));
      }
    }
  }

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
              _header(),
              const SizedBox(height: 16),
              _swipeCard(),
              const SizedBox(height: 12),
              _gyroCard(),
              const SizedBox(height: 12),
              _styleCard(),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(52)),
                onPressed: app.readyToRecommend ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecommendPage())) : null,
                icon: const Icon(Icons.auto_awesome),
                label: Text(app.readyToRecommend ? '生成我的灵敏度推荐' : '完成测量并选择风格后可生成推荐'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    final app = AppState.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('校准测量', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(
          '按你的自然操作习惯做几次滑动与转动，我们据此计算适合你的灵敏度。\n'
          '${app.hasSwipe ? "● 滑屏已测" : "○ 滑屏未测"}　${app.hasGyro ? "● 陀螺仪已测" : "○ 陀螺仪可选"}　${app.style != null ? "● 风格已选" : "○ 风格未选"}',
          style: const TextStyle(color: AppColors.dimText, height: 1.5),
        ),
      ],
    );
  }

  Widget _swipeCard() {
    final done = _swipe.length >= targetSamples;
    return _card(
      title: '① 滑屏速度测试',
      subtitle: '在下方区域像游戏里转视角那样快速左右滑动，连续 ${targetSamples - _swipe.length} 次（越多越准）。',
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {},
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              child: Container(
                height: 170,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.panel.withValues(alpha: 0.4), AppColors.darkBg]),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.6), width: 1.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swipe, size: 42, color: AppColors.primary),
                    const SizedBox(height: 8),
                    const Text('在此区域快速滑动（可横屏操作）', style: TextStyle(color: AppColors.accentText)),
                    const SizedBox(height: 6),
                    Text('已采集 $_swipeLengthSamples / $targetSamples 次', style: const TextStyle(color: AppColors.dimText)),
                    if (done) const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('✓ 完成，已自动保存', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton(onPressed: _swipe.isEmpty ? null : _resetSwipe, child: const Text('重新测量')),
              const Spacer(),
              if (done) TextButton(onPressed: _swipeCardStats, child: const Text('查看测量数据')),
            ],
          ),
        ],
      ),
    );
  }

  int get _swipeLengthSamples => _swipe.length;

  void _swipeCardStats() {
    final p = AppState.instance.swipe;
    if (p == null || p.samples.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('滑屏测量数据'),
        content: Text(
          '平均速度：每秒扫过屏宽 ${p.avgNormSpeed.toStringAsFixed(2)}×\n'
          '稳定度：${(p.stabilityScore * 100).toStringAsFixed(0)}%\n'
          '平均滑动距离：屏宽 ${p.distanceBias.toStringAsFixed(2)}×\n\n'
          '手速越快，推荐灵敏度越低；手越稳，越适合陀螺仪。',
          style: const TextStyle(height: 1.7),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('好'))],
      ),
    );
  }

  Widget _gyroCard() {
    return _card(
      title: '② 陀螺仪转动测试（可选）',
      subtitle: '想连陀螺仪灵敏度一起调，就按住按钮像游戏中转动手机那样匀速摆动手腕，共 $targetSamples 段。',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => _gyroStart(),
                  onTapUp: (_) => _gyroEnd(),
                  onTapCancel: _gyroEnd,
                  child: Container(
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _gyroActive ? AppColors.primary : AppColors.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _gyroActive ? '采集中… 保持转动' : '按住并转动手腕（长按 1~2 秒）',
                      style: const TextStyle(color: AppColors.accentText, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('已采集 ${_gyroPeaks.length} / $targetSamples 段', style: const TextStyle(color: AppColors.dimText, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _styleCard() {
    return _card(
      title: '③ 你的操作风格',
      subtitle: '影响推荐倾向（是否建议开陀螺仪、数值偏保守或激进）。',
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            children: PlayStyle.values.map((s) {
              final sel = AppState.instance.style == s;
              return ChoiceChip(
                label: Text('${s.label} · ${s.description}'),
                selected: sel,
                onSelected: (_) => AppState.instance.setStyle(s),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.panel,
                side: BorderSide(color: sel ? AppColors.primary : AppColors.panel, width: 1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required String subtitle, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.accentText)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.dimText, fontSize: 12.5, height: 1.4)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
