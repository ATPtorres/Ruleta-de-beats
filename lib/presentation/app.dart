import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/state.dart';
import '../domain/models.dart';
import 'details.dart';
import 'library_pages.dart';
import 'timer_page.dart';

const purple = Color(0xFFBB96FF);
const cyan = Color(0xFF57E8E8);
const panel = Color(0xFF181825);
const ink = Color(0xFF101017);

class BeatRouletteApp extends StatelessWidget {
  const BeatRouletteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Beat Roulette',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: purple,
        secondary: cyan,
        surface: panel,
        onSurface: Color(0xFFF2EEFB),
        onPrimary: Color(0xFF201138),
      ),
      scaffoldBackgroundColor: ink,
      appBarTheme: const AppBarTheme(
        backgroundColor: ink,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: Color(0xFF433066),
      ),
      cardTheme: const CardThemeData(color: panel, margin: EdgeInsets.zero),
    ),
    home: const Deck(),
  );
}

class Deck extends StatefulWidget {
  const Deck({super.key});
  @override
  State<Deck> createState() => _DeckState();
}

class _DeckState extends State<Deck> {
  int index = 0;
  int timerPreset = 30;
  int presetVersion = 0;

  void openTimer(int minutes) => setState(() {
    timerPreset = minutes;
    presetVersion++;
    index = 1;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.graphic_eq, color: cyan),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Beat Roulette',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 18),
          child: Text(
            'OFFLINE',
            style: TextStyle(
              color: cyan,
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      bottom: false,
      child: IndexedStack(
        index: index,
        children: [
          RoulettePage(onTimer: openTimer),
          TimerPage(preset: timerPreset, presetVersion: presetVersion),
          HistoryPage(onTimer: openTimer),
          const RulesPage(),
        ],
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.album_outlined),
          label: 'Ruleta',
        ),
        NavigationDestination(
          icon: Icon(Icons.timer_outlined),
          label: 'Tiempo',
        ),
        NavigationDestination(icon: Icon(Icons.history), label: 'Historial'),
        NavigationDestination(icon: Icon(Icons.tune), label: 'Reglas'),
      ],
    ),
  );
}

class RoulettePage extends ConsumerStatefulWidget {
  const RoulettePage({super.key, required this.onTimer});
  final ValueChanged<int> onTimer;

  @override
  ConsumerState<RoulettePage> createState() => _RoulettePageState();
}

class _RoulettePageState extends ConsumerState<RoulettePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool busy = false;
  double angle = 0;
  double turn = 0;

  Future<void> generate() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final store = ref.read(storeProvider);
      final next = ref
          .read(generatorProvider)
          .generate(
            custom: ref.read(rulesProvider),
            previous: ref.read(currentProvider),
            locks: ref.read(proProvider) ? ref.read(locksProvider) : const {},
            timer: store.timerMinutes,
          );
      await store.saveChallenge(next);
      if (!mounted) return;
      ref.read(revisionProvider.notifier).state++;
      HapticFeedback.selectionClick();
      if (!MediaQuery.disableAnimationsOf(context)) {
        turn = math.pi * (4 + math.Random().nextDouble() * 2);
        await _spin.forward(from: 0).orCancel;
        angle = (angle + turn) % (math.pi * 2);
        turn = 0;
      }
      if (mounted) ref.read(currentProvider.notifier).state = next;
    } on TickerCanceled {
      return;
    } catch (error) {
      if (mounted) {
        showMessage(
          context,
          error is StateError ? error.message : 'No se pudo guardar el reto.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentProvider);
    final pro = ref.watch(proProvider);
    final locks = ref.watch(locksProvider);
    return PageContent(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'SESIÓN CREATIVA',
                style: TextStyle(
                  color: cyan,
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Rápido')),
                ButtonSegment(value: true, label: Text('Pro')),
              ],
              selected: {pro},
              showSelectedIcon: false,
              onSelectionChanged: busy
                  ? null
                  : (v) => ref.read(proProvider.notifier).state = v.single,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          '¿Qué vas a producir?',
          style: TextStyle(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: SizedBox(
            width: 190,
            height: 190,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => CustomPaint(
                painter: _WheelPainter(
                  angle + turn * Curves.easeOutCubic.transform(_spin.value),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(58),
            textStyle: const TextStyle(
              fontSize: 18,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          onPressed: busy ? null : generate,
          icon: const Icon(Icons.casino_outlined),
          label: Text(busy ? 'GIRANDO…' : 'GIRAR'),
        ),
        const SizedBox(height: 18),
        if (current == null)
          Text(
            pro
                ? 'Gira una vez para desbloquear los candados.'
                : 'Gira para crear tu primer reto.',
            textAlign: TextAlign.center,
          )
        else ...[
          if (pro)
            Wrap(
              spacing: 7,
              runSpacing: 3,
              children: [
                for (final field in Field.values)
                  FilterChip(
                    avatar: Icon(
                      locks.contains(field) ? Icons.lock : Icons.lock_open,
                      size: 15,
                    ),
                    showCheckmark: false,
                    label: Text(field.label),
                    selected: locks.contains(field),
                    onSelected: busy
                        ? null
                        : (value) {
                            final next = {...locks};
                            if (value) {
                              next.add(field);
                            } else {
                              next.remove(field);
                            }
                            ref.read(locksProvider.notifier).state = next;
                          },
                  ),
              ],
            ),
          ChallengeDetails(challenge: current, onTimer: widget.onTimer),
        ],
      ],
    );
  }
}

class PageContent extends StatelessWidget {
  const PageContent({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

void showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class _WheelPainter extends CustomPainter {
  const _WheelPainter(this.angle);
  final double angle;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;
    canvas.drawCircle(center, radius + 7, p..color = const Color(0xFF29243D));
    canvas.drawCircle(center, radius + 4, p..color = ink);
    const colors = [
      Color(0xFF8C52EF),
      Color(0xFF4D3181),
      Color(0xFF138C9E),
      Color(0xFF225367),
    ];
    for (var i = 0; i < 12; i++) {
      final start = angle + i * math.pi / 6 - math.pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        math.pi / 6 - .033,
        true,
        p..color = colors[i % colors.length],
      );
      final marker = start + math.pi / 12;
      final dot =
          center + Offset(math.cos(marker), math.sin(marker)) * (radius - 16);
      canvas.drawCircle(dot, 2.7, p..color = const Color(0xCFFFFFFF));
    }
    canvas.drawCircle(center, 26, p..color = ink);
    canvas.drawCircle(center, 17, p..color = const Color(0xFF33234B));
    for (var i = 0; i < 5; i++) {
      final h = [4.0, 7.0, 11.0, 7.0, 4.0][i];
      final x = center.dx + (i - 2) * 4.0;
      canvas.drawLine(
        Offset(x, center.dy - h),
        Offset(x, center.dy + h),
        p
          ..color = cyan
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
    final pointer = Path()
      ..moveTo(center.dx - 8, 3)
      ..lineTo(center.dx + 8, 3)
      ..lineTo(center.dx, 20)
      ..close();
    canvas.drawPath(pointer, p..color = const Color(0xFFF1ECFF));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      angle != oldDelegate.angle;
}
