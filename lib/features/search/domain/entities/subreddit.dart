import 'package:equatable/equatable.dart';

class Subreddit extends Equatable {
  final String name;
  final String displayName;
  final String title;
  final String description;
  final int subscribers;
  final int activeUsers;
  final String url;
  final DateTime? createdAt;
  final bool isNsfw;

  const Subreddit({
    required this.name,
    required this.displayName,
    required this.title,
    required this.description,
    required this.subscribers,
    required this.activeUsers,
    required this.url,
    this.createdAt,
    this.isNsfw = false,
  });

  @override
  List<Object?> get props => [
    name,
    displayName,
    title,
    description,
    subscribers,
    activeUsers,
    url,
    createdAt,
    isNsfw,
  ];
}
