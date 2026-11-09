import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'application/android_tools.dart';
import 'application/state.dart';
import 'data/hive_store.dart';
import 'presentation/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await HiveStore.open(await AndroidTools().storagePath());
    runApp(
      ProviderScope(
        overrides: [storeProvider.overrideWithValue(store)],
        child: const BeatRouletteApp(),
      ),
    );
  } catch (_) {
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudo abrir el almacenamiento local. Cierra la app y vuelve a abrirla.',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
