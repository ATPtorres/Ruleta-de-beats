enum Field {
  genre('Género'),
  bpm('BPM'),
  scale('Escala'),
  restriction('Restricción'),
  challenge('Desafío'),
  condition('Condición');

  const Field(this.label);
  final String label;
}

enum RuleKind {
  genre('Géneros'),
  restriction('Restricciones'),
  challenge('Desafíos'),
  condition('Condiciones');

  const RuleKind(this.label);
  final String label;
}

class CustomRule {
  const CustomRule(
    this.id,
    this.kind,
    this.text, {
    this.min = 80,
    this.max = 120,
    this.tags = const {},
  });
  final String id, text;
  final RuleKind kind;
  final int min, max;
  final Set<String> tags;

  factory CustomRule.fromMap(Map m) => CustomRule(
    m['id'] as String,
    RuleKind.values.byName(m['kind'] as String),
    m['text'] as String,
    min: m['min'] as int,
    max: m['max'] as int,
    tags: (m['tags'] as List).cast<String>().toSet(),
  );

  Map<String, Object> toMap() => {
    'id': id,
    'kind': kind.name,
    'text': text,
    'min': min,
    'max': max,
    'tags': tags.toList(),
  };
}

class Challenge {
  const Challenge(
    this.id,
    this.date,
    this.values,
    this.genreId,
    this.ruleIds, {
    this.limit,
    this.notes = '',
    this.favorite = false,
  });
  final String id, genreId, notes;
  final DateTime date;
  final Map<Field, String> values;
  final Map<Field, String> ruleIds;
  final int? limit;
  final bool favorite;

  String label(Field field) => values[field] ?? '';
  Challenge edit({String? notes, bool? favorite}) => Challenge(
    id,
    date,
    values,
    genreId,
    ruleIds,
    limit: limit,
    notes: notes ?? this.notes,
    favorite: favorite ?? this.favorite,
  );

  factory Challenge.fromMap(Map m) => Challenge(
    m['id'] as String,
    DateTime.parse(m['date'] as String),
    (m['values'] as Map).map(
      (k, v) => MapEntry(Field.values.byName(k as String), v as String),
    ),
    m['genreId'] as String,
    (m['ruleIds'] as Map).map(
      (k, v) => MapEntry(Field.values.byName(k as String), v as String),
    ),
    limit: m['limit'] as int?,
    notes: m['notes'] as String,
    favorite: m['favorite'] as bool,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'date': date.toUtc().toIso8601String(),
    'genreId': genreId,
    'values': values.map((k, v) => MapEntry(k.name, v)),
    'ruleIds': ruleIds.map((k, v) => MapEntry(k.name, v)),
    'limit': limit,
    'notes': notes,
    'favorite': favorite,
  };
}

abstract interface class BeatStore {
  List<Challenge> get history;
  List<CustomRule> get rules;
  int get timerMinutes;
  bool get keepScreenOn;
  Future<void> saveChallenge(Challenge value);
  Future<void> saveRule(CustomRule value);
  Future<void> deleteRule(String id);
  Future<void> saveTimer(int minutes, bool keepScreenOn);
}
