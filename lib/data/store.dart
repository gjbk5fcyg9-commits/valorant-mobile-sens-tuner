import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logic/calibration.dart';
import '../models/sensitivity.dart';

/// 本地存储：校准结果 + 用户自定义预设。
class Store {
  static const _kSwipe = 'swipe_samples_v1';
  static const _kScreenW = 'screen_w_v1';
  static const _kScreenH = 'screen_h_v1';
  static const _kGyro = 'gyro_samples_v1';
  static const _kStyle = 'play_style_v1';
  static const _kLastRecommend = 'last_recommend_v1';
  static const _kCustomPresets = 'custom_presets_v1';

  static Future<SwipeProfile?> loadSwipe() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kSwipe);
    if (raw == null) return null;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final samples = list
          .map((e) => SwipeSample(
                distancePx: (e['distancePx'] as num).toDouble(),
                durationMs: (e['durationMs'] as num).toDouble(),
                peakSpeedPxPerSec: (e['peakSpeedPxPerSec'] as num).toDouble(),
                avgSpeedPxPerSec: (e['avgSpeedPxPerSec'] as num).toDouble(),
              ))
          .toList();
      return SwipeProfile(samples: samples, screenWidthPx: p.getDouble(_kScreenW) ?? 1, screenHeightPx: p.getDouble(_kScreenH) ?? 1);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSwipe(SwipeProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSwipe, jsonEncode(profile.samples.map((s) => s.toJson()).toList()));
    await p.setDouble(_kScreenW, profile.screenWidthPx);
    await p.setDouble(_kScreenH, profile.screenHeightPx);
  }

  static Future<GyroProfile?> loadGyro() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kGyro);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GyroProfile(
        samples: (map['samples'] as List).cast<num>().map((e) => e.toDouble()).toList(),
        axisSpeeds: (map['axis'] as List).cast<num>().map((e) => e.toDouble()).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveGyro(GyroProfile profile) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kGyro, jsonEncode({'samples': profile.samples, 'axis': profile.axisSpeeds}));
  }

  static Future<PlayStyle?> loadStyle() async {
    final p = await SharedPreferences.getInstance();
    final idx = p.getInt(_kStyle);
    if (idx == null) return null;
    return PlayStyle.values.elementAtOrNull(idx);
  }

  static Future<void> saveStyle(PlayStyle style) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kStyle, style.index);
  }

  static Future<Map<PlayStyle, String>?> loadLastRecommend() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kLastRecommend);
    if (raw == null) return null;
    try {
      final map = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(PlayStyle.values[int.parse(k)], v as String));
      return map;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveLastRecommend(Map<PlayStyle, String> reason) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastRecommend, jsonEncode(reason.map((k, v) => MapEntry(k.index.toString(), v))));
  }

  static Future<List<SensPreset>> loadCustomPresets() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_kCustomPresets);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(_presetFromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomPresets(List<SensPreset> presets) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCustomPresets, jsonEncode(presets.map(_presetToJson).toList()));
  }

  static Map<String, dynamic> _presetToJson(SensPreset preset) => {
        'id': preset.id,
        'name': preset.name,
        'description': preset.description,
        'includeGyro': preset.includeGyro,
        'values': preset.values.map((k, v) => MapEntry(k.index.toString(), v)),
        'toggles': preset.toggles.map((k, v) => MapEntry(k.label, v)),
      };

  static SensPreset _presetFromJson(Map<String, dynamic> json) {
    final values = <SensId, int>{};
    (json['values'] as Map<String, dynamic>).forEach((k, v) {
      final id = SensId.values.elementAtOrNull(int.parse(k));
      if (id != null) values[id] = v as int;
    });
    return SensPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      includeGyro: (json['includeGyro'] as bool?) ?? true,
      values: values,
      toggles: const {},
    );
  }
}
