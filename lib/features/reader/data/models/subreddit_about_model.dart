import 'package:goodreddit/core/error/exceptions.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';

class SubredditAboutModel extends SubredditAbout {
  const SubredditAboutModel({
    required super.name,
    super.title,
    super.publicDescription,
    super.subscribers,
    super.activeUsers,
    super.iconUrl,
    super.over18,
    super.fullname,
    super.userIsSubscriber,
  });

  /// Parses the `t5` "about" thing: `{kind:'t5', data:{...}}` (or a bare data
  /// map).
  ///
  /// A missing/banned subreddit answers `about.json` with HTTP 200 and a
  /// `Listing` body (no `display_name`); reject that as "not found" rather than
  /// surfacing a degenerate empty header.
  factory SubredditAboutModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final name = (data['display_name'] ?? '') as String;
    if (name.isEmpty) {
      throw const RedditException('Subreddit not found');
    }
    return SubredditAboutModel(
      name: name,
      title: (data['title'] ?? '') as String,
      publicDescription: (data['public_description'] ?? '') as String,
      subscribers: (data['subscribers'] as num?)?.toInt() ?? 0,
      activeUsers: (data['active_user_count'] as num?)?.toInt(),
      iconUrl: _icon(data),
      over18: data['over18'] == true || data['over_18'] == true,
      fullname: data['name'] as String?, // t5_…
      userIsSubscriber: data['user_is_subscriber'] as bool?,
    );
  }

  /// Prefer the styled `community_icon`, fall back to the legacy `icon_img`.
  /// Both are HTML-entity encoded and may be empty strings.
  static String? _icon(Map<String, dynamic> data) {
    for (final key in ['community_icon', 'icon_img']) {
      final raw = data[key];
      if (raw is String && raw.startsWith('http')) {
        return raw.replaceAll('&amp;', '&');
      }
    }
    return null;
  }
}
