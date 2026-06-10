import 'dart:convert';

/// Domain model for a vocabulary word. Learning target is English; translations
/// keyed by ISO code. Extended metadata (part of speech, phonetics, audio
/// URLs, usage examples) is preserved when source dataset provides it — used
/// by future UI features (IPA display, pronunciation playback, contextual
/// examples).
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

  /// Extended metadata (nullable — not all sources provide it)
  final String? type;          // part of speech: 'verb', 'noun', ...
  final String? phoneticsUs;   // IPA US, e.g. '/əˈbændən/'
  final String? phoneticsUk;   // IPA UK
  final String? audioUs;       // MP3 URL US
  final String? audioUk;       // MP3 URL UK
  final List<String> examples; // usage examples

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
    this.type,
    this.phoneticsUs,
    this.phoneticsUk,
    this.audioUs,
    this.audioUk,
    this.examples = const [],
  });

  bool get isLearned => learnedAt != null;

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
    String? type,
    String? phoneticsUs,
    String? phoneticsUk,
    String? audioUs,
    String? audioUk,
    List<String>? examples,
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
      type: type ?? this.type,
      phoneticsUs: phoneticsUs ?? this.phoneticsUs,
      phoneticsUk: phoneticsUk ?? this.phoneticsUk,
      audioUs: audioUs ?? this.audioUs,
      audioUk: audioUk ?? this.audioUk,
      examples: examples ?? this.examples,
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
        'type': type,
        'phonetics_us': phoneticsUs,
        'phonetics_uk': phoneticsUk,
        'audio_us': audioUs,
        'audio_uk': audioUk,
        'examples': examples.isEmpty ? null : jsonEncode(examples),
      };

  factory Word.fromMap(Map<String, Object?> m) {
    final raw = (m['translations'] as String?) ?? '{}';
    final tr = (jsonDecode(raw) as Map).cast<String, String>();
    final exRaw = m['examples'] as String?;
    final examples = exRaw == null
        ? <String>[]
        : (jsonDecode(exRaw) as List).cast<String>();
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
      type: m['type'] as String?,
      phoneticsUs: m['phonetics_us'] as String?,
      phoneticsUk: m['phonetics_uk'] as String?,
      audioUs: m['audio_us'] as String?,
      audioUk: m['audio_uk'] as String?,
      examples: examples,
    );
  }

  /// For seed/remote JSON. Extended fields are picked up if present.
  factory Word.fromSeedJson(Map<String, Object?> j, {required String batch}) {
    final tr = (j['translations'] as Map?)?.cast<String, String>() ??
        {if (j['ru'] != null) 'ru': j['ru'] as String};

    final phonetics = j['phonetics'] as Map?;
    final audio = j['audio'] as Map?;
    final audioUs = (audio?['us'] as Map?)?['mp3'] as String?;
    final audioUk = (audio?['uk'] as Map?)?['mp3'] as String?;

    final examples = (j['examples'] as List?)?.cast<String>() ?? const <String>[];

    return Word(
      id: j['id'] as int,
      en: j['en'] as String,
      translations: tr,
      batch: batch,
      cefr: j['cefr'] as String?,
      type: j['type'] as String?,
      phoneticsUs: phonetics?['us'] as String?,
      phoneticsUk: phonetics?['uk'] as String?,
      audioUs: audioUs,
      audioUk: audioUk,
      examples: examples,
    );
  }

  static DateTime? _dt(Object? v) =>
      v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
