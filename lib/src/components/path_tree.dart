/// One visible row of a [MeridianPathTree]: a folder or a file.
///
/// Build a fixed-extent list from the rows: indent each by [depth], show a
/// disclosure chevron on [directory] rows and toggle their [identity] in the
/// collapsed set.
class MeridianPathTreeRow<T> {
  const MeridianPathTreeRow.directory({
    required this.identity,
    required this.label,
    required this.depth,
    required this.descendants,
  }) : directory = true,
       item = null;

  const MeridianPathTreeRow.file({
    required T this.item,
    required this.identity,
    required this.label,
    required this.depth,
  }) : directory = false,
       descendants = const [];

  final bool directory;

  /// `a/b` for the folder `b` inside `a`; the item's full path for a file.
  /// Folder identities are what the collapsed set holds.
  final String identity;

  /// The segment name in a tree, the full path in a list.
  final String label;

  /// Nesting level; 0 at the root and for every row of a list.
  final int depth;

  /// The file's item; null for a folder.
  final T? item;

  /// Every file item below a folder, at any depth: what a folder's actions
  /// (stage, discard, copy) apply to. Empty for a file.
  final List<T> descendants;
}

/// Flattens items with '/'-separated paths into the visible rows of a file
/// list or tree. Pure logic: the app builds the rows' widgets.
abstract final class MeridianPathTree {
  /// The visible rows for [items].
  ///
  /// As a tree (the default) each path is split at `/` (backslashes count as
  /// `/`; empty segments are dropped). At every level the folders come
  /// first, sorted by name, then the files, sorted by [compareFiles]
  /// (default: [pathOf]). A folder whose identity is in [collapsed] keeps its
  /// row but hides everything below it.
  ///
  /// With `tree: false` the result is the files alone, sorted the same way,
  /// at depth 0 and labelled with their full path.
  static List<MeridianPathTreeRow<T>> flatten<T>(
    Iterable<T> items, {
    required String Function(T) pathOf,
    required Set<String> collapsed,
    bool tree = true,
    int Function(T, T)? compareFiles,
  }) {
    final compare =
        compareFiles ?? (T a, T b) => pathOf(a).compareTo(pathOf(b));
    if (!tree) {
      final files = items.toList()..sort(compare);
      return [
        for (final item in files)
          MeridianPathTreeRow<T>.file(
            item: item,
            identity: pathOf(item),
            label: pathOf(item),
            depth: 0,
          ),
      ];
    }

    final root = _Node<T>('', '');
    for (final item in items) {
      final parts = pathOf(item)
          .replaceAll('\\', '/')
          .split('/')
          .where((part) => part.isNotEmpty)
          .toList();
      var node = root;
      var identity = '';
      for (final part in parts.take(parts.length > 1 ? parts.length - 1 : 0)) {
        identity = identity.isEmpty ? part : '$identity/$part';
        node = node.directories.putIfAbsent(
          part,
          () => _Node<T>(part, identity),
        );
      }
      node.files.add((item: item, name: parts.isEmpty ? '' : parts.last));
    }

    final rows = <MeridianPathTreeRow<T>>[];
    void visit(_Node<T> node, int depth) {
      final directories = node.directories.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      for (final directory in directories) {
        rows.add(
          MeridianPathTreeRow<T>.directory(
            identity: directory.identity,
            label: directory.name,
            depth: depth,
            descendants: List.unmodifiable(directory.descendants),
          ),
        );
        if (!collapsed.contains(directory.identity)) {
          visit(directory, depth + 1);
        }
      }
      final files = node.files.toList()
        ..sort((a, b) => compare(a.item, b.item));
      for (final file in files) {
        rows.add(
          MeridianPathTreeRow<T>.file(
            item: file.item,
            identity: pathOf(file.item),
            label: file.name,
            depth: depth,
          ),
        );
      }
    }

    visit(root, 0);
    return rows;
  }
}

class _Node<T> {
  _Node(this.name, this.identity);

  final String name;
  final String identity;
  final Map<String, _Node<T>> directories = {};
  final List<({T item, String name})> files = [];

  List<T> get descendants => [
    for (final file in files) file.item,
    for (final directory in directories.values) ...directory.descendants,
  ];
}
