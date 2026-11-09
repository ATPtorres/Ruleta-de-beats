import 'dart:math';
import 'models.dart';

typedef Genre = ({
  String id,
  String name,
  int min,
  int max,
  int center,
  int major,
  int minor,
  int modal,
});
typedef Option = ({String id, String text, Set<String> tags, int? limit});

const genres = <Genre>[
  (
    id: 'trap',
    name: 'Trap',
    min: 125,
    max: 165,
    center: 145,
    major: 2,
    minor: 9,
    modal: 3,
  ),
  (
    id: 'drill',
    name: 'Drill',
    min: 130,
    max: 155,
    center: 142,
    major: 1,
    minor: 9,
    modal: 4,
  ),
  (
    id: 'lofi',
    name: 'LoFi',
    min: 60,
    max: 90,
    center: 76,
    major: 4,
    minor: 9,
    modal: 3,
  ),
  (
    id: 'boom',
    name: 'Boom Bap',
    min: 80,
    max: 105,
    center: 91,
    major: 4,
    minor: 8,
    modal: 3,
  ),
  (
    id: 'reggaeton',
    name: 'Reggaetón',
    min: 85,
    max: 108,
    center: 95,
    major: 3,
    minor: 8,
    modal: 2,
  ),
  (
    id: 'house',
    name: 'House',
    min: 116,
    max: 132,
    center: 124,
    major: 7,
    minor: 7,
    modal: 3,
  ),
  (
    id: 'techno',
    name: 'Techno',
    min: 125,
    max: 155,
    center: 138,
    major: 2,
    minor: 8,
    modal: 4,
  ),
  (
    id: 'edm',
    name: 'EDM',
    min: 115,
    max: 150,
    center: 128,
    major: 7,
    minor: 7,
    modal: 2,
  ),
  (
    id: 'afro',
    name: 'Afrobeat',
    min: 92,
    max: 126,
    center: 108,
    major: 8,
    minor: 5,
    modal: 3,
  ),
  (
    id: 'rnb',
    name: 'R&B',
    min: 62,
    max: 110,
    center: 84,
    major: 6,
    minor: 8,
    modal: 3,
  ),
  (
    id: 'hyperpop',
    name: 'Hyperpop',
    min: 135,
    max: 185,
    center: 158,
    major: 8,
    minor: 5,
    modal: 3,
  ),
  (
    id: 'synthwave',
    name: 'Synthwave',
    min: 85,
    max: 130,
    center: 105,
    major: 4,
    minor: 9,
    modal: 3,
  ),
  (
    id: 'retrowave',
    name: 'Retrowave',
    min: 85,
    max: 125,
    center: 102,
    major: 5,
    minor: 8,
    modal: 2,
  ),
  (
    id: 'funk',
    name: 'Funk',
    min: 90,
    max: 125,
    center: 108,
    major: 7,
    minor: 5,
    modal: 5,
  ),
  (
    id: 'pop80',
    name: '80s Pop',
    min: 88,
    max: 132,
    center: 112,
    major: 9,
    minor: 5,
    modal: 2,
  ),
];

const restrictions = <Option>[
  (id: 'three', text: 'Usa solo 3 pistas.', tags: {'threeTracks'}, limit: null),
  (
    id: 'nohat',
    text: 'Construye el groove sin hi-hats.',
    tags: {'noHats'},
    limit: null,
  ),
  (
    id: 'onesynth',
    text: 'Produce todo con un solo sintetizador.',
    tags: {'synthOnly'},
    limit: null,
  ),
  (
    id: 'samples',
    text: 'Produce todo con samples.',
    tags: {'samplesOnly'},
    limit: null,
  ),
  (
    id: 'vintage',
    text: 'Construye el beat con samples de estética vintage.',
    tags: {'samplesOnly'},
    limit: null,
  ),
  (
    id: 'phone',
    text: 'Construye el beat con grabaciones de tu móvil.',
    tags: {'samplesOnly', 'needsVoice'},
    limit: null,
  ),
  (
    id: 'nocomp',
    text: 'Mezcla sin usar compresión.',
    tags: {'noCompression'},
    limit: null,
  ),
  (
    id: 'voice',
    text: 'Crea el bajo a partir de una voz humana.',
    tags: {'needsVoice'},
    limit: null,
  ),
  (
    id: 'dry',
    text: 'Trabaja sin reverb. Crea profundidad con volumen y paneo.',
    tags: {},
    limit: null,
  ),
  (id: 'mono', text: 'Diseña el beat en mono.', tags: {}, limit: null),
];

