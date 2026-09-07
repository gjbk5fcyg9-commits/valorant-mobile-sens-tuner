import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/sensitivity.dart' show PlayStyle;

/// 一次滑屏手势的统计特征。
@immutable
class SwipeSample {
  const SwipeSample({
    required this.distancePx,
    required this.durationMs,
    required this.peakSpeedPxPerSec,
    required this.avgSpeedPxPerSec,
  });

  final double distancePx;
  final double durationMs;
  final double peakSpeedPxPerSec;
  final double avgSpeedPxPerSec;

  /// 速度档位：基于与屏宽的关系归一化（不同手机屏宽不同，直接 px 不可比）。
  /// 此处用 avgSpeed/屏宽 得到 "每秒扫过几个屏宽" 的量纲。
  double normalizedSpeed(double screenWidthPx) => avgSpeedPxPerSec / screenWidthPx;

  Map<String, dynamic> toJson() => {
        'distancePx': distancePx,
        'durationMs': durationMs,
        'peakSpeedPxPerSec': peakSpeedPxPerSec,
        'avgSpeedPxPerSec': avgSpeedPxPerSec,
      };
}

/// 滑屏采样结果聚合。
@immutable
class SwipeProfile {
  const SwipeProfile({required this.samples, required this.screenWidthPx, required this.screenHeightPx});

  final List<SwipeSample> samples;
  final double screenWidthPx;
  final double screenHeightPx;

  bool get hasData => samples.length >= 3;

  /// 归一化平均速度中位数（每秒扫过屏宽）。
  double get medianNormSpeed {
    if (samples.isEmpty) return 0;
    final speeds = samples.map((s) => s.normalizedSpeed(screenWidthPx)).toList()..sort();
    return speeds[speeds.length ~/ 2];
  }

  double get avgNormSpeed {
    if (samples.isEmpty) return 0;
    return samples.map((s) => s.normalizedSpeed(screenWidthPx)).reduce((a, b) => a + b) / samples.length;
  }

  /// 稳定性：速度离散度越小越稳（CV = std/mean）。
  double get stabilityScore {
    if (samples.length < 2) return 1;
    final speeds = samples.map((s) => s.normalizedSpeed(screenWidthPx)).toList();
    final mean = speeds.reduce((a, b) => a + b) / speeds.length;
    if (mean == 0) return 1;
    final variance = speeds.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / speeds.length;
    final cv = math.sqrt(variance) / mean;
    return (1 - cv.clamp(0.0, 1.0));
  }

  /// 距离趋势：偏好大范围甩枪(>1) 还是小幅微调(<1)。
  double get distanceBias {
    if (samples.isEmpty) return 1;
    final dists = samples.map((s) => s.distancePx / screenWidthPx).toList();
    return dists.reduce((a, b) => a + b) / dists.length;
  }
}

/// 陀螺仪采样统计（转动手机的角速度特征，rad/s）。
@immutable
class GyroProfile {
  const GyroProfile({required this.samples, required this.axisSpeeds});

  /// 每段采样的总角速度峰值（rad/s）。
  final List<double> samples;
  final List<double> axisSpeeds; // x/y/z 各自平均角速度

  bool get hasData => samples.length >= 3;

  /// 平均峰值角速度：玩家转动手机的习惯力度。
  double get avgPeak {
    if (samples.isEmpty) return 0;
    return samples.reduce((a, b) => a + b) / samples.length;
  }

  /// 稳定性（越小越稳定）。
  double get stability {
    if (samples.length < 2) return 1;
    final mean = avgPeak;
    if (mean == 0) return 1;
    final variance = samples.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / samples.length;
    return (1 - (math.sqrt(variance) / mean)).clamp(0.0, 1.0);
  }
}

/// 校准/推荐结果状态。
enum CalibrationStage {
  notStarted('未校准'),
  swipeDone('滑屏已测'),
  gyroDone('陀螺仪已测'),
  complete('已推荐');

  const CalibrationStage(this.label);
  final String label;
}

/// 推荐引擎：把玩家操作特征映射到预设档位与微调系数。
class RecommendEngine {
  const RecommendEngine();

