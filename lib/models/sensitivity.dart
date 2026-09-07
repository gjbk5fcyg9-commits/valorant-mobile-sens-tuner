/// 灵敏度参数体系数据模型
///
/// 依据《无畏契约：源能行动》实际设置体系建模（调研报告第二节）：
/// 灵敏度 = 滑屏(镜头转向)灵敏度 + 开火灵敏度 + 陀螺仪灵敏度 三套并行，
/// 每套内部按「常规腰射 / 各武器开镜」细分，狙击枪(冥驹)另有二段开镜。
/// 数值范围未获官方出处，按社区实测帖取值，全部参数均为 int。
library;

/// 武器 / 场景档位。
enum WeaponSlot {
  hipfire('腰射', '不开镜直接射击'),
  smg('冲锋枪开镜', '冲锋枪类'),
  rifle('步枪开镜', '步枪/突击类'),
  lmg('机枪开镜', '机枪类'),
  sniper('狙击枪开镜', '狙击枪(不含冥驹)'),
  operator('冥驹二段开镜', '冥驹(狙击枪)开镜后再次开镜'),
  goldHunter('金牌猎头开镜', '金牌猎头类武器');

  const WeaponSlot(this.label, this.description);
  final String label;
  final String description;
}

/// 灵敏度体系（三套并行）。
enum SensFamily {
  look('滑屏灵敏度', '手指在屏幕滑动转动镜头的速度'),
  fire('开火灵敏度', '开火状态下的镜头灵敏度'),
  gyro('陀螺仪灵敏度', '转动手机带动镜头的灵敏度');

  const SensFamily(this.label, this.description);
  final String label;
  final String description;

  static const List<SensFamily> families = [SensFamily.look, SensFamily.fire, SensFamily.gyro];
}

/// 灵敏度分类：family × slot 组合。
enum SensId {
  lookHip('滑屏·腰射', SensFamily.look, WeaponSlot.hipfire),
  lookSmg('滑屏·冲锋枪开镜', SensFamily.look, WeaponSlot.smg),
  lookRifle('滑屏·步枪开镜', SensFamily.look, WeaponSlot.rifle),
  lookLmg('滑屏·机枪开镜', SensFamily.look, WeaponSlot.lmg),
  lookSniper('滑屏·狙击枪开镜', SensFamily.look, WeaponSlot.sniper),
  lookOperator('滑屏·冥驹二段开镜', SensFamily.look, WeaponSlot.operator),
  lookGoldHunter('滑屏·金牌猎头开镜', SensFamily.look, WeaponSlot.goldHunter),
  fireHip('开火·腰射', SensFamily.fire, WeaponSlot.hipfire),
  fireSmg('开火·冲锋枪开镜', SensFamily.fire, WeaponSlot.smg),
  fireRifle('开火·步枪开镜', SensFamily.fire, WeaponSlot.rifle),
  fireLmg('开火·机枪开镜', SensFamily.fire, WeaponSlot.lmg),
  fireSniper('开火·狙击枪开镜', SensFamily.fire, WeaponSlot.sniper),
  fireOperator('开火·冥驹二段开镜', SensFamily.fire, WeaponSlot.operator),
  fireGoldHunter('开火·金牌猎头开镜', SensFamily.fire, WeaponSlot.goldHunter),
  gyroVertical('陀螺仪·垂直灵敏度', SensFamily.gyro, null),
  gyroLook('陀螺仪·转向灵敏度', SensFamily.gyro, null),
  gyroSmg('陀螺仪·冲锋枪开镜', SensFamily.gyro, WeaponSlot.smg),
  gyroRifle('陀螺仪·步枪开镜', SensFamily.gyro, WeaponSlot.rifle),
  gyroLmg('陀螺仪·机枪开镜', SensFamily.gyro, WeaponSlot.lmg),
  gyroSniper('陀螺仪·狙击枪开镜', SensFamily.gyro, WeaponSlot.sniper),
  gyroOperator('陀螺仪·冥驹二段开镜', SensFamily.gyro, WeaponSlot.operator),
  gyroGoldHunter('陀螺仪·金牌猎头开镜', SensFamily.gyro, WeaponSlot.goldHunter);

  const SensId(this.label, this.family, this.slot);
  final String label;
  final SensFamily family;
  final WeaponSlot? slot;

  static const List<SensId> valuesByFamily = [
    lookHip, lookSmg, lookRifle, lookLmg, lookSniper, lookOperator, lookGoldHunter,
    fireHip, fireSmg, fireRifle, fireLmg, fireSniper, fireOperator, fireGoldHunter,
    gyroVertical, gyroLook, gyroSmg, gyroRifle, gyroLmg, gyroSniper, gyroOperator,
    gyroGoldHunter,
  ];
}

/// 游戏全局开关项（灵敏度之外的辅助项，推荐一并给出）。
class ToggleSetting {
  const ToggleSetting(this.label, this.defaultValue, this.note);
  final String label;
  final bool defaultValue;
  final String note;
}

/// 一套完整灵敏度配置 = 每个 SensId 一个数值 + 全局开关。
/// 注意：作为不可变值使用（const 构建），调用方不应修改内部 map。
class SensPreset {
  const SensPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.values,
    this.toggles = const {},
    this.isDefault = false,
    this.includeGyro = true,
  });

  final String id; // 唯一标识，用于本地存储
  final String name;
  final String description;
  final Map<SensId, int> values; // 未包含的 SensId 视为不推荐/不设置
  final Map<ToggleSetting, bool> toggles;
  final bool isDefault;
  final bool includeGyro; // 陀螺仪是否参与本预设（用户可自主决定要不要一起调）

  /// 生成一份可直接对照填写游戏的文本清单。
  String toChecklistText({bool withGyro = true}) {
    final buf = StringBuffer();
    buf.writeln('■ $name');
    buf.writeln('──────────────────');
    for (final family in SensFamily.families) {
      if (family == SensFamily.gyro && !withGyro) continue;
      buf.writeln('【${family.label}】');
      for (final e in values.entries) {
        if (e.key.family == family && (family != SensFamily.gyro || withGyro)) {
          buf.writeln('  ${e.key.label}：${e.value}');
        }
      }
      buf.writeln('');
    }
    if (toggles.isNotEmpty) {
      buf.writeln('【其他开关】');
      toggles.forEach((k, v) => buf.writeln('  ${k.label}：${v ? '开' : '关'}'));
    }
    return buf.toString();
  }
}

/// 数值约束（用于 UI 滑块与校验）。范围来自社区实测帖的合理区间。
class SensRange {
  const SensRange(this.min, this.max, this.step);
  final int min;
  final int max;
  final int step;
}

/// 预置的方案风格说明，用于推荐页展示理由。
enum PlayStyle {
  stable('稳架枪', '擅长预瞄与架点，追求镜头稳定', 1),
  balanced('均衡', '架枪与拉枪并重，万金油', 0),
  aggressive('激进跟枪', '喜欢跟枪扫射与快速甩枪', 1);

  const PlayStyle(this.label, this.description, this.gyroBias);
  final String label;
  final String description;

  /// 风格对陀螺仪的偏好系数：>0 更倾向开陀螺仪。
  final int gyroBias;
}