const challenges = <Option>[
  (id: 'sprint', text: 'Termina el beat en 20 minutos.', tags: {}, limit: 20),
  (
    id: 'tempo',
    text: 'Cambia de tempo en el puente.',
    tags: {'tempoChange'},
    limit: null,
  ),
  (
    id: 'world',
    text: 'Integra un instrumento tradicional de tu elección.',
    tags: {'liveInstrument'},
    limit: null,
  ),
  (
    id: 'odd',
    text: 'Crea una sección en compás de 7/8.',
    tags: {},
    limit: null,
  ),
  (
    id: 'hat',
    text: 'Programa una variación de hi-hats cada cuatro compases.',
    tags: {'needsHats'},
    limit: null,
  ),
  (
    id: 'sidechain',
    text: 'Haz respirar el bajo con compresión sidechain.',
    tags: {'needsCompression'},
    limit: null,
  ),
  (
    id: 'layer',
    text: 'Construye un hook usando al menos cuatro pistas.',
    tags: {'fourTracks'},
    limit: null,
  ),
  (
    id: 'break',
    text: 'Crea tensión con un compás de silencio antes del estribillo.',
    tags: {},
    limit: null,
  ),
  (
    id: 'flip',
    text: 'Crea dos grooves distintos con los mismos sonidos.',
    tags: {},
    limit: null,
  ),
];

const tagLabels = <String, String>{
  'threeTracks': 'Máximo 3 pistas',
  'fourTracks': 'Al menos 4 pistas',
  'noHats': 'Sin hi-hats',
  'needsHats': 'Requiere hi-hats',
  'synthOnly': 'Solo sintetizador',
  'samplesOnly': 'Solo samples',
  'needsVoice': 'Requiere grabaciones',
  'liveInstrument': 'Requiere instrumento real',
  'noCompression': 'Sin compresión',
  'needsCompression': 'Requiere compresión',
  'tempoChange': 'Cambio de tempo',
  'fixedTempo': 'Tempo fijo',
};

const _conflicts = [
  ('threeTracks', 'fourTracks'),
  ('noHats', 'needsHats'),
  ('synthOnly', 'samplesOnly'),
  ('synthOnly', 'needsVoice'),
  ('synthOnly', 'liveInstrument'),
  ('samplesOnly', 'liveInstrument'),
  ('noCompression', 'needsCompression'),
  ('tempoChange', 'fixedTempo'),
];

bool compatible(Set<String> tags) =>
    !_conflicts.any((pair) => tags.contains(pair.$1) && tags.contains(pair.$2));

class Generator {
  Generator([Random? random]) : _random = random ?? Random();
  final Random _random;

  T _pick<T>(List<T> options, int Function(T) weight) {
    var n = _random.nextInt(
      options.fold<int>(0, (int sum, T item) => sum + weight(item)),
    );
    return options.firstWhere((item) => (n -= weight(item)) < 0);
  }

