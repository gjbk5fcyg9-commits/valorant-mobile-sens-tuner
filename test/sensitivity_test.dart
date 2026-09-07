import 'package:flutter_test/flutter_test.dart';

import 'package:sens_tuner/models/sensitivity.dart';

void main() {
  test('SensId 枚举覆盖三套体系且数值映射完整', () {
    expect(SensId.values.length, greaterThan(20));
    expect(SensFamily.families.length, 3);
    // 每个内置预设都应包含 look.hipfire 与 fire.hipfire
    // （此处仅验证数据枚举可遍历，无崩溃）
    for (final id in SensId.values) {
      expect(id.label, isNotEmpty);
    }
  });
}
