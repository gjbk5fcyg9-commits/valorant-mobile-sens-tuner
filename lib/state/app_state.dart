import 'package:flutter/foundation.dart';

import '../data/store.dart';
import '../logic/calibration.dart';
import '../models/sensitivity.dart';

/// 全局应用状态（首页/校准页/预设页共享）。
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  SwipeProfile? _swipe;
  GyroProfile? _gyro;
  PlayStyle? _style;
  List<SensPreset> _custom = [];
  bool _loaded = false;

  SwipeProfile? get swipe => _swipe;
  GyroProfile? get gyro => _gyro;
  PlayStyle? get style => _style;
  List<SensPreset> get customPresets => List.unmodifiable(_custom);
  bool get loaded => _loaded;

  bool get hasSwipe => _swipe?.hasData ?? false;
  bool get hasGyro => _gyro?.hasData ?? false;
  bool get readyToRecommend => hasSwipe && _style != null;

  Future<void> init() async {
    if (_loaded) return;
    _swipe = await Store.loadSwipe();
    _gyro = await Store.loadGyro();
    _style = await Store.loadStyle();
    _custom = await Store.loadCustomPresets();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSwipe(SwipeProfile p) async {
    _swipe = p;
    await Store.saveSwipe(p);
    notifyListeners();
  }

  Future<void> setGyro(GyroProfile p) async {
    _gyro = p;
    await Store.saveGyro(p);
    notifyListeners();
  }

  Future<void> setStyle(PlayStyle s) async {
    _style = s;
    await Store.saveStyle(s);
    notifyListeners();
  }

  Future<void> addCustomPreset(SensPreset preset) async {
    _custom = [..._custom, preset];
    await Store.saveCustomPresets(_custom);
    notifyListeners();
  }

  Future<void> removeCustomPreset(String id) async {
    _custom = _custom.where((p) => p.id != id).toList();
    await Store.saveCustomPresets(_custom);
    notifyListeners();
  }
}
