import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/state.dart';
import '../domain/generator.dart';
import '../domain/models.dart';
import 'app.dart';
import 'details.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key, required this.onTimer});
  final ValueChanged<int> onTimer;
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String query = '';
  String? genre;
  bool onlyFavorites = false;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(historyProvider);
    final genres = all.map((e) => e.label(Field.genre)).toSet().toList()
      ..sort();
    final entries = all
        .where(
          (item) =>
              (!onlyFavorites || item.favorite) &&
              (genre == null || item.label(Field.genre) == genre) &&
              '${item.values.values.join(' ')} ${item.notes}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            children: [
              TextField(
                onChanged: (text) =>
                    setState(() => query = text.trim().toLowerCase()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar retos y notas',
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: genre ?? '',
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Todos los géneros'),
                        ),
                        for (final value in genres)
                          DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => genre = value == '' ? null : value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilterChip(
                    label: const Text('Favoritos'),
                    selected: onlyFavorites,
                    avatar: const Icon(Icons.star_outline),
                    onSelected: (value) =>
                        setState(() => onlyFavorites = value),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    all.isEmpty
                        ? 'Tus retos aparecerán aquí.'
                        : 'Sin resultados para estos filtros.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final date = MaterialLocalizations.of(
                      context,
                    ).formatCompactDate(entry.date.toLocal());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: ListTile(
                          leading: Icon(
                            entry.favorite ? Icons.star : Icons.album_outlined,
                            color: purple,
                          ),
                          title: Text(entry.label(Field.genre)),
                          subtitle: Text(
                            '${entry.label(Field.bpm)} BPM  /  ${entry.label(Field.scale)}  /  $date',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            showDragHandle: true,
                            builder: (sheet) => SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                              child: ChallengeDetails(
                                challenge: entry,
                                onTimer: (minutes) {
                                  Navigator.pop(sheet);
                                  widget.onTimer(minutes);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class RulesPage extends ConsumerStatefulWidget {
  const RulesPage({super.key});
  @override
  ConsumerState<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends ConsumerState<RulesPage> {
  RuleKind kind = RuleKind.genre;

  Future<void> edit([CustomRule? old]) async {
    final item = await showDialog<CustomRule>(
      context: context,
      builder: (context) => _RuleDialog(kind: old?.kind ?? kind, old: old),
    );
    if (mounted && item != null) {
      await write(() => ref.read(storeProvider).saveRule(item));
    }
  }

  Future<void> remove(CustomRule rule) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar regla'),
        content: Text(rule.text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (mounted && ok == true) {
      await write(() => ref.read(storeProvider).deleteRule(rule.id));
    }
  }

  Future<void> write(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) ref.read(revisionProvider.notifier).state++;
    } catch (_) {
      if (mounted) {
        showMessage(context, 'No se pudieron actualizar las reglas.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref
        .watch(rulesProvider)
        .where((rule) => rule.kind == kind)
        .toList();
    return PageContent(
      children: [
        const Text(
          'CATÁLOGO PERSONAL',
          style: TextStyle(color: cyan, fontSize: 11, letterSpacing: 2.4),
        ),
        const Text(
          'Mis propias reglas',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Text(
          'Añade opciones a la ruleta. Las etiquetas de compatibilidad ayudan a evitar contradicciones.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final item in RuleKind.values)
              ChoiceChip(
                label: Text(item.label),
                selected: kind == item,
                onSelected: (_) => setState(() => kind = item),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => edit(),
          icon: const Icon(Icons.add),
          label: const Text('Añadir al catálogo'),
        ),
        const SizedBox(height: 12),
        if (rules.isEmpty)
          const Text('Todavía no hay entradas en esta categoría.'),
        for (final rule in rules)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                title: Text(rule.text),
                subtitle: rule.kind == RuleKind.genre
                    ? Text('${rule.min}–${rule.max} BPM')
                    : rule.tags.isEmpty
                    ? null
                    : Text(
                        rule.tags
                            .map((tag) => tagLabels[tag] ?? tag)
                            .join(' · '),
                      ),
                onTap: () => edit(rule),
                trailing: IconButton(
                  onPressed: () => remove(rule),
                  tooltip: 'Eliminar regla',
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({required this.kind, this.old});
  final RuleKind kind;
  final CustomRule? old;
  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  final form = GlobalKey<FormState>();
  late String text = widget.old?.text ?? '';
  late String min = '${widget.old?.min ?? 80}';
  late String max = '${widget.old?.max ?? 120}';
  late final tags = <String>{...?widget.old?.tags};
  String? error;
  bool get isGenre => widget.kind == RuleKind.genre;

  void save() {
    if (!form.currentState!.validate()) return;
    if (isGenre && int.parse(min) > int.parse(max)) {
      setState(() => error = 'El BPM mínimo debe ser menor o igual al máximo.');
      return;
    }
    if (!compatible(tags)) {
      setState(() => error = 'Selecciona etiquetas compatibles entre sí.');
      return;
    }
    Navigator.pop(
      context,
      CustomRule(
        widget.old?.id ?? 'custom-${DateTime.now().microsecondsSinceEpoch}',
        widget.kind,
        text.trim(),
        min: int.parse(min),
        max: int.parse(max),
        tags: {...tags},
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.old == null
          ? 'Añadir · ${widget.kind.label}'
          : 'Editar · ${widget.kind.label}',
    ),
    scrollable: true,
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: text,
            maxLength: isGenre ? 40 : 120,
            decoration: InputDecoration(
              labelText: isGenre ? 'Nombre del género' : 'Texto de la regla',
            ),
            onChanged: (value) => text = value,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe un nombre o una regla.'
                : null,
          ),
          if (isGenre) ...[
            const SizedBox(height: 10),
            TextFormField(
              initialValue: min,
              onChanged: (value) => min = value,
              validator: validateBpm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'BPM mínimo'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: max,
              onChanged: (value) => max = value,
              validator: validateBpm,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'BPM máximo'),
            ),
          ] else ...[
            const Text('Etiquetas opcionales'),
            Wrap(
              spacing: 5,
              children: [
                for (final tag in tagLabels.entries)
                  FilterChip(
                    label: Text(tag.value),
                    selected: tags.contains(tag.key),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        tags.add(tag.key);
                      } else {
                        tags.remove(tag.key);
                      }
                    }),
                  ),
              ],
            ),
          ],
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: save, child: const Text('Guardar')),
    ],
  );
}

String? validateBpm(String? value) {
  final bpm = int.tryParse(value ?? '');
  return bpm == null || bpm < 30 || bpm > 240
      ? 'Usa un BPM entre 30 y 240.'
      : null;
}
