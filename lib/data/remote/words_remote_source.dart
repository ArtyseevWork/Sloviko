import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/word.dart';

/// Fetches additional word batches from a public GitHub-hosted JSON.
/// Path convention: <baseUrl>/<batchId>.json with shape:
///   { "words": [ {"id":..., "en":..., "ru":..., "cefr":"A2"} ] }
class WordsRemoteSource {
  static const baseUrl =
      'https://raw.githubusercontent.com/ArtyseevWork/Sloviko/main/data/batches';

  /// Returns null if fetch fails or batch not found.
  Future<List<Word>?> fetchBatch(String batchId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/$batchId.json'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, Object?>;
      final list = (j['words'] as List).cast<Map<String, Object?>>();
      return list.map((m) => Word.fromSeedJson(m, batch: batchId)).toList();
    } catch (_) {
      return null;
    }
  }
}
