import 'package:goodreddit/features/update/domain/entities/app_update.dart';

class AppUpdateModel extends AppUpdate {
  const AppUpdateModel({
    required super.version,
    super.apkUrl,
    super.releaseNotes,
  });

  /// Parses the GitHub `releases/latest` API response.
  factory AppUpdateModel.fromGithubJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final assets = (json['assets'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final apk = assets.where(
      (a) => (a['name'] as String? ?? '').toLowerCase().endsWith('.apk'),
    );
    final body = (json['body'] as String?)?.trim();

    return AppUpdateModel(
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      apkUrl: apk.isEmpty ? null : apk.first['browser_download_url'] as String?,
      releaseNotes: (body == null || body.isEmpty) ? null : body,
    );
  }
}
