import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:test/test.dart';

const _rules = [
  Rule(
    id: 1,
    ruleAction: RuleAction.DOMAIN_SUFFIX,
    content: 'youtube.com',
    ruleTarget: 'Streaming',
  ),
  Rule(
    id: 2,
    ruleAction: RuleAction.GEOIP,
    content: 'CN',
    ruleTarget: 'DIRECT',
  ),
  Rule(
    id: 3,
    ruleAction: RuleAction.RULE_SET,
    ruleProvider: 'ads',
    ruleTarget: 'REJECT',
  ),
];

void main() {
  group('Rule.matchQuery', () {
    test('matches the content', () {
      expect(_rules[0].matchQuery('youtube'), isTrue);
      expect(_rules[1].matchQuery('youtube'), isFalse);
    });

    test('matches the match type', () {
      expect(_rules[1].matchQuery('geoip'), isTrue);
      expect(_rules[0].matchQuery('geoip'), isFalse);
    });

    test('matches the target only in target mode', () {
      const target = RuleQueryField.target;
      expect(_rules[1].matchQuery('direct', field: target), isTrue);
      expect(_rules[2].matchQuery('reject', field: target), isTrue);
      expect(_rules[0].matchQuery('direct', field: target), isFalse);
    });

    test('each mode ignores the other column', () {
      // 'CN' is the content of a rule whose target is DIRECT.
      expect(_rules[1].matchQuery('direct'), isFalse);
      expect(
        _rules[1].matchQuery('CN', field: RuleQueryField.target),
        isFalse,
      );
    });

    test('matches the rule provider for a rule set', () {
      expect(_rules[2].matchQuery('ads'), isTrue);
    });

    test('ignores case and surrounding spaces', () {
      expect(_rules[0].matchQuery('  YouTube  '), isTrue);
    });

    test('an empty query matches everything', () {
      expect(_rules[0].matchQuery(''), isTrue);
      expect(_rules[0].matchQuery('   '), isTrue);
    });
  });

  group('List<Rule>.filterQuery', () {
    test('keeps only matching rules', () {
      expect(_rules.filterQuery('com').map((e) => e.id), [1]);
      expect(
        _rules
            .filterQuery('reject', field: RuleQueryField.target)
            .map((e) => e.id),
        [3],
      );
    });

    test('returns the list untouched for a blank query', () {
      expect(_rules.filterQuery('  '), same(_rules));
    });

    test('returns empty when nothing matches', () {
      expect(_rules.filterQuery('nothing-here'), isEmpty);
    });
  });

  group('List<Rule>.targets', () {
    test('collects the policies in use, sorted and deduplicated', () {
      expect(_rules.targets, ['DIRECT', 'REJECT', 'Streaming']);
    });

    test('skips rules without a target', () {
      const rules = [Rule(id: 1, ruleAction: RuleAction.MATCH)];
      expect(rules.targets, isEmpty);
    });
  });
}
