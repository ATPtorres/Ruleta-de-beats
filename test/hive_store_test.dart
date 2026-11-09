import 'dart:io';
import 'dart:math';
import 'package:beat_roulette/data/hive_store.dart';
import 'package:beat_roulette/domain/generator.dart';
import 'package:beat_roulette/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('Hive conserva reto, notas, favoritos y reglas al reabrir', () async {
    final path = await Directory.systemTemp.createTemp('beat_roulette_test_');
    addTearDown(() async {
      await Hive.close();
      await path.delete(recursive: true);
    });
    Hive.init(path.path);
    Future<HiveStore> open() async => HiveStore(
      await Hive.openBox<Map>('history_v1'),
      await Hive.openBox<Map>('rules_v1'),
      await Hive.openBox<Map>('settings_v1'),
    );
    final store = await open();
    final result = Generator(Random(11)).generate();
    await store.saveChallenge(
      result.edit(notes: 'Dejar respirar el bajo', favorite: true),
    );
    await store.saveRule(
      const CustomRule('custom', RuleKind.genre, 'Darkwave', min: 95, max: 125),
    );
    await store.saveTimer(45, true);
    await Hive.close();
    final reopened = await open();
    expect(reopened.history.single.values, result.values);
    expect(reopened.history.single.notes, 'Dejar respirar el bajo');
    expect(reopened.history.single.favorite, isTrue);
    expect(reopened.rules.single.min, 95);
    expect(reopened.timerMinutes, 45);
    expect(reopened.keepScreenOn, isTrue);
  });
}
