import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/android_tools.dart';
import '../application/state.dart';
import '../domain/models.dart';
import 'app.dart';

class ChallengeDetails extends ConsumerStatefulWidget {
  const ChallengeDetails({
    super.key,
    required this.challenge,
    required this.onTimer,
  });
  final Challenge challenge;
  final ValueChanged<int> onTimer;

  @override
  ConsumerState<ChallengeDetails> createState() => _ChallengeDetailsState();
}

class _ChallengeDetailsState extends ConsumerState<ChallengeDetails> {
  bool saving = false;
  bool exporting = false;

  Future<void> edit(Challenge updated) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await ref.read(storeProvider).saveChallenge(updated);
      if (!mounted) return;
      final current = ref.read(currentProvider);
      if (current?.id == updated.id) {
        ref.read(currentProvider.notifier).state = updated;
      }
      ref.read(revisionProvider.notifier).state++;
    } catch (_) {
      if (mounted) showMessage(context, 'No se pudo actualizar el reto.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> notes(Challenge current) async {
    var value = current.notes;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notas del reto'),
        content: TextFormField(
          initialValue: value,
          minLines: 3,
          maxLines: 6,
          maxLength: 1000,
          onChanged: (text) => value = text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, value.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (mounted && result != null) await edit(current.edit(notes: result));
  }

  Future<void> export(Challenge value) async {
    setState(() => exporting = true);
    try {
      final name = await exportCard(value);
      if (mounted) {
        showMessage(context, 'PNG guardado en Imágenes / Beat Roulette\n$name');
      }
    } catch (_) {
      if (mounted) showMessage(context, 'No se pudo exportar el PNG.');
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final item =
        history.where((e) => e.id == widget.challenge.id).firstOrNull ??
        widget.challenge;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label(Field.genre),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: saving
                      ? null
                      : () => edit(item.edit(favorite: !item.favorite)),
                  tooltip: item.favorite
                      ? 'Quitar favorito'
                      : 'Marcar como favorito',
                  icon: Icon(
                    item.favorite ? Icons.star : Icons.star_border,
                    color: purple,
                  ),
                ),
              ],
            ),
            Text(
              '${item.label(Field.bpm)} BPM    /    ${item.label(Field.scale)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: cyan),
            ),
            const Divider(height: 24),
            for (final field in [
              Field.restriction,
              Field.challenge,
              Field.condition,
            ])
              if (item.label(field).isNotEmpty) ...[
                Text(
                  field.label.toUpperCase(),
                  style: const TextStyle(
                    color: purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                Text(item.label(field)),
                const SizedBox(height: 9),
              ],
            if (item.notes.isNotEmpty) ...[
              const Text(
                'NOTAS',
                style: TextStyle(
                  color: purple,
                  fontSize: 10,
                  letterSpacing: 1.4,
                ),
              ),
              Text(item.notes),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                OutlinedButton.icon(
                  onPressed: () => widget.onTimer(item.limit ?? 30),
                  icon: const Icon(Icons.timer_outlined),
                  label: Text('${item.limit ?? 30} min'),
                ),
                OutlinedButton.icon(
                  onPressed: saving ? null : () => notes(item),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Notas'),
                ),
                OutlinedButton.icon(
                  onPressed: exporting ? null : () => export(item),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('PNG'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> exportCard(Challenge item) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint();
  const size = 1080;
  const area = Rect.fromLTWH(0, 0, 1080, 1080);
  paint.shader = const LinearGradient(
    colors: [Color(0xFF120F20), Color(0xFF241745), Color(0xFF0D2632)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ).createShader(area);
  canvas.drawRect(area, paint);
  paint.shader = null;
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(48, 48, 1032, 1032),
      const Radius.circular(37),
    ),
    paint
      ..color = const Color(0xFF574575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
  paint.style = PaintingStyle.fill;
  canvas.drawRect(const Rect.fromLTWH(83, 151, 914, 2), paint..color = purple);

  void draw(
    String value,
    double y,
    double size,
    Color color, {
    int max = 1,
    bool bold = false,
    double width = 914,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: max,
      ellipsis: '…',
    )..layout(maxWidth: width);
    text.paint(canvas, Offset(83, y));
    text.dispose();
  }

  draw('BEAT ROULETTE  /  RETO DE PRODUCCIÓN', 88, 30, cyan, bold: true);
  draw(item.label(Field.genre), 177, 67, Colors.white, max: 2, bold: true);
  draw(
    '${item.label(Field.bpm)} BPM   /   ${item.label(Field.scale)}',
    348,
    46,
    cyan,
    bold: true,
  );
  final fields = [
    Field.restriction,
    Field.challenge,
    Field.condition,
  ].where((field) => item.label(field).isNotEmpty).toList();
  for (var i = 0; i < fields.length; i++) {
    final field = fields[i];
    final y = 438.0 + 157 * i;
    draw(field.label.toUpperCase(), y, 24, purple, bold: true);
    draw(item.label(field), y + 35, 34, Colors.white, max: 3);
  }
  draw('TIEMPO LÍMITE    ${item.limit ?? 30} MIN', 947, 32, cyan, bold: true);

  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(size, size);
    try {
      final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      return await AndroidTools().savePng(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}