  /// 速度档位：每秒扫过屏宽数。
  /// <0.8 慢速精细 / 0.8~1.4 中速 / >1.4 快速甩枪。
  static String speedBand(double normSpeed) {
    if (normSpeed < 0.8) return 'slow';
    if (normSpeed > 1.4) return 'fast';
    return 'mid';
  }

  /// 由滑屏特征 + 玩家自评风格 -> 推荐一组灵敏度系数。
  ///
  /// 核心规则（可解释、可调参）：
  /// - 玩家滑得慢而稳 → 适合用较高滑屏灵敏度（弥补手速，镜头响应更快）
  /// - 玩家滑得快 → 推荐较低灵敏度（否则过度转向）
  /// - 手不稳（低稳定性）→ 略微降低灵敏度换取可控
  /// - 偏好大范围甩枪 → 轻微提高灵敏度
  /// - 风格激进/陀螺仪顺手 → 倾向开陀螺仪并给偏高陀螺仪值
  static ({double lookMult, double fireMult, double gyroMult, bool suggestGyro, String reason}) recommend({
    required SwipeProfile swipe,
    required GyroProfile? gyro,
    required PlayStyle style,
  }) {
    final spd = swipe.hasData ? swipe.avgNormSpeed : 1.0;
    final stab = swipe.hasData ? swipe.stabilityScore : 0.8;
    final dist = swipe.hasData ? swipe.distanceBias : 1.0;

    var lookMult = 1.0;
    switch (speedBand(spd)) {
      case 'slow':
        lookMult = 1.15; // 手慢，用更高灵敏度补
      case 'fast':
        lookMult = 0.85; // 手快，需降灵敏度防过度
      default:
        lookMult = 1.0;
    }
    if (stab < 0.5) lookMult *= 0.95; // 不稳定，略降
    if (dist > 1.4) lookMult *= 1.05; // 大甩枪
    if (dist < 0.6) lookMult *= 0.97; // 微调为主，略降

    // 开火灵敏度跟随滑屏，但更保守（防止开火时抖动）。
    var fireMult = 0.9 + (lookMult - 1.0) * 0.8;

    // 陀螺仪：风格 + 玩家转动幅度共同决定是否建议开启。
    var gyroMult = 1.0;
    var suggestGyro = true;
    final reasons = <String>[];
    if (gyro != null && gyro.hasData) {
      final peak = gyro.avgPeak;
      if (peak < 1.2) {
        gyroMult = 1.15; // 转得轻，需要更高陀螺仪灵敏度
      } else if (peak > 3.0) {
        gyroMult = 0.85; // 转得猛，低一点防抖
      }
      if (gyro.stability < 0.45) {
        gyroMult *= 0.9;
        reasons.add('你转手机时手有些抖，陀螺仪灵敏度已调低');
      } else {
        reasons.add('你的持机转动很稳定，适合陀螺仪微调');
      }
      suggestGyro = true;
    } else {
      // 未测陀螺仪：按风格给建议
      suggestGyro = style.gyroBias >= 0;
      if (!suggestGyro) reasons.add('稳架枪风格且未测陀螺仪，暂不建议开启');
    }

    lookMult = _clamp(lookMult, 0.6, 1.4);
    fireMult = _clamp(fireMult, 0.6, 1.3);
    gyroMult = _clamp(gyroMult, 0.6, 1.4);

    final reason = [
      switch (speedBand(spd)) {
        'slow' => '你的滑屏偏慢，推荐调高滑屏灵敏度以弥补手速',
        'fast' => '你滑屏速度很快，推荐调低灵敏度防止镜头过度转向',
        _ => '你的滑屏速度适中，保持均衡灵敏度即可',
      },
      if (stab < 0.5) '你滑屏稳定性一般，已略微降低数值换取可控',
      ...reasons,
    ].join('；');

    return (lookMult: lookMult, fireMult: fireMult, gyroMult: gyroMult, suggestGyro: suggestGyro, reason: reason);
  }

  static double _clamp(double v, double lo, double hi) => v.clamp(lo, hi);
}
