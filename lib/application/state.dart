import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/generator.dart';
import '../domain/models.dart';

final storeProvider = Provider<BeatStore>(
  (ref) => throw StateError('Hive pendiente'),
);
final generatorProvider = Provider((ref) => Generator());
final currentProvider = StateProvider<Challenge?>(
  (ref) => ref.watch(storeProvider).history.firstOrNull,
);
final locksProvider = StateProvider<Set<Field>>((ref) => {});
final proProvider = StateProvider<bool>((ref) => false);
final revisionProvider = StateProvider<int>((ref) => 0);
final historyProvider = Provider<List<Challenge>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(storeProvider).history;
});
final rulesProvider = Provider<List<CustomRule>>((ref) {
  ref.watch(revisionProvider);
  return ref.watch(storeProvider).rules;
});
