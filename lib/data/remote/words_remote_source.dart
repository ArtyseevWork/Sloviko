import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/word.dart';

/// Fetches vocabulary batches and the batch-order manifest from a public
/// GitHub-hosted JSON tree.
///
///   <baseUrl>/manifest.json — { "batches": ["a1_batch_1", ...] }
///   <baseUrl>/<batchId>.json — { "words": [...] }
class WordsRemoteSource {
  static const baseUrl =
      'https://raw.githubusercontent.com/ArtyseevWork/Sloviko/main/data/batches';

  /// Returns the ordered list of batch ids declared by the server, or null if
  /// the fetch fails (network down, malformed JSON, etc.).
  Future<List<String>?> fetchManifest() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/manifest.json'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, Object?>;
      final list = (j['batches'] as List?)?.cast<String>();
      if (list == null || list.isEmpty) return null;
      return list;
    } catch (_) {
      return null;
    }
  }

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
