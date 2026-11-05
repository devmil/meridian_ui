import 'package:meridian_ui/meridian_ui.dart';

/// Category runs for the gallery's short Dart samples. An app gets these
/// from a real parser; this only marks keywords, strings, comments, numbers
/// and called names so the previews show every common colour.
Map<int, List<MeridianSyntaxRun>> sampleSyntax(List<String> lines) {
  final pattern = RegExp(
    r'(//.*$)|("(?:[^"\\]|\\.)*")|\b(import|void|final|const|class|return)\b'
    r'|\b(\d+)\b|\b([A-Za-z_]\w*)(?=\()|([=;.(){}])',
  );
  return {
    for (final (index, line) in lines.indexed)
      index: [
        for (final match in pattern.allMatches(line))
          MeridianSyntaxRun(
            match.start,
            match.end,
            match.group(1) != null
                ? MeridianSyntaxKind.comment
                : match.group(2) != null
                ? MeridianSyntaxKind.string
                : match.group(3) != null
                ? MeridianSyntaxKind.keyword
                : match.group(4) != null
                ? MeridianSyntaxKind.number
                : match.group(5) != null
                ? MeridianSyntaxKind.function
                : MeridianSyntaxKind.punctuation,
          ),
      ],
  };
}
