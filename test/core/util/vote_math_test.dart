import 'package:flutter_test/flutter_test.dart';
import 'package:goodreddit/core/util/vote_math.dart';

void main() {
  group('VoteDir', () {
    test('fromLikes maps the tri-state', () {
      expect(VoteDir.fromLikes(true), VoteDir.up);
      expect(VoteDir.fromLikes(false), VoteDir.down);
      expect(VoteDir.fromLikes(null), VoteDir.none);
    });

    test('delta and apiDir', () {
      expect(VoteDir.up.delta, 1);
      expect(VoteDir.none.delta, 0);
      expect(VoteDir.down.delta, -1);
      expect(VoteDir.up.apiDir, '1');
      expect(VoteDir.none.apiDir, '0');
      expect(VoteDir.down.apiDir, '-1');
    });
  });

  group('nextVote — Reddit toggle semantics', () {
    test('tapping the active arrow clears, tapping the other switches', () {
      expect(nextVote(VoteDir.none, VoteDir.up), VoteDir.up);
      expect(nextVote(VoteDir.none, VoteDir.down), VoteDir.down);
      expect(nextVote(VoteDir.up, VoteDir.up), VoteDir.none); // toggle off
      expect(nextVote(VoteDir.up, VoteDir.down), VoteDir.down); // switch
      expect(nextVote(VoteDir.down, VoteDir.down), VoteDir.none);
      expect(nextVote(VoteDir.down, VoteDir.up), VoteDir.up);
    });
  });
}
