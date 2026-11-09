import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models.dart';

class HiveStore implements BeatStore {
  HiveStore(this._history, this._rules, this._settings);
  final Box<Map> _history, _rules, _settings;

  static Future<HiveStore> open() async {
    await Hive.initFlutter();
    final boxes = await Future.wait([
      Hive.openBox<Map>('history_v1'),
      Hive.openBox<Map>('rules_v1'),
      Hive.openBox<Map>('settings_v1'),
    ]);
    return HiveStore(boxes[0], boxes[1], boxes[2]);
  }

  @override
  List<Challenge> get history =>
      _history.values.map(Challenge.fromMap).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  @override
  List<CustomRule> get rules => _rules.values.map(CustomRule.fromMap).toList();
  @override
  int get timerMinutes => _settings.get('timer')?['minutes'] as int? ?? 30;
  @override
  bool get keepScreenOn => _settings.get('timer')?['screen'] as bool? ?? false;
  @override
  Future<void> saveChallenge(Challenge value) =>
      _history.put(value.id, value.toMap());
  @override
  Future<void> saveRule(CustomRule value) =>
      _rules.put(value.id, value.toMap());
  @override
  Future<void> deleteRule(String id) => _rules.delete(id);
  @override
  Future<void> saveTimer(int minutes, bool keepScreenOn) =>
      _settings.put('timer', {'minutes': minutes, 'screen': keepScreenOn});
}
