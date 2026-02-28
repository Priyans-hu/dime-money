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

  /// Returns true if [remoteBuildNumber] > [localBuildNumber].
  /// Build numbers are monotonically increasing integers (the +N in pubspec).
  static bool _isNewer(int remoteBuildNumber, int localBuildNumber) {
    return remoteBuildNumber > localBuildNumber;
  }

  /// Extract build number from release tag or name.
  /// Looks for "+N" suffix first, then checks release body for "build: N".
  /// Falls back to 0 if not found.
  static int _extractBuildNumber(Map<String, dynamic> releaseData) {
    final tagName = releaseData['tag_name'] as String? ?? '';
    final body = releaseData['body'] as String? ?? '';

    // Check tag for +N suffix (e.g. v0.3.0+3)
    final plusMatch = RegExp(r'\+(\d+)').firstMatch(tagName);
    if (plusMatch != null) return int.parse(plusMatch.group(1)!);

    // Check release body for "build: N" or "Build: N"
    final bodyMatch =
        RegExp(r'[Bb]uild:\s*(\d+)').firstMatch(body);
    if (bodyMatch != null) return int.parse(bodyMatch.group(1)!);

    // Fallback: use the APK filename pattern (e.g. app-release-3.apk)
    final assets = releaseData['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      final nameMatch = RegExp(r'(\d+)\.apk$').firstMatch(name);
      if (nameMatch != null) return int.parse(nameMatch.group(1)!);
    }

    return 0;
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
      final localBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final remoteBuild = _extractBuildNumber(data);
      if (!_isNewer(remoteBuild, localBuild)) return null;

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
