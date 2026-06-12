import 'dart:convert';

import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/history/data/models/research_session_model.dart';
import 'package:hive/hive.dart';

/// Persists research sessions in a Hive box, keyed by session id. Values are
/// JSON strings so the schema can evolve without Hive type adapters.
abstract class SessionLocalDataSource {
  Future<List<ResearchSessionModel>> getAll();
  Future<void> save(ResearchSessionModel session);
  Future<void> delete(String id);
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  static const boxName = 'research_sessions';

  final Box<String> box;

  SessionLocalDataSourceImpl({required this.box});

  @override
  Future<List<ResearchSessionModel>> getAll() async {
    try {
      final sessions =
          box.values
              .map(
                (raw) => ResearchSessionModel.fromJson(
                  jsonDecode(raw) as Map<String, dynamic>,
                ),
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      throw CacheException('Failed to read sessions: $e');
    }
  }

  @override
  Future<void> save(ResearchSessionModel session) async {
    try {
      await box.put(session.id, jsonEncode(session.toJson()));
    } catch (e) {
      throw CacheException('Failed to save session: $e');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await box.delete(id);
    } catch (e) {
      throw CacheException('Failed to delete session: $e');
    }
  }
}
