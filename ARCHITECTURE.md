# 架构说明（Architecture）

## 总览

单模块 Flutter 应用，目录分层清晰：模型（models）→ 数据（data）→ 逻辑（logic）→ 状态（state）→ 页面（pages）。

```
┌─────────────────────────────────────────────┐
│  UI: pages/*（4 Tab + 2 详情页）             │
├─────────────────────────────────────────────┤
│  State: AppState (ChangeNotifier 单例)       │
│     - 持有测量结果 / 风格 / 自定义预设        │
├─────────────────────────────────────────────┤
│  Logic: calibration.dart                    │
│     - SwipeProfile/GyroProfile 统计特征       │
│     - RecommendEngine 规则推荐               │
├─────────────────────────────────────────────┤
│  Data: presets.dart(内置数值) store.dart(持久化)│
├─────────────────────────────────────────────┤
│  Models: sensitivity.dart（SensId 枚举域）    │
└─────────────────────────────────────────────┘
```

## 核心数据模型（lib/models/sensitivity.dart）

以「灵敏度三套体系 × 武器档位」为域模型：

- `SensFamily`: look / fire / gyro —— 滑屏 / 开火 / 陀螺仪
- `WeaponSlot`: hipfire / smg / rifle / lmg / sniper / operator / goldHunter
- `SensId`: 22 个具体设置项 = family × slot 的交叉（陀螺仪另有垂直/转向 2 项）
- `SensPreset`: 一套完整灵敏度方案（id + 名称 + 数值 map + 开关）
- `PlayStyle`: stable / balanced / aggressive —— 玩家风格，影响推荐倾向

## 校准与推荐流程

### 1. 滑屏采样（calibrate_page）

用 `Listener`（PointerDown/Move/Up）采集每次滑动的：
- `distancePx`：总位移
- `durationMs`：时长
- `peakSpeedPxPerSec`：帧间峰值速度
- `avgSpeedPxPerSec`：平均速度

过滤条件：位移 > 60px、时长 40–3000ms，避免误触。

### 2. 特征化（SwipeProfile）

- `medianNormSpeed` / `avgNormSpeed`：**归一化速度 = 平均速度 / 屏宽**（每秒扫过几个屏宽）——跨机型可比的核心量纲
- `stabilityScore`：速度离散度 CV 的倒数（越稳越接近 1）
- `distanceBias`：平均滑动距离 / 屏宽（大甩枪 vs 微调习惯）

### 3. 陀螺仪采样（可选）

`sensors_plus` 的 `gyroscopeEventStream` 订阅；长按按钮期间记录**峰值角速度**（rad/s），多次采样后聚合出 `GyroProfile`：
- `avgPeak`：平均峰值角速度（转动习惯力度）
- `stability`：峰值离散度（持机稳定度）

### 4. 推荐规则（RecommendEngine.recommend）

对滑屏/开火/陀螺仪各自输出一个**乘法系数**（±60% 范围），再乘到基准预设值上：

| 特征 | 规则 | 系数影响 |
|---|---|---|
| 手速慢（<0.8 屏宽/秒） | 高灵敏度弥补 | look ×1.15 |
| 手速快（>1.4） | 低灵敏度防过转 | look ×0.85 |
| 不稳定（稳定度 <0.5） | 降灵敏度换可控 | ×0.95 |
| 大甩枪（dist>1.4） | 略增 | ×1.05 |
| 陀螺仪转得轻 | 高陀螺仪灵敏度 | gyro ×1.15 |
| 陀螺仪转得猛 | 降防抖 | gyro ×0.85 |
| 陀螺仪不稳 | 再降 + 提示 | gyro ×0.9 |

开火灵敏度跟随滑屏但更保守（系数 = 0.9 + (look-1)×0.8）。

> 这些系数是启发式经验值，刻意集中在一个文件便于社区调参。欢迎提交测量数据驱动的改进 PR。

### 5. 输出

推荐页生成 `SensPreset`（可保存为自定义预设）与**纯文本清单**（复制 → 游戏内对照手动填入）。

## 数据流 / 持久化

- `AppState`（ChangeNotifier 单例）在首页 `initState` 里 `.init()` 一次性从 SharedPreferences 装载
- 采样完成即写盘（`Store.saveSwipe/saveGyro`）
- 自定义预设存 JSON 数组；内置预设（presets.dart）只读

## 测试策略

- `test/sensitivity_test.dart`：域模型完整性（枚举覆盖、可遍历）
- 推荐引擎为纯函数，便于日后加单测
- UI 层逻辑轻，通过 `flutter analyze` 静态保证

## 平台注意事项

- Android 不需要额外权限（陀螺仪普通传感器）
- iOS 需要 `NSMotionUsageDescription`（已写入 Info.plist，仅陀螺仪校准触发）
- iOS 无签名分发，仓库以源码 + Actions workflow 形式提供 iOS 构建
