import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/android_tools.dart';
import '../application/state.dart';
import 'app.dart';

class TimerPage extends ConsumerStatefulWidget {
  const TimerPage({
    super.key,
    required this.preset,
    required this.presetVersion,
  });
  final int preset, presetVersion;
  @override
  ConsumerState<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends ConsumerState<TimerPage>
    with WidgetsBindingObserver {
  final android = AndroidTools();
  late int minutes;
  late bool keepOn;
  int deadline = 0, total = 0;
  bool ready = false, busy = false, done = false;
  Timer? ticker;
  Map<String, bool> status = {};

  @override
  void initState() {
    super.initState();
    final store = ref.read(storeProvider);
    minutes = store.timerMinutes;
    keepOn = store.keepScreenOn;
    WidgetsBinding.instance.addObserver(this);
    unawaited(restore());
  }

  Future<void> restore() async {
    try {
      final saved = await android.deadline();
      final permissions = await android.status();
      if (!mounted) return;
      setState(() {
        status = permissions;
        if (saved > 0) {
          deadline = saved;
          if (total == 0) total = minutes * 60;
        } else {
          done = ready && deadline > 0;
          deadline = 0;
        }
        ready = true;
      });
      await android.setScreen(keepOn && deadline > 0);
      if (!mounted) return;
      startTicker();
    } catch (_) {
      if (mounted) {
        showMessage(context, 'El temporizador de Android no está disponible.');
      }
    }
  }

  @override
  void didUpdateWidget(covariant TimerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.presetVersion != oldWidget.presetVersion &&
        deadline == 0 &&
        !busy) {
      minutes = widget.preset;
      done = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) unawaited(restore());
  }

  int get remaining => deadline == 0
      ? (done ? 0 : minutes * 60)
      : ((deadline - DateTime.now().millisecondsSinceEpoch) / 1000)
            .ceil()
            .clamp(0, 86400);

  void startTicker() {
    ticker?.cancel();
    if (deadline == 0) return;
    ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
    tick();
  }

  void tick() {
    if (!mounted || busy || deadline == 0) return;
    if (remaining == 0) {
      ticker?.cancel();
      final active =
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (active) {
        unawaited(
          perform(() async {
            await android.finish();
            if (!mounted) return;
            setState(() {
              deadline = 0;
              done = true;
            });
            await android.setScreen(false);
          }),
        );
      }
    } else {
      setState(() {});
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showMessage(context, 'No se pudo actualizar el temporizador.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> toggle() => perform(() async {
    if (deadline != 0) {
      await android.cancel();
      ticker?.cancel();
      if (!mounted) return;
      setState(() {
        deadline = 0;
        done = false;
      });
      await android.setScreen(false);
    } else {
      final target = DateTime.now()
          .add(Duration(minutes: minutes))
          .millisecondsSinceEpoch;
      await ref.read(storeProvider).saveTimer(minutes, keepOn);
      await android.start(target);
      if (!mounted) return;
      setState(() {
        total = minutes * 60;
        deadline = target;
        done = false;
      });
      startTicker();
      await android.setScreen(keepOn);
    }
  });

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = remaining;
    final hours = seconds ~/ 3600;
    final mm = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return PageContent(
      children: [
        const Text(
          'FOCO DE PRODUCCIÓN',
          style: TextStyle(color: cyan, fontSize: 11, letterSpacing: 2.4),
        ),
        const Text(
          'Temporizador',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss',
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: deadline == 0
                      ? (done ? 0 : 1)
                      : (seconds / (total > 0 ? total : 1)).clamp(0.0, 1.0),
                  minHeight: 5,
                  color: cyan,
                  borderRadius: BorderRadius.circular(8),
                ),
                if (done)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Sesión terminada'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final preset in {15, if (minutes == 20) 20, 30, 45, 60, 120})
              ChoiceChip(
                label: Text(preset < 60 ? '$preset min' : '${preset ~/ 60} h'),
                selected: preset == minutes,
                onSelected: ready && deadline == 0 && !busy
                    ? (_) => perform(() async {
                        await ref.read(storeProvider).saveTimer(preset, keepOn);
                        if (mounted) {
                          setState(() {
                            minutes = preset;
                            done = false;
                          });
                        }
                      })
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: ready && !busy ? toggle : null,
          icon: Icon(deadline == 0 ? Icons.play_arrow : Icons.stop),
          label: Text(deadline == 0 ? 'Iniciar sesión' : 'Cancelar sesión'),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: keepOn,
          title: const Text('Mantener pantalla encendida'),
          subtitle: const Text('Durante una sesión activa'),
          onChanged: ready && !busy
              ? (value) => perform(() async {
                  await ref.read(storeProvider).saveTimer(minutes, value);
                  if (!mounted) return;
                  setState(() => keepOn = value);
                  await android.setScreen(value && deadline > 0);
                })
              : null,
        ),
        if (ready && status['notifications'] != true)
          OutlinedButton.icon(
            onPressed: () => perform(android.enableNotifications),
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Activar avisos de Android'),
          ),
        if (ready && status['exact'] != true)
          OutlinedButton.icon(
            onPressed: () => perform(android.exactSettings),
            icon: const Icon(Icons.alarm_on),
            label: const Text('Habilitar alarmas exactas'),
          ),
        if (ready && status['exact'] != true)
          const Text(
            'Con la pantalla apagada, Android puede retrasar el aviso.',
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
