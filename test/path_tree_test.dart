import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_ui/meridian_ui.dart';

/// A changed file as GitLama's commit and Changes lists carry it.
class _File {
  const _File(this.path, [this.status = 'M']);

  final String path;
  final String status;

  @override
  String toString() => path;
}

List<MeridianPathTreeRow<_File>> _flatten(
  List<_File> files, {
  Set<String> collapsed = const {},
  bool tree = true,
  int Function(_File, _File)? compareFiles,
}) => MeridianPathTree.flatten(
  files,
  pathOf: (file) => file.path,
  collapsed: collapsed,
  tree: tree,
  compareFiles: compareFiles,
);

/// `D name@depth` for folders, `F label@depth` for files.
List<String> _shape(List<MeridianPathTreeRow<_File>> rows) => [
  for (final row in rows)
    '${row.directory ? 'D' : 'F'} ${row.label}@${row.depth}',
];

void main() {
  const files = [
    _File('lib/src/widgets/button.dart'),
    _File('README.md'),
    _File('lib/main.dart'),
    _File('lib/src/app.dart'),
    _File('test/app_test.dart', 'A'),
    _File('lib/src/widgets/a/deep/nested/leaf.dart'),
    _File('CHANGELOG.md'),
  ];

  test('folders come first by name, then files by path, at every level', () {
    expect(_shape(_flatten(files)), [
      'D lib@0',
      'D src@1',
      'D widgets@2',
      'D a@3',
      'D deep@4',
      'D nested@5',
      'F leaf.dart@6',
      'F button.dart@3',
      'F app.dart@2',
      'F main.dart@1',
      'D test@0',
      'F app_test.dart@1',
      'F CHANGELOG.md@0',
      'F README.md@0',
    ]);
  });

  test('identities: the folder path, or the file\'s full path', () {
    final rows = _flatten(files);
    expect(
      [
        for (final row in rows)
          if (row.directory) row.identity,
      ],
      [
        'lib',
        'lib/src',
        'lib/src/widgets',
        'lib/src/widgets/a',
        'lib/src/widgets/a/deep',
        'lib/src/widgets/a/deep/nested',
        'test',
      ],
    );
    final leaf = rows.firstWhere((row) => row.label == 'leaf.dart');
    expect(leaf.identity, 'lib/src/widgets/a/deep/nested/leaf.dart');
    expect(leaf.item, files[5]);
    expect(rows.firstWhere((row) => row.label == 'lib').item, isNull);
  });

  test('a root file stays at depth 0 with its own name', () {
    final rows = _flatten(const [_File('pubspec.yaml')]);
    expect(_shape(rows), ['F pubspec.yaml@0']);
    expect(rows.single.identity, 'pubspec.yaml');
    expect(rows.single.descendants, isEmpty);
  });

  test('collapsed folders keep their row and hide everything below', () {
    expect(_shape(_flatten(files, collapsed: {'lib/src'})), [
      'D lib@0',
      'D src@1',
      'F main.dart@1',
      'D test@0',
      'F app_test.dart@1',
      'F CHANGELOG.md@0',
      'F README.md@0',
    ]);
    // A collapsed folder inside a collapsed folder changes nothing more,
    // and stays collapsed when its parent opens again.
    expect(_shape(_flatten(files, collapsed: {'lib', 'lib/src/widgets'})), [
      'D lib@0',
      'D test@0',
      'F app_test.dart@1',
      'F CHANGELOG.md@0',
      'F README.md@0',
    ]);
    expect(_shape(_flatten(files, collapsed: {'lib/src/widgets'})), [
      'D lib@0',
      'D src@1',
      'D widgets@2',
      'F app.dart@2',
      'F main.dart@1',
      'D test@0',
      'F app_test.dart@1',
      'F CHANGELOG.md@0',
      'F README.md@0',
    ]);
  });

  test('folders carry every file below them, collapsed or not', () {
    final rows = _flatten(files, collapsed: {'lib'});
    final lib = rows.firstWhere((row) => row.identity == 'lib');
    expect(lib.descendants.map((file) => file.path).toSet(), {
      'lib/main.dart',
      'lib/src/app.dart',
      'lib/src/widgets/button.dart',
      'lib/src/widgets/a/deep/nested/leaf.dart',
    });
    final open = _flatten(files);
    final widgets = open.firstWhere((row) => row.identity == 'lib/src/widgets');
    expect(widgets.descendants, [files[0], files[5]]);
    final nested = open.firstWhere(
      (row) => row.identity == 'lib/src/widgets/a/deep/nested',
    );
    expect(nested.descendants, [files[5]]);
    for (final row in open.where((row) => !row.directory)) {
      expect(row.descendants, isEmpty);
    }
  });

  test('backslashes separate folders and empty segments are dropped', () {
    final rows = _flatten(const [
      _File(r'src\core\main.c'),
      _File('src//core/util.c'),
      _File('/src/readme.txt/'),
    ]);
    expect(_shape(rows), [
      'D src@0',
      'D core@1',
      // Files sort by the path as given, as GitLama's lists did: '/' sorts
      // before '\'.
      'F util.c@2',
      'F main.c@2',
      'F readme.txt@1',
    ]);
    expect(rows[1].identity, 'src/core');
    // A file keeps its path as given as its identity.
    expect(rows[3].identity, r'src\core\main.c');
  });

  test('list mode: files only, sorted, full paths at depth 0', () {
    final rows = _flatten(files, tree: false, collapsed: {'lib'});
    expect(_shape(rows), [
      'F CHANGELOG.md@0',
      'F README.md@0',
      'F lib/main.dart@0',
      'F lib/src/app.dart@0',
      'F lib/src/widgets/a/deep/nested/leaf.dart@0',
      'F lib/src/widgets/button.dart@0',
      'F test/app_test.dart@0',
    ]);
    expect(rows.every((row) => !row.directory && row.item != null), isTrue);
    expect(rows.first.identity, 'CHANGELOG.md');
  });

  test('compareFiles orders files in both modes; folders stay by name', () {
    int byStatusThenPath(_File a, _File b) {
      final status = a.status.compareTo(b.status);
      return status != 0 ? status : a.path.compareTo(b.path);
    }

    const mixed = [
      _File('b.txt', 'M'),
      _File('a.txt', 'M'),
      _File('c.txt', 'A'),
      _File('z/x.txt', 'M'),
      _File('y/x.txt', 'M'),
    ];
    expect(_shape(_flatten(mixed, compareFiles: byStatusThenPath)), [
      'D y@0',
      'F x.txt@1',
      'D z@0',
      'F x.txt@1',
      'F c.txt@0',
      'F a.txt@0',
      'F b.txt@0',
    ]);
    expect(
      _shape(_flatten(mixed, tree: false, compareFiles: byStatusThenPath)),
      ['F c.txt@0', 'F a.txt@0', 'F b.txt@0', 'F y/x.txt@0', 'F z/x.txt@0'],
    );
  });

  test('no items, no rows', () {
    expect(_flatten(const []), isEmpty);
    expect(_flatten(const [], tree: false), isEmpty);
  });
}
