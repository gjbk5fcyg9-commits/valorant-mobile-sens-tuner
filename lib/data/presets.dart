import '../models/sensitivity.dart';

/// 内置预设库（社区公开推荐数值的整理版）。
///
/// 数值来源：
/// - 7724 游戏网 2025-08-19《无畏契约手游灵敏度推荐》
///   http://m.7724.com/syzx/news/194865.html （滑屏/开火/陀螺仪三套数值）
/// - 公开攻略对"镜头转向模式=固定速度、转向辅助=开"的建议
///
/// 覆盖度说明：攻略帖未给出滑屏侧的一些武器细分档（如滑屏·冲锋枪/机枪开镜），
/// 此处按同档位"步枪开镜"比例外推补齐；数值仅供参考，可在 App 内自调。

const toggleTurnMode = ToggleSetting('镜头转向模式=固定速度', true, '固定速度更利于压枪与预瞄');
const toggleTurnAssist = ToggleSetting('转向辅助', true, '开启后转向更跟手');
const toggleGyroAssist = ToggleSetting('陀螺仪辅助瞄准', true, '轻微跟枪辅助');

/// 预设 A：稳健型（默认，社区推荐居中档）
const defaultPreset = SensPreset(
  id: 'balanced',
  name: '均衡·社区推荐',
  description: '适合多数玩家的起步方案，源自公开攻略推荐数值',
  values: {
    SensId.lookHip: 82,
    SensId.lookSmg: 68,
    SensId.lookRifle: 64,
    SensId.lookLmg: 68,
    SensId.lookSniper: 32,
    SensId.lookOperator: 20,
    SensId.lookGoldHunter: 54,
    SensId.fireHip: 80,
    SensId.fireSmg: 68,
    SensId.fireRifle: 64,
    SensId.fireLmg: 68,
    SensId.fireSniper: 35,
    SensId.fireOperator: 18,
    SensId.fireGoldHunter: 54,
    SensId.gyroVertical: 90,
    SensId.gyroLook: 180,
    SensId.gyroSmg: 82,
    SensId.gyroRifle: 76,
    SensId.gyroLmg: 82,
    SensId.gyroSniper: 78,
    SensId.gyroOperator: 22,
    SensId.gyroGoldHunter: 66,
  },
  toggles: {toggleTurnMode: true, toggleTurnAssist: true, toggleGyroAssist: true},
  isDefault: true,
);

/// 预设 B：职业选手级（略激进，适合跟枪/步枪手，源自社区"职业选手向"档）
const proPreset = SensPreset(
  id: 'pro',
  name: '激进·职业向',
  description: '适合跟枪、扫射、步枪手风格的高灵敏度方案',
  values: {
    SensId.lookHip: 100,
    SensId.lookSmg: 80,
    SensId.lookRifle: 76,
    SensId.lookLmg: 80,
    SensId.lookSniper: 40,
    SensId.lookOperator: 26,
    SensId.lookGoldHunter: 62,
    SensId.fireHip: 96,
    SensId.fireSmg: 78,
    SensId.fireRifle: 74,
    SensId.fireLmg: 78,
    SensId.fireSniper: 42,
    SensId.fireOperator: 24,
    SensId.fireGoldHunter: 62,
    SensId.gyroVertical: 100,
    SensId.gyroLook: 220,
    SensId.gyroSmg: 90,
    SensId.gyroRifle: 84,
    SensId.gyroLmg: 90,
    SensId.gyroSniper: 84,
    SensId.gyroOperator: 28,
    SensId.gyroGoldHunter: 72,
  },
  toggles: {toggleTurnMode: true, toggleTurnAssist: true, toggleGyroAssist: true},
);

/// 预设 C：稳健狙手型（低灵敏度，适合架枪、狙击）
const sniperPreset = SensPreset(
  id: 'sniper',
  name: '稳架·狙手型',
  description: '低灵敏度高稳定，适合狙击与架点玩家',
  values: {
    SensId.lookHip: 60,
    SensId.lookSmg: 50,
    SensId.lookRifle: 48,
    SensId.lookLmg: 50,
    SensId.lookSniper: 20,
    SensId.lookOperator: 12,
    SensId.lookGoldHunter: 30,
    SensId.fireHip: 60,
    SensId.fireSmg: 50,
    SensId.fireRifle: 48,
    SensId.fireLmg: 50,
    SensId.fireSniper: 20,
    SensId.fireOperator: 12,
    SensId.fireGoldHunter: 30,
    SensId.gyroVertical: 60,
    SensId.gyroLook: 120,
    SensId.gyroSmg: 60,
    SensId.gyroRifle: 56,
    SensId.gyroLmg: 60,
    SensId.gyroSniper: 50,
    SensId.gyroOperator: 14,
    SensId.gyroGoldHunter: 40,
  },
  toggles: {toggleTurnMode: true, toggleTurnAssist: true, toggleGyroAssist: false},
);

/// 全部内置预设。
const List<SensPreset> builtinPresets = [defaultPreset, proPreset, sniperPreset];
