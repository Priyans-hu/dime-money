import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String apkDownloadUrl;

  const UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.apkDownloadUrl,
  });
}

class UpdateChecker {
  static const _repo = 'Priyans-hu/dime-money';
  static const _apiUrl =
      'https://api.github.com/repos/$_repo/releases/latest';

  /// Compare semver strings. Returns true if [remote] > [local].
  /// Handles formats like "0.3.0", "v0.3.1", "0.4.0+5".
  static bool _isNewer(String remote, String local) {
    final r = _parseSemver(remote);
    final l = _parseSemver(local);
    for (var i = 0; i < 3; i++) {
      if (r[i] > l[i]) return true;
      if (r[i] < l[i]) return false;
    }
    return false;
  }

  /// Parse "v0.3.1+5" → [0, 3, 1]. Strips leading 'v' and trailing '+N'.
  static List<int> _parseSemver(String version) {
    final cleaned = version.replaceAll(RegExp(r'^v'), '').split('+').first;
    final parts = cleaned.split('.');
    return List.generate(3, (i) => int.tryParse(i < parts.length ? parts[i] : '0') ?? 0);
  }

  /// Check GitHub releases for a newer version.
  /// Returns [UpdateInfo] if an update is available, null otherwise.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? '';

      final packageInfo = await PackageInfo.fromPlatform();
      if (!_isNewer(tagName, packageInfo.version)) return null;

      // Find the APK asset
      final assets = data['assets'] as List<dynamic>? ?? [];
      String? apkUrl;
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = asset['browser_download_url'] as String?;
          break;
        }
      }
      if (apkUrl == null) return null;

      return UpdateInfo(
        version: tagName.replaceAll(RegExp(r'^v'), ''),
        releaseNotes: body,
        apkDownloadUrl: apkUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Download APK and open it to trigger Android installer.
  static Future<void> downloadAndInstall(
    String url,
    void Function(int received, int total) onProgress,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? -1;
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/dime_money_update.apk';
      final file = File(filePath);
      final sink = file.openWrite();

      var receivedBytes = 0;
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes, totalBytes);
      }
      await sink.close();

      await OpenFilex.open(filePath);
    } finally {
      client.close();
    }
  }
}
