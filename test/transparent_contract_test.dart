import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `Colors.transparent` is transparent *black*. A fill, edge or rule that
/// animates between it and a light colour passes through translucent grey:
/// a dark flash on every hover. Animated "no paint" must be
/// `meridianClear(<the colour it animates to>)`.
///
/// Components may pass `Colors.transparent` only as a `rest:` to
/// `MeridianInteractionState.fill` (which normalizes it) or at the static
/// sites listed here, which never animate.
void main() {
  const staticSites = {
    // Progress track and overlay chrome: painted, never animated.
    "color: widget.track ? meridian.colors.line : Colors.transparent,",
    'backgroundColor: Colors.transparent,',
    'color: elevated ? colors.line : Colors.transparent,',
    // Keycap and quiet count: no transition.
    'color: onAccent ? Colors.transparent : colors.paneAlt,',
    'MeridianCountTone.quiet => (Colors.transparent, colors.inkMuted),',
  };

  test('animated fills never start or end at transparent black', () {
    final violations = <String>[];
    final files = Directory(
      'lib/src/components',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (!line.contains('Colors.transparent') ||
            line.startsWith('//') ||
            line.startsWith('rest: Colors.transparent') ||
            staticSites.contains(line)) {
          continue;
        }
        violations.add('${file.path}:${i + 1}: $line');
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Use meridianClear(<target colour>) for animated "no paint":\n'
          '${violations.join('\n')}',
    );
  });
}