  Challenge generate({
    List<CustomRule> custom = const [],
    Challenge? previous,
    Set<Field> locks = const {},
    int timer = 30,
  }) {
    final now = DateTime.now();
    final profiles = [
      ...genres,
      for (final rule in custom.where((r) => r.kind == RuleKind.genre))
        (
          id: rule.id,
          name: rule.text,
          min: rule.min,
          max: rule.max,
          center: (rule.min + rule.max) ~/ 2,
          major: 6,
          minor: 7,
          modal: 3,
        ),
    ];
    bool locked(Field field) => previous != null && locks.contains(field);
    final lockedBpm = locked(Field.bpm)
        ? int.parse(previous!.label(Field.bpm))
        : null;
    final availableGenres = profiles
        .where(
          (g) =>
              (!locked(Field.genre) || g.id == previous!.genreId) &&
              (lockedBpm == null || (lockedBpm >= g.min && lockedBpm <= g.max)),
        )
        .toList();
    if (availableGenres.isEmpty) {
      throw StateError(
        'El BPM o el género fijado ya no coincide con el catálogo. Quita ese candado.',
      );
    }
    final genre = _pick(
      availableGenres,
      (g) => g.id == previous?.genreId && availableGenres.length > 1
          ? 1
          : {
              'synthwave',
              'retrowave',
              'pop80',
              'funk',
              'reggaeton',
              'trap',
            }.contains(g.id)
          ? 5
          : 3,
    );
    final bpm =
        lockedBpm ??
        _pick<int>(
          List.generate(genre.max - genre.min + 1, (i) => genre.min + i),
          (bpm) => max(1, 10 - (bpm - genre.center).abs() ~/ 2),
        );
    const roots = [
      'C',
      'C#',
      'D',
      'Eb',
      'E',
      'F',
      'F#',
      'G',
      'Ab',
      'A',
      'Bb',
      'B',
    ];
    final mode = _pick(
      ['Major', 'Minor', 'Dorian', 'Phrygian', 'Mixolydian'],
      (m) => switch (m) {
        'Major' => genre.major * 3,
        'Minor' => genre.minor * 3,
        _ => genre.modal,
      },
    );
    final scale = locked(Field.scale)
        ? previous!.label(Field.scale)
        : '${roots[_random.nextInt(roots.length)]} $mode';

    List<Option> pool(Field field, RuleKind kind, List<Option> defaults) {
      final list = [
        ...defaults,
        for (final rule in custom.where((r) => r.kind == kind))
          (id: rule.id, text: rule.text, tags: rule.tags, limit: null),
      ];
      return locked(field)
          ? list
                .where((option) => option.id == previous!.ruleIds[field])
                .toList()
          : list;
    }

    const none = (id: 'none', text: '', tags: <String>{}, limit: null);
    final rs = pool(Field.restriction, RuleKind.restriction, restrictions);
    final ds = pool(Field.challenge, RuleKind.challenge, challenges);
    final cs = pool(Field.condition, RuleKind.condition, [none]);
    bool fits(Option r, Option d, Option c) =>
        compatible({...r.tags, ...d.tags, ...c.tags});
    final possibleR = rs
        .where((r) => ds.any((d) => cs.any((c) => fits(r, d, c))))
        .toList();
    if (possibleR.isEmpty) {
      throw StateError(
        'Los candados fijan reglas incompatibles o eliminadas. Quita un candado y vuelve a girar.',
      );
    }
    final r = _pick(
      possibleR,
      (item) => item.id == 'vintage' && genre.id == 'lofi'
          ? 12
          : item.id == 'onesynth' &&
                {'synthwave', 'retrowave', 'pop80'}.contains(genre.id)
          ? 8
          : 3,
    );
    final d = _pick(
      ds.where((d) => cs.any((c) => fits(r, d, c))).toList(),
      (_) => 3,
    );
    final c = _pick(
      cs.where((c) => fits(r, d, c)).toList(),
      (c) => c.id == 'none' ? 1 : 3,
    );

    return Challenge(
      '${now.microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}',
      now,
      Map.unmodifiable({
        Field.genre: genre.name,
        Field.bpm: '$bpm',
        Field.scale: scale,
        Field.restriction: r.text,
        Field.challenge: d.text,
        Field.condition: c.text,
      }),
      genre.id,
      Map.unmodifiable({
        Field.restriction: r.id,
        Field.challenge: d.id,
        Field.condition: c.id,
      }),
      limit: d.limit ?? timer,
    );
  }
}
