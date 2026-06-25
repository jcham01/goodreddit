import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/util/reddit_text.dart';

void main() {
  group('normalizeSubredditKey', () {
    test('strips the r/ prefix in every shape and lowercases', () {
      expect(normalizeSubredditKey('cooking'), 'cooking');
      expect(normalizeSubredditKey('r/cooking'), 'cooking');
      expect(normalizeSubredditKey('/r/cooking'), 'cooking');
      expect(normalizeSubredditKey('R/Cooking'), 'cooking');
      expect(normalizeSubredditKey('  r/Cooking  '), 'cooking');
      expect(normalizeSubredditKey('FlutterDev'), 'flutterdev');
    });

    test('is idempotent', () {
      final once = normalizeSubredditKey('r/Cooking');
      expect(normalizeSubredditKey(once), once);
    });
  });

  group('isBrowsableSubreddit', () {
    test('accepts real subreddits, rejects profiles and empties', () {
      expect(isBrowsableSubreddit('flutterdev'), isTrue);
      expect(isBrowsableSubreddit('AskReddit'), isTrue);
      expect(isBrowsableSubreddit(''), isFalse);
      expect(isBrowsableSubreddit('u_spez'), isFalse);
      expect(isBrowsableSubreddit('U_Spez'), isFalse);
    });
  });
}
