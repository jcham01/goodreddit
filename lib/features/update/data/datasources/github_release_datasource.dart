import 'package:dio/dio.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/update/data/models/app_update_model.dart';

abstract class GithubReleaseDataSource {
  /// Fetches the latest published release of [ApiConstants.githubRepo].
  Future<AppUpdateModel> fetchLatestRelease();
}

class GithubReleaseDataSourceImpl implements GithubReleaseDataSource {
  final Dio dio;

  GithubReleaseDataSourceImpl({required this.dio});

  @override
  Future<AppUpdateModel> fetchLatestRelease() async {
    try {
      final response = await dio.get<Map<String, dynamic>>(
        ApiConstants.latestReleaseUrl,
        options: Options(
          headers: {'Accept': 'application/vnd.github+json'},
        ),
      );
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty GitHub release response');
      }
      return AppUpdateModel.fromGithubJson(data);
    } on DioException catch (e) {
      // 404 also covers "no release published yet" — treated as no update.
      throw ServerException('GitHub release check failed: ${e.message}');
    }
  }
}
