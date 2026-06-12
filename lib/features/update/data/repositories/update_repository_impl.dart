import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/update/data/datasources/github_release_datasource.dart';
import 'package:goodreddit/features/update/domain/entities/app_update.dart';
import 'package:goodreddit/features/update/domain/repositories/update_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateRepositoryImpl implements UpdateRepository {
  final GithubReleaseDataSource dataSource;

  UpdateRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, AppUpdate?>> checkForUpdate() async {
    try {
      final latest = await dataSource.fetchLatestRelease();
      final info = await PackageInfo.fromPlatform();
      final isNewer = _compareVersions(latest.version, info.version) > 0;
      return Right(isNewer ? latest : null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  /// Compares dotted numeric versions (`1.2.0` vs `1.10`). Returns >0 when
  /// [a] is newer than [b]. Non-numeric segments compare as 0.
  int _compareVersions(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final length = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < length; i++) {
      final da = i < pa.length ? pa[i] : 0;
      final db = i < pb.length ? pb[i] : 0;
      if (da != db) return da - db;
    }
    return 0;
  }
}
