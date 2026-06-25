import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/features/scraper/data/models/post_model.dart';

void main() {
  group('PostModel.fromJson — interaction seed fields', () {
    test('reads name, tri-state likes, saved, and score_hidden', () {
      final p = PostModel.fromJson({
        'data': {
          'id': 'abc',
          'name': 't3_abc',
          'title': 'T',
          'subreddit': 's',
          'score': 12,
          'likes': true,
          'saved': true,
          'score_hidden': true,
        },
      });
      expect(p.name, 't3_abc');
      expect(p.fullname, 't3_abc');
      expect(p.likes, isTrue);
      expect(p.saved, isTrue);
      expect(p.scoreHidden, isTrue);
    });

    test('likes stays null when absent; hide_score alias is honored', () {
      final p = PostModel.fromJson({
        'data': {'id': 'x', 'hide_score': true},
      });
      expect(p.likes, isNull);
      expect(p.saved, isFalse);
      expect(p.scoreHidden, isTrue);
    });

    test('likes:false means downvoted', () {
      final p = PostModel.fromJson({
        'data': {'id': 'd', 'likes': false},
      });
      expect(p.likes, isFalse);
    });

    test('fullname synthesizes t3_<id> when name is absent', () {
      final p = PostModel.fromJson({
        'data': {'id': 'q'},
      });
      expect(p.name, isNull);
      expect(p.fullname, 't3_q');
    });

    test('toJson round-trips the new fields', () {
      final p = PostModel.fromJson({
        'data': {'id': 'a', 'name': 't3_a', 'likes': false, 'saved': true},
      });
      final json = p.toJson();
      expect(json['name'], 't3_a');
      expect(json['likes'], isFalse);
      expect(json['saved'], isTrue);
      expect(json['score_hidden'], isFalse);
    });
  });
}
