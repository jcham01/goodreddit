import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/interactions/domain/entities/post_interaction.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

PostInteraction _pi({
  int baseScore = 10,
  VoteDir baseDir = VoteDir.none,
  VoteDir voteDir = VoteDir.none,
  bool baseSaved = false,
  bool saved = false,
}) => PostInteraction(
  baseScore: baseScore,
  baseDir: baseDir,
  baseSaved: baseSaved,
  voteDir: voteDir,
  saved: saved,
);

void main() {
  group('displayScore = baseScore - baseDir + voteDir', () {
    test('covers the baseDir × voteDir matrix', () {
      expect(_pi(baseDir: VoteDir.none, voteDir: VoteDir.up).displayScore, 11);
      expect(_pi(baseDir: VoteDir.none, voteDir: VoteDir.down).displayScore, 9);
      expect(_pi(baseDir: VoteDir.up, voteDir: VoteDir.none).displayScore, 9);
      expect(_pi(baseDir: VoteDir.up, voteDir: VoteDir.down).displayScore, 8);
      expect(_pi(baseDir: VoteDir.down, voteDir: VoteDir.up).displayScore, 12);
      expect(_pi(baseDir: VoteDir.up, voteDir: VoteDir.up).displayScore, 10);
      expect(_pi(baseDir: VoteDir.none, voteDir: VoteDir.none).displayScore, 10);
    });
  });

  group('diverges', () {
    test('true only when the overlay differs from the baseline', () {
      expect(_pi().diverges, isFalse);
      expect(_pi(voteDir: VoteDir.up).diverges, isTrue);
      expect(_pi(baseSaved: false, saved: true).diverges, isTrue);
      expect(
        _pi(baseDir: VoteDir.up, voteDir: VoteDir.up, baseSaved: true, saved: true)
            .diverges,
        isFalse,
      );
    });
  });

  group('seed', () {
    test('mirrors the post baseline into the overlay', () {
      final p = Post(
        id: 'a',
        name: 't3_a',
        title: 't',
        selfText: '',
        author: 'u',
        score: 42,
        numComments: 0,
        url: '',
        permalink: '/p',
        createdAt: DateTime(2020),
        likes: true,
        saved: true,
      );
      final pi = PostInteraction.seed(p);
      expect(pi.baseScore, 42);
      expect(pi.baseDir, VoteDir.up);
      expect(pi.voteDir, VoteDir.up);
      expect(pi.saved, isTrue);
      expect(pi.displayScore, 42);
      expect(pi.diverges, isFalse);
    });
  });
}
