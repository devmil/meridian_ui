import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meridian_ui/meridian_ui.dart';

/// Build with `--dart-define=MERIDIAN_SCREENSHOTS=true` to render the whole
/// gallery page for every brand, both themes, and regular and touch
/// density to PNG files, then quit.
const screenshotMode = bool.fromEnvironment('MERIDIAN_SCREENSHOTS');

/// One screenshot's settings.
typedef GalleryShot = ({
  MeridianBrand brand,
  Brightness brightness,
  MeridianDensity density,
});

const _densities = [MeridianDensity.regular, MeridianDensity.touch];

/// Applies each combination with [apply], waits for it to settle and writes
/// what [page] paints. Files go to a `meridian-gallery` folder in the
/// (sandboxed) temporary directory; the path is printed.
Future<void> captureGallery({
  required GlobalKey page,
  required Future<void> Function(GalleryShot shot) apply,
}) async {
  final dir = Directory('${Directory.systemTemp.path}/meridian-gallery')
    ..createSync(recursive: true);
  var first = true;
  for (final brand in MeridianBrands.all) {
    for (final brightness in Brightness.values) {
      for (final density in _densities) {
        await apply((brand: brand, brightness: brightness, density: density));
        // Let icons load and state animations finish.
        await Future<void>.delayed(Duration(milliseconds: first ? 2000 : 700));
        first = false;
        await WidgetsBinding.instance.endOfFrame;
        final boundary =
            page.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(
          pixelRatio:
              ui.PlatformDispatcher.instance.views.first.devicePixelRatio,
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        final name = '${brand.id}-${brightness.name}-${density.name}.png';
        File('${dir.path}/$name').writeAsBytesSync(png!.buffer.asUint8List());
        debugPrint('meridian-gallery: wrote ${dir.path}/$name');
      }
    }
  }
  debugPrint('meridian-gallery: done ${dir.path}');
  exit(0);
}
