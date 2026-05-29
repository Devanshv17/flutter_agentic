/// HuggingFace Hub REST API client.
///
/// Provides:
/// - Listing files inside a repository.
/// - Detecting the best model file for Flutter.
/// - Constructing CDN download URLs.
/// - Searching for models by task / library.
library;

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'model_format.dart';

// ── DTOs ─────────────────────────────────────────────────────────────────────

/// A single file entry inside a HuggingFace repository.
class HFFile {
  /// File path inside the repo (e.g. `"model.gguf"`, `"weights/shard-1.gguf"`).
  final String rfilename;

  /// File size in bytes, or null if not returned by the API.
  final int? size;

  /// SHA-256 blob hash, or null if not returned.
  final String? blobId;

  const HFFile({
    required this.rfilename,
    this.size,
    this.blobId,
  });

  /// Inferred [ModelFormat] for this file.
  ModelFormat get format => ModelFormat.detect(rfilename);

  /// Human-readable size string (e.g. `"271 MB"`).
  String get sizeDisplay {
    if (size == null) return 'unknown size';
    final mb = size! / (1024 * 1024);
    if (mb >= 1000) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  String toString() => 'HFFile($rfilename, $sizeDisplay)';
}

/// Basic metadata for a HuggingFace repository.
class HFModelInfo {
  final String modelId;
  final List<HFFile> files;
  final List<String> tags;
  final String? pipelineTag;
  final int? downloads;
  final int? likes;

  const HFModelInfo({
    required this.modelId,
    required this.files,
    this.tags = const [],
    this.pipelineTag,
    this.downloads,
    this.likes,
  });

  /// All files that are directly runnable in Flutter (any supported format).
  List<HFFile> get runnableFiles => files
      .where((f) => f.format != ModelFormat.unknown && f.format.isOnDevice)
      .toList();

  /// Recommended file for Flutter — prefers `.litertlm` > `.gguf` > `.task`.
  HFFile? get recommendedFile {
    // Order of preference for Flutter
    const order = [
      ModelFormat.litertlm,
      ModelFormat.gguf,
      ModelFormat.task,
      ModelFormat.tflite,
      ModelFormat.binary,
    ];
    for (final fmt in order) {
      // Among multiple files of the same format, pick the smallest
      final candidates = files.where((f) => f.format == fmt).toList();
      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => (a.size ?? 0).compareTo(b.size ?? 0));
        return candidates.first;
      }
    }
    return null;
  }
}

// ── Main client ───────────────────────────────────────────────────────────────

/// Static client for the HuggingFace Hub REST API.
///
/// All methods are static — no instance needed. Tokens are resolved
/// automatically from `HF_TOKEN` / `HUGGINGFACE_TOKEN` env vars, or
/// can be supplied explicitly.
///
/// ```dart
/// // Inspect a repo
/// final info = await HFHub.modelInfo('litert-community/Qwen3-0.6B');
/// print(info.recommendedFile); // → HFFile(qwen3-0.6b-q4_1.litertlm, 400 MB)
///
/// // Get download URL
/// final url = HFHub.downloadUrl('litert-community/Qwen3-0.6B', 'qwen3-0.6b-q4_1.litertlm');
/// ```
abstract class HFHub {
  static const _apiBase = 'https://huggingface.co/api';
  static const _cdnBase = 'https://huggingface.co';

  // ── Model info ────────────────────────────────────────────────────────────

