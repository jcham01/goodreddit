import 'package:equatable/equatable.dart';

/// Subreddit "about" metadata (from `/r/<sub>/about.json`, a `t5` thing).
class SubredditAbout extends Equatable {
  final String name; // bare display_name, e.g. "flutterdev"
  final String title;
  final String publicDescription;
  final int subscribers;
  final int? activeUsers;
  final String? iconUrl;
  final bool over18;

  const SubredditAbout({
    required this.name,
    this.title = '',
    this.publicDescription = '',
    this.subscribers = 0,
    this.activeUsers,
    this.iconUrl,
    this.over18 = false,
  });

  @override
  List<Object?> get props => [
    name,
    title,
    publicDescription,
    subscribers,
    activeUsers,
    iconUrl,
    over18,
  ];
}
