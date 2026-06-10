import 'dart:convert';

/// Domain model for a vocabulary word. The learning target is always English;
/// translations live in a map keyed by ISO code (e.g. 'ru', 'uk', 'pl').
/// The user picks their native language in settings; quiz shows the matching
/// translation. Adding a new language = new key in the map, no schema change.
class Word {
  final int id;
  final String en;
  final Map<String, String> translations;

  final int shortScore;
  final int longScore;
  final DateTime? lastLongUpAt;
  final DateTime? learnedAt;
  final int decayStep;
  final String batch;
  final String? cefr;

  const Word({
    required this.id,
    required this.en,
    required this.translations,
    this.shortScore = 0,
    this.longScore = 0,
    this.lastLongUpAt,
    this.learnedAt,
    this.decayStep = 0,
    this.batch = 'seed',
    this.cefr,
  });

  bool get isLearned => learnedAt != null;

  /// Translation for the user's native language. Falls back to first
  /// available translation, then to '—'.
  String tr(String nativeLang) =>
      translations[nativeLang] ?? translations.values.firstOrNull ?? '—';

  Word copyWith({
    int? id,
    String? en,
    Map<String, String>? translations,
    int? shortScore,
    int? longScore,
    DateTime? lastLongUpAt,
    bool clearLastLongUpAt = false,
    DateTime? learnedAt,
    bool clearLearnedAt = false,
    int? decayStep,
    String? batch,
    String? cefr,
  }) {
    return Word(
      id: id ?? this.id,
      en: en ?? this.en,
      translations: translations ?? this.translations,
      shortScore: shortScore ?? this.shortScore,
      longScore: longScore ?? this.longScore,
      lastLongUpAt: clearLastLongUpAt ? null : (lastLongUpAt ?? this.lastLongUpAt),
      learnedAt: clearLearnedAt ? null : (learnedAt ?? this.learnedAt),
      decayStep: decayStep ?? this.decayStep,
      batch: batch ?? this.batch,
      cefr: cefr ?? this.cefr,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'en': en,
        'translations': jsonEncode(translations),
        'short_score': shortScore,
        'long_score': longScore,
        'last_long_up_at': lastLongUpAt?.millisecondsSinceEpoch,
        'learned_at': learnedAt?.millisecondsSinceEpoch,
        'decay_step': decayStep,
        'batch': batch,
        'cefr': cefr,
      };

  factory Word.fromMap(Map<String, Object?> m) {
    final raw = (m['translations'] as String?) ?? '{}';
    final tr = (jsonDecode(raw) as Map).cast<String, String>();
    return Word(
      id: m['id'] as int,
      en: m['en'] as String,
      translations: tr,
      shortScore: (m['short_score'] as int?) ?? 0,
      longScore: (m['long_score'] as int?) ?? 0,
      lastLongUpAt: _dt(m['last_long_up_at']),
      learnedAt: _dt(m['learned_at']),
      decayStep: (m['decay_step'] as int?) ?? 0,
      batch: (m['batch'] as String?) ?? 'seed',
      cefr: m['cefr'] as String?,
    );
  }

  /// For seed/remote JSON. Expected shape:
  ///   {"id":1,"en":"house","translations":{"ru":"дом","uk":"дім"},"cefr":"A2"}
  factory Word.fromSeedJson(Map<String, Object?> j, {required String batch}) {
    final tr = (j['translations'] as Map?)?.cast<String, String>() ??
        // Backward-compat: legacy {"ru":"…"} field.
        {if (j['ru'] != null) 'ru': j['ru'] as String};
    return Word(
      id: j['id'] as int,
      en: j['en'] as String,
      translations: tr,
      batch: batch,
      cefr: j['cefr'] as String?,
    );
  }

  static DateTime? _dt(Object? v) =>
      v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