  /// Fetch full metadata and file list for a repository.
  ///
  /// [repoId] is `owner/name` (e.g. `"litert-community/Qwen3-0.6B"`).
  /// [hfToken] is read from env if not supplied.
  ///
  /// Throws [HFException] on API errors.
  static Future<HFModelInfo> modelInfo(
    String repoId, {
    String? hfToken,
    String revision = 'main',
  }) async {
    final token = _resolveToken(hfToken);
    final uri = Uri.parse('$_apiBase/models/$repoId?blobs=true&revision=$revision');

    final response = await http.get(uri, headers: _headers(token));
    _checkStatus(response, repoId);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final siblings = (json['siblings'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    final files = siblings.map((s) {
      final size = (s['size'] as num?)?.toInt();
      return HFFile(
        rfilename: s['rfilename'] as String,
        size: size,
        blobId: s['oid'] as String?,
      );
    }).toList();

    final tags = (json['tags'] as List? ?? []).cast<String>();

    return HFModelInfo(
      modelId: repoId,
      files: files,
      tags: tags,
      pipelineTag: json['pipeline_tag'] as String?,
      downloads: (json['downloads'] as num?)?.toInt(),
      likes: (json['likes'] as num?)?.toInt(),
    );
  }

  /// List only the files inside a repository (lighter than [modelInfo]).
  static Future<List<HFFile>> listFiles(
    String repoId, {
    String? hfToken,
    String revision = 'main',
  }) async {
    final info = await modelInfo(repoId, hfToken: hfToken, revision: revision);
    return info.files;
  }

  /// Find the best model file for Flutter in [repoId].
  ///
  /// Returns the recommended [HFFile], or `null` if the repo has no
  /// runnable model files.
  static Future<HFFile?> findBestFile(
    String repoId, {
    String? hfToken,
    String revision = 'main',
  }) async {
    final info = await modelInfo(repoId, hfToken: hfToken, revision: revision);
    return info.recommendedFile;
  }

  // ── URL construction ──────────────────────────────────────────────────────

  /// CDN download URL for a specific file in a repository.
  ///
  /// ```dart
  /// HFHub.downloadUrl('litert-community/Qwen3-0.6B', 'qwen3-0.6b-q4_1.litertlm')
  /// // → https://huggingface.co/litert-community/Qwen3-0.6B/resolve/main/qwen3-0.6b-q4_1.litertlm
  /// ```
  static String downloadUrl(
    String repoId,
    String filename, {
    String revision = 'main',
  }) =>
      '$_cdnBase/$repoId/resolve/$revision/$filename';

  /// Attempt to parse a HuggingFace URL into its `repoId` and `filename`.
  ///
  /// Returns `null` if the URL does not look like a HF file URL.
  ///
  /// Handles these patterns:
  /// - `https://huggingface.co/{owner}/{repo}/resolve/{rev}/{path}`
  /// - `https://huggingface.co/{owner}/{repo}/blob/{rev}/{path}`
  static ({String repoId, String filename, String revision})? parseUrl(
      String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (!uri.host.contains('huggingface.co')) return null;

    // /owner/repo/(resolve|blob)/rev/filename
    final parts = uri.pathSegments;
    if (parts.length >= 5 &&
        (parts[2] == 'resolve' || parts[2] == 'blob')) {
      final repoId = '${parts[0]}/${parts[1]}';
      final revision = parts[3];
      final filename = parts.sublist(4).join('/');
      return (repoId: repoId, filename: filename, revision: revision);
    }
    return null;
  }

  // ── Inference API ────────────────────────────────────────────────────────

  /// Base URL for the HF Serverless Inference API (new router endpoint).
  static String inferenceUrl(String modelId) =>
      'https://router.huggingface.co/hf-inference/models/$modelId/v1/chat/completions';

  // ── Private ───────────────────────────────────────────────────────────────

  static String? _resolveToken(String? explicit) {
    if (kIsWeb) return explicit; // env not available on web
    return explicit ??
        Platform.environment['HF_TOKEN'] ??
        Platform.environment['HUGGINGFACE_TOKEN'];
  }

  static Map<String, String> _headers(String? token) => {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static void _checkStatus(http.Response res, String repoId) {
    if (res.statusCode == 200) return;
    if (res.statusCode == 401) {
      throw HFException(
        'HTTP 401 for "$repoId". '
        'Set HF_TOKEN env var or pass hfToken: "<token>".',
        statusCode: 401,
      );
    }
    if (res.statusCode == 403) {
      throw HFException(
        'HTTP 403 for "$repoId". Accept the model license on '
        'huggingface.co and use a valid token.',
        statusCode: 403,
      );
    }
    if (res.statusCode == 404) {
      throw HFException(
        'Repository "$repoId" not found. Check the repo ID.',
        statusCode: 404,
      );
    }
    throw HFException('HTTP ${res.statusCode} for "$repoId": ${res.body}',
        statusCode: res.statusCode);
  }
}

/// Thrown when the HuggingFace API returns an error.
class HFException implements Exception {
  final String message;
  final int? statusCode;

  const HFException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode != null ? 'HFException($statusCode): $message' : 'HFException: $message';
}
