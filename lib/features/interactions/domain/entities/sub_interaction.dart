import 'package:equatable/equatable.dart';
import 'package:goodreddit/features/reader/domain/entities/subreddit_about.dart';

/// Per-subreddit subscribe state, keyed (externally, in the store map) by the
/// lowercased subreddit name. Same baseline+overlay derivation as
/// [PostInteraction], so the member count never double-counts on re-seed.
class SubInteraction extends Equatable {
  final String srName;
  final String? fullname; // t5_…

  final int baseSubscribers;
  final bool baseSubscribed;

  final bool subscribed; // user overlay
  final bool pending;

  const SubInteraction({
    required this.srName,
    this.fullname,
    required this.baseSubscribers,
    required this.baseSubscribed,
    required this.subscribed,
    this.pending = false,
  });

  factory SubInteraction.seed(SubredditAbout about) {
    final subscribed = about.userIsSubscriber == true;
    return SubInteraction(
      srName: about.name,
      fullname: about.fullname,
      baseSubscribers: about.subscribers,
      baseSubscribed: subscribed,
      subscribed: subscribed,
    );
  }

  /// Member count adjusted by the overlay, clamped at zero.
  int get displaySubscribers {
    final n = baseSubscribers + (subscribed ? 1 : 0) - (baseSubscribed ? 1 : 0);
    return n < 0 ? 0 : n;
  }

  bool get diverges => subscribed != baseSubscribed;

  SubInteraction copyWith({
    String? srName,
    String? fullname,
    int? baseSubscribers,
    bool? baseSubscribed,
    bool? subscribed,
    bool? pending,
  }) {
    return SubInteraction(
      srName: srName ?? this.srName,
      fullname: fullname ?? this.fullname,
      baseSubscribers: baseSubscribers ?? this.baseSubscribers,
      baseSubscribed: baseSubscribed ?? this.baseSubscribed,
      subscribed: subscribed ?? this.subscribed,
      pending: pending ?? this.pending,
    );
  }

  @override
  List<Object?> get props => [
    srName,
    fullname,
    baseSubscribers,
    baseSubscribed,
    subscribed,
    pending,
  ];
}
