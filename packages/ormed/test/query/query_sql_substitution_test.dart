import 'package:ormed/ormed.dart';
import 'package:test/test.dart';

void main() {
  group('QueryGrammar substituteBindingsIntoRawSql', () {
    const grammar = _PreviewGrammar();

    test('escapes values and replaces placeholders', () {
      final sql =
          "SELECT * FROM users WHERE id = ? AND name = ? AND active = ?";
      final rendered = grammar.substituteBindingsIntoRawSql(sql, [
        42,
        "O'Connor",
        true,
      ]);
      expect(
        rendered,
        "SELECT * FROM users WHERE id = 42 AND name = 'O''Connor' AND active = 1",
      );
    });

    test('ignores placeholders inside string literals', () {
      const sql = "SELECT '?' AS literal, ? AS value";
      final rendered = grammar.substituteBindingsIntoRawSql(sql, [7]);
      expect(rendered, "SELECT '?' AS literal, 7 AS value");
    });
  });
}

class _PreviewGrammar extends QueryGrammar {
  const _PreviewGrammar();
}
