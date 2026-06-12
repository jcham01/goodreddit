import 'package:dartz/dartz.dart';
import 'package:goodreddit/core/error/failures.dart';
import 'package:goodreddit/features/update/domain/entities/app_update.dart';

abstract class UpdateRepository {
  /// Returns the latest published version when it is newer than the
  /// installed one, or `Right(null)` when the app is up to date.
  Future<Either<Failure, AppUpdate?>> checkForUpdate();
}
