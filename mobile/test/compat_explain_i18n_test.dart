import 'package:flutter_test/flutter_test.dart';

import 'package:aetherride_mobile/domain/compatibility/rules.dart';
import 'package:aetherride_mobile/l10n/app_localizations_en.dart';
import 'package:aetherride_mobile/l10n/l10n_ext.dart';

void main() {
  test('compatExplain fills ARB fail templates from valuesA/B', () {
    final l10n = AppLocalizationsEn();
    const r = CompatibilityResult(
      verdict: CompatVerdict.incompatible,
      ruleCode: 'RL-DRV-011',
      title: 'Kassette benötigt passenden Freilaufkörper',
      severity: RuleSeverity.functional,
      explainDe: 'Die Kassette benötigt XD, deine Nabe hat Micro Spline.',
      valuesA: {'freehub_standard': 'XD'},
      valuesB: {'freehub_standard': 'Micro Spline'},
    );
    final out = l10n.compatExplain(r);
    expect(out, contains('XD'));
    expect(out, contains('Micro Spline'));
    expect(out, isNot(contains('Kassette benötigt')));
  });

  test('setup template ids map off German domain labels', () {
    final l10n = AppLocalizationsEn();
    expect(
      l10n.setupTemplateLabelFor('tpl-editorial-wet-roots'),
      'Editorial: wet roots',
    );
    expect(
      l10n.setupTemplateLabelFor('tpl-fox-oem-base'),
      isNot(contains('Gewichtstabelle')),
    );
  });
}
