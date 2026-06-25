import 'package:equatable/equatable.dart';

class Post extends Equatable {
  final String id;
  final String title;
  final String selfText;
  final String author;
  final int score;
  final int numComments;
  final String url;
  final String permalink;
  final DateTime createdAt;
  final String? flair;
  final bool isStickied;

  // Reader/feed fields (an aggregated feed mixes many subreddits, so a post
  // must carry its own subreddit and presentation hints).
  final String subreddit; // bare name, e.g. "flutterdev"
  final String? thumbnail; // raw value; may be a sentinel ("self", "default"…)
  final String? preview; // large preview image URL (HTML-entity decoded)
  final bool isVideo;
  final bool over18;
  final bool spoiler;
  final bool locked;
  final double? upvoteRatio;

  const Post({
    required this.id,
    required this.title,
    required this.selfText,
    required this.author,
    required this.score,
    required this.numComments,
    required this.url,
    required this.permalink,
    required this.createdAt,
    this.flair,
    this.isStickied = false,
    this.subreddit = '',
    this.thumbnail,
    this.preview,
    this.isVideo = false,
    this.over18 = false,
    this.spoiler = false,
    this.locked = false,
    this.upvoteRatio,
  });

  /// A usable image URL, or null when Reddit returned a sentinel
  /// ("self", "default", "nsfw", "spoiler", "image", "") instead of a URL.
  String? get thumbnailUrl {
    final t = thumbnail;
    if (t == null || !t.startsWith('http')) return null;
    return t;
  }

  /// Full permalink on www.reddit.com.
  String get fullPermalink => 'https://www.reddit.com$permalink';

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    score,
    numComments,
    subreddit,
    over18,
    spoiler,
    locked,
    isVideo,
    isStickied,
    flair,
    thumbnail,
    preview,
    upvoteRatio,
  ];
}
