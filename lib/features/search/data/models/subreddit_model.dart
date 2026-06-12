import 'package:goodreddit/features/search/domain/entities/subreddit.dart';

class SubredditModel extends Subreddit {
  const SubredditModel({
    required super.name,
    required super.displayName,
    required super.title,
    required super.description,
    required super.subscribers,
    required super.activeUsers,
    required super.url,
    super.createdAt,
    super.isNsfw,
  });

  factory SubredditModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return SubredditModel(
      name: data['display_name'] ?? '',
      displayName:
          data['display_name_prefixed'] ?? 'r/${data['display_name'] ?? ''}',
      title: data['title'] ?? '',
      description: data['public_description'] ?? data['description'] ?? '',
      subscribers: data['subscribers'] ?? 0,
      activeUsers: data['accounts_active'] ?? data['active_user_count'] ?? 0,
      url: data['url'] ?? '',
      createdAt: data['created_utc'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['created_utc'] as num).toInt() * 1000,
            )
          : null,
      isNsfw: data['over18'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': name,
      'display_name_prefixed': displayName,
      'title': title,
      'public_description': description,
      'subscribers': subscribers,
      'accounts_active': activeUsers,
      'url': url,
      'created_utc': createdAt != null
          ? createdAt!.millisecondsSinceEpoch ~/ 1000
          : null,
      'over18': isNsfw,
    };
  }
}
