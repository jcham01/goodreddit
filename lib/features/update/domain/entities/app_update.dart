import 'package:equatable/equatable.dart';

/// A newer app version published as a GitHub release.
class AppUpdate extends Equatable {
  /// Version of the release, without the leading `v` (e.g. `1.2.0`).
  final String version;

  /// Direct download URL of the `.apk` asset, if the release has one.
  final String? apkUrl;

  /// Release notes (the release body), if any.
  final String? releaseNotes;

  const AppUpdate({
    required this.version,
    this.apkUrl,
    this.releaseNotes,
  });

  @override
  List<Object?> get props => [version, apkUrl, releaseNotes];
}
