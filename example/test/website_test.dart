import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meridian_gallery/widgetbook.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

/// The landing page states facts about the library and links into
/// Widgetbook. These checks fail when either side changes alone.
void main() {
  final page = File('../webfront/index.html').readAsStringSync();
  final styles = File('../webfront/style.css').readAsStringSync();
  final script = File('../webfront/site.js').readAsStringSync();
  final paths = WidgetbookRoot(
    children: meridianDirectories(),
  ).leaves.whereType<WidgetbookUseCase>().map((node) => node.path).toSet();

  String hex(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  test('every Widgetbook link opens a use case', () {
    final linked = [
      ...RegExp(r'widgetbook/#/\?path=([a-z0-9/-]+)').allMatches(page),
      ...RegExp(r'data-path="([a-z0-9/-]+)"').allMatches(page),
      ...RegExp(r"path: '([a-z0-9/-]+)'").allMatches(script),
    ].map((match) => match.group(1)!).toList();
    expect(linked, isNotEmpty);
    for (final path in linked) {
      expect(paths, contains(path));
    }
  });

  test('the live preview offers the brands and themes that exist', () {
    final brands = RegExp(
      r'data-brand="([^"]+)"',
    ).allMatches(page).map((match) => match.group(1)).toList();
    expect(brands, [for (final brand in MeridianBrands.all) brand.name]);
    final themes = RegExp(
      r'data-theme="([^"]+)"',
    ).allMatches(page).map((match) => match.group(1)).toList();
    expect(themes, ['light', 'dark']);
  });

  test('the icon count is the size of the icon set', () {
    final counts = RegExp(
      r'(\d+)(?:</b><span>Lucide icons| icons)',
    ).allMatches(page).map((match) => int.parse(match.group(1)!)).toList();
    expect(counts, hasLength(2));
    expect(counts, everyElement(MeridianIcons.all.length));
  });

  test('each brand card names its accent and density', () {
    for (final brand in MeridianBrands.all) {
      final card = RegExp(
        '/ ${brand.name.toUpperCase()}</span>(.*?)</article>',
      ).firstMatch(page)?.group(1);
      expect(card, isNotNull, reason: brand.name);
      final accent = hex(brand.light.accent);
      expect(card, contains('<dd>${accent.toUpperCase()}</dd>'));
      expect(card, contains('<dd>${brand.density.name}</dd>'));
      expect(styles, contains('background:$accent'), reason: brand.name);
    }
  });

  test('the token swatches show the light core colours', () {
    final colors = MeridianColors.resolve(
      Brightness.light,
      MeridianBrands.gitlama.light,
    );
    final tokens = {
      'ground': colors.ground,
      'pane': colors.pane,
      'pane-alt': colors.paneAlt,
      'canvas': colors.canvas,
      'ink': colors.ink,
      'ink-muted': colors.inkMuted,
      'ink-faint': colors.inkFaint,
      'line-strong': colors.lineStrong,
      'success': colors.success,
      'warning': colors.warning,
      'attention': colors.attention,
      'danger': colors.danger,
    };
    for (final MapEntry(key: name, value: color) in tokens.entries) {
      expect(
        page,
        contains('<b>$name</b><code>${hex(color).toUpperCase()}</code>'),
      );
    }
    for (final color in colors.series) {
      expect(page, contains('<i style="background:${hex(color)}"></i>'));
    }
  });

  test('the density rows use the row heights', () {
    for (final density in MeridianDensity.values) {
      final height = density.rowExtent.round();
      expect(page, contains('<b>${density.name}</b><code>$height</code>'));
      expect(page, contains('style="--row:${height}px"'));
    }
  });
}
