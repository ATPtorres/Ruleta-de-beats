import 'package:beat_roulette/application/android_tools.dart';
import 'package:beat_roulette/application/state.dart';
import 'package:beat_roulette/domain/models.dart';
import 'package:beat_roulette/presentation/app.dart';
import 'package:beat_roulette/presentation/details.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStore implements BeatStore {
  @override
  final history = <Challenge>[];
  @override
  final rules = <CustomRule>[];
  @override
  int timerMinutes = 30;
  @override
  bool keepScreenOn = false;

  @override
  Future<void> saveChallenge(Challenge value) async => history.insert(0, value);
  @override
  Future<void> saveRule(CustomRule value) async => rules.add(value);
  @override
  Future<void> deleteRule(String id) async =>
      rules.removeWhere((value) => value.id == id);
  @override
  Future<void> saveTimer(int minutes, bool keepScreenOn) async {
    timerMinutes = minutes;
    this.keepScreenOn = keepScreenOn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(
    () => messenger.setMockMethodCallHandler(AndroidTools.channel, null),
  );

  testWidgets('gira y recupera el reto en Historial en una pantalla estrecha', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    messenger.setMockMethodCallHandler(AndroidTools.channel, (call) async {
      if (call.method == 'deadline') return 0;
      if (call.method == 'status') {
        return {'notifications': true, 'exact': true};
      }
      return null;
    });
    final store = _MemoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storeProvider.overrideWithValue(store)],
        child: const BeatRouletteApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('GIRAR'));
    await tester.pumpAndSettle();
    expect(store.history, hasLength(1));
    await tester.tap(find.text('Pro'));
    await tester.pumpAndSettle();
    expect(find.text('Género'), findsOneWidget);
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text(store.history.single.label(Field.genre)), findsOneWidget);
  });

  testWidgets('la exportación produce un PNG cuadrado de 1080 px', (
    tester,
  ) async {
    Uint8List? bytes;
    messenger.setMockMethodCallHandler(AndroidTools.channel, (call) async {
      bytes = call.arguments['bytes'] as Uint8List;
      return 'Beat-Roulette-test.png';
    });
    final challenge = Challenge(
      'png',
      DateTime(2026),
      const {
        Field.genre: 'Synthwave',
        Field.bpm: '104',
        Field.scale: 'D Minor',
        Field.restriction: 'Usa solo 3 pistas.',
        Field.challenge: 'Crea un puente en 7/8.',
      },
      'synthwave',
      const {},
      limit: 30,
    );
    final name = await tester.runAsync(() => exportCard(challenge));
    expect(name, 'Beat-Roulette-test.png');
    final data = ByteData.sublistView(bytes!);
    expect(data.getUint32(0), 0x89504e47);
    expect(data.getUint32(16), 1080);
    expect(data.getUint32(20), 1080);
  });
}
