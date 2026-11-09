import 'dart:math';
import 'package:beat_roulette/domain/generator.dart';
import 'package:beat_roulette/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tempo dentro del perfil y reglas compatibles en 1500 giros', () {
    final generator = Generator(Random(14));
    final r = {for (final item in restrictions) item.id: item.tags};
    final d = {for (final item in challenges) item.id: item.tags};
    const fixed = CustomRule(
      'fixed',
      RuleKind.condition,
      'Tempo fijo',
      tags: {'fixedTempo'},
    );
    for (var i = 0; i < 1500; i++) {
      final result = generator.generate(custom: [fixed]);
      final genre = genres.singleWhere((g) => g.id == result.genreId);
      expect(
        int.parse(result.label(Field.bpm)),
        inInclusiveRange(genre.min, genre.max),
      );
      expect(
        compatible({
          ...r[result.ruleIds[Field.restriction]]!,
          ...d[result.ruleIds[Field.challenge]]!,
          if (result.ruleIds[Field.condition] == 'fixed') ...fixed.tags,
        }),
        isTrue,
      );
      expect(
        result.limit,
        result.ruleIds[Field.challenge] == 'sprint' ? 20 : 30,
      );
    }
  });

  test('LoFi favorece escala menor y samples vintage', () {
    final generator = Generator(Random(42));
    final previous = Challenge('lofi', DateTime(2026), {}, 'lofi', {});
    var minor = 0;
    var major = 0;
    var vintage = 0;
    var synth = 0;
    for (var i = 0; i < 1200; i++) {
      final value = generator.generate(
        previous: previous,
        locks: {Field.genre},
      );
      expect(value.label(Field.genre), 'LoFi');
      expect(int.parse(value.label(Field.bpm)), inInclusiveRange(60, 90));
      if (value.label(Field.scale).endsWith('Minor')) minor++;
      if (value.label(Field.scale).endsWith('Major')) major++;
      if (value.ruleIds[Field.restriction] == 'vintage') vintage++;
      if (value.ruleIds[Field.restriction] == 'onesynth') synth++;
    }
    expect(minor, greaterThan(major));
    expect(vintage, greaterThan(synth));
  });

  test('mantiene campos fijados y serializa notas y favorito', () {
    final generator = Generator(Random(3));
    final previous = generator.generate();
    final result = generator.generate(
      previous: previous,
      locks: {Field.genre, Field.bpm, Field.scale, Field.restriction},
    );
    for (final field in {
      Field.genre,
      Field.bpm,
      Field.scale,
      Field.restriction,
    }) {
      expect(result.label(field), previous.label(field));
    }
    final snapshot = Challenge.fromMap(
      result.edit(notes: 'Probé una caja en mono', favorite: true).toMap(),
    );
    expect(snapshot.values, result.values);
    expect(snapshot.ruleIds, result.ruleIds);
    expect(snapshot.favorite, isTrue);
    expect(snapshot.notes, 'Probé una caja en mono');
  });

  test('valida reglas propias fijadas y sus conflictos', () {
    const custom = CustomRule(
      'custom-no-hats',
      RuleKind.restriction,
      'Sin hats',
      tags: {'noHats'},
    );
    final previous = Challenge('test', DateTime(2026), {}, 'trap', {
      Field.restriction: custom.id,
    });
    final generator = Generator(Random(5));
    for (var i = 0; i < 100; i++) {
      final value = generator.generate(
        previous: previous,
        locks: {Field.restriction},
        custom: [custom],
      );
      expect(value.label(Field.restriction), 'Sin hats');
      expect(value.ruleIds[Field.challenge], isNot('hat'));
    }
    expect(
      () => generator.generate(previous: previous, locks: {Field.restriction}),
      throwsStateError,
    );
  });
}
