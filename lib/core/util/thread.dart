import 'package:goodreddit/features/reader/domain/entities/thread_item.dart';

/// Filters a depth-flattened thread, hiding every descendant of a collapsed
/// comment.
///
/// In a depth-first flattened thread, a node's descendants are exactly the
/// items that follow it with a strictly greater depth, up to the next item that
/// returns to the collapsed node's depth (a sibling) or shallower (an ancestor's
/// sibling). Nested collapses compose because reaching a shallower-or-equal node
/// clears the active threshold before that node is itself inspected.
List<ThreadItem> visibleThread(
  List<ThreadItem> items,
  Set<String> collapsedIds,
) {
  if (collapsedIds.isEmpty) return items;
  final out = <ThreadItem>[];
  int? hiddenBelowDepth; // when set, items deeper than this are hidden
  for (final item in items) {
    if (hiddenBelowDepth != null) {
      if (item.depth > hiddenBelowDepth) continue; // descendant: hide
      hiddenBelowDepth = null; // back to a sibling/ancestor: stop hiding
    }
    out.add(item);
    if (item is CommentNode && collapsedIds.contains(item.id)) {
      hiddenBelowDepth = item.depth;
    }
  }
  return out;
}

/// Number of descendants (replies, nested at any depth) of the comment at
/// [index] in a depth-flattened thread. Used to label a collapsed comment.
int descendantCount(List<ThreadItem> items, int index) {
  final base = items[index].depth;
  var count = 0;
  for (var i = index + 1; i < items.length; i++) {
    if (items[i].depth <= base) break;
    if (items[i] is CommentNode) count++;
  }
  return count;
}

/// Descendant-comment count for every [CommentNode] in one linear pass, keyed by
/// comment id. Equivalent to calling [descendantCount] for each node but O(n)
/// instead of O(n²) — compute it once per thread and reuse across rebuilds.
Map<String, int> descendantCounts(List<ThreadItem> items) {
  final counts = <String, int>{};
  final ids = <String>[];
  final depths = <int>[];
  final running = <int>[]; // descendant-comment count accumulated per open node

  void closeWhile(bool Function(int depth) shouldPop) {
    while (depths.isNotEmpty && shouldPop(depths.last)) {
      final id = ids.removeLast();
      depths.removeLast();
      final c = running.removeLast();
      counts[id] = c;
      if (running.isNotEmpty) running[running.length - 1] += c; // bubble up
    }
  }

  for (final item in items) {
    closeWhile((d) => d >= item.depth);
    if (item is CommentNode) {
      if (running.isNotEmpty) running[running.length - 1] += 1; // self
      ids.add(item.id);
      depths.add(item.depth);
      running.add(0);
    }
  }
  closeWhile((_) => true); // drain remaining open nodes
  return counts;
}
