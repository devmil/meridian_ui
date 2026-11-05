import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> raster(String family, ui.FontWeight weight) async {
  final builder =
      ui.ParagraphBuilder(
        ui.ParagraphStyle(textDirection: ui.TextDirection.ltr),
      )..pushStyle(
        ui.TextStyle(
          fontFamily: family,
          fontWeight: weight,
          fontSize: 30,
          color: const ui.Color(0xff000000),
        ),
      );
  builder.addText('ÄÖÜ 0123456789');
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: 320));
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawParagraph(paragraph, ui.Offset.zero);
  final picture = recorder.endRecording();
  final image = await picture.toImage(320, 80);
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return Uint8List.fromList(bytes.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
    paragraph.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Mono licence notice is included in runtime assets', () async {
    final notice = await rootBundle.loadString('assets/fonts/OFL.txt');
    expect(notice, contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(notice, contains('The JetBrains Mono Project Authors'));
  });
  test('Mono weight requests select the authentic bundled face', () async {
    const faces = [
      ('Regular', ui.FontWeight.w400),
      ('Medium', ui.FontWeight.w500),
      ('Bold', ui.FontWeight.w700),
    ];
    final family = FontLoader('packages/meridian_ui/JetBrains Mono');
    for (final (name, _) in faces) {
      final data = rootBundle.load('assets/fonts/JetBrainsMono-$name.ttf');
      family.addFont(data);
      await (FontLoader('proof.$name')..addFont(data)).load();
    }
    await family.load();
    final results = <Uint8List>[];
    for (final (name, weight) in faces) {
      final actual = await raster(
        'packages/meridian_ui/JetBrains Mono',
        weight,
      );
      final expected = await raster('proof.$name', weight);
      expect(actual, orderedEquals(expected), reason: name);
      expect(actual.where((value) => value != 0), isNotEmpty);
      results.add(actual);
    }
    expect(results[0], isNot(orderedEquals(results[1])));
    expect(results[1], isNot(orderedEquals(results[2])));
  });
}
