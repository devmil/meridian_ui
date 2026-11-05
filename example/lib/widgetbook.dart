import 'package:flutter/material.dart';
import 'package:meridian_ui/meridian_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'widgetbook/actions.dart';
import 'widgetbook/addon.dart';
import 'widgetbook/containers.dart';
import 'widgetbook/data.dart';
import 'widgetbook/display.dart';
import 'widgetbook/feedback.dart';
import 'widgetbook/foundation.dart';
import 'widgetbook/inputs.dart';
import 'widgetbook/motion.dart';
import 'widgetbook/navigation.dart';

void main() => runApp(const MeridianWidgetbook());

/// The navigation tree. Built anew for each Widgetbook, because a node keeps
/// a reference to its parent.
List<WidgetbookNode> meridianDirectories() => [
  foundationFolder(),
  actionsFolder(),
  inputsFolder(),
  navigationFolder(),
  displayFolder(),
  feedbackFolder(),
  containersFolder(),
  dataFolder(),
  documentsFolder(),
  motionFolder(),
];

/// Inspect isolated Meridian states across brands, themes, and densities.
class MeridianWidgetbook extends StatelessWidget {
  const MeridianWidgetbook({super.key, this.initialRoute = '/'});

  final String initialRoute;

  @override
  Widget build(BuildContext context) => Widgetbook.material(
    initialRoute: initialRoute,
    addons: [
      ViewportAddon([
        Viewports.none,
        IosViewports.iPhone13,
        IosViewports.iPad,
        MacosViewports.macbookPro,
      ]),
      ...meridianAddons(),
      TextScaleAddon(min: 0.8, max: 2, divisions: 6),
      InspectorAddon(),
    ],
    home: const _Home(),
    directories: meridianDirectories(),
  );
}

/// The page shown before a use case is chosen.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => Theme(
    data: buildMeridianTheme(
      brand: MeridianBrands.gitlama,
      brightness: Theme.of(context).brightness,
    ),
    child: Builder(
      builder: (context) {
        final meridian = context.meridian;
        final muted = meridian.text.body.copyWith(
          color: meridian.colors.inkMuted,
        );
        return MeridianGround(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(MeridianSpace.space8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: MeridianIsland(
                  padding: const EdgeInsets.all(MeridianSpace.space8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meridian', style: meridian.text.display),
                      const SizedBox(height: MeridianSpace.space3),
                      Text(
                        'Every primitive on its own, for every brand, theme '
                        'and density.',
                        style: muted,
                      ),
                      const SizedBox(height: MeridianSpace.space8),
                      for (final (icon, title, text) in const [
                        (
                          MeridianIcons.listTree,
                          'Choose a component',
                          'The navigation lists the primitives by group. '
                              'Foundation holds colours, type and icons.',
                        ),
                        (
                          MeridianIcons.slidersHorizontal,
                          'Turn the knobs',
                          'A Playground use case exposes the properties of a '
                              'component. The address keeps your settings, so '
                              'a state can be shared as a link.',
                        ),
                        (
                          MeridianIcons.palette,
                          'Switch the brand',
                          'The addons set brand, theme and density, slow '
                              'motion down and turn on reduced motion.',
                        ),
                      ]) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MeridianIcon(icon, color: meridian.colors.accent),
                            const SizedBox(width: MeridianSpace.space5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: meridian.text.bodyStrong),
                                  const SizedBox(height: MeridianSpace.space1),
                                  Text(text, style: muted),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: MeridianSpace.space6),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
