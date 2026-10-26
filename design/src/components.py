#!/usr/bin/env python3
"""Writes design/project/components/<Name>/README.md and preview.html for every
Meridian component. Guidelines and previews live together here so they stay in step
with the Flutter widgets in lib/src/components/."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "design" / "project" / "components"

C = []  # (name, group, height, readme, preview_js)


def add(name, group, height, readme, js):
    C.append((name, group, height, readme.strip() + "\n", js.strip()))


# ------------------------------------------------------------------ Actions
add("Button", "Actions", 140, """
# Button

A labelled command. Flutter: `MeridianButton`.

The density's control height is a minimum. Enlarged text grows the button to
fit its label line and vertical padding; surrounding rows must permit that
height instead of clipping it back to the unscaled extent.

- **primary** at most once per island or screen, for the thing it exists to do (Send, Export, Commit). **secondary** is the default. **quiet** for inline and low-stakes actions. **danger** only inside a confirming dialog; in rows and headers use **dangerQuiet**.
- The consumer provides: `label` (verb plus object, sentence case: "Move 3 messages to archive", never "OK"), `onPressed` (`null` disables), optional `icon` (or `leading`, a small picture where no Lucide glyph fits: a colour dot, a pen preset), `trailingIcon`, `shortcut` (keys shown inside the button; `shortcutReveal: whileModifierHeld` shows them only while the modifier is held), `loading` (keeps the label, swaps the icon for a spinner), `disabledReason` (the tooltip that says why), `size: small` in island headers and rows, `expand` for full-width buttons on touch.
- `success` is edge-triggered: set it after confirmed output, then reset it before another operation. By default the leading icon becomes a check for `motion-hold`. `successReplacesLabel: true` crossfades the whole label and decorations to a centred check over `motion-quick`, keeping the content mounted so width and the accessible command name stay unchanged. Reduced motion keeps the crossfade with a static check.
- `onSuccessFinished` reports the completed hold once, bound to the callback supplied when `success` turned true. Starting `loading`, clearing `success`, or unmounting cancels the report. The consumer owns output success and any close action; do not report or retry external output from this presentation callback.
- `iconOnly` requires an icon and preserves the accessible label, tooltip, delayed spinner, confirmation and focus while drawing only the icon at the density control extent. Change this property on the existing owner during responsive layout; padding switches with the geometry so shrinking cannot temporarily squeeze the icon.
- The width follows the label; never fix it, German runs up to 40% longer.
- Height `size-control` (28px), `size-control-sm` (22px) small, `size-control-touch` (44px) at touch density with a 48px hit target. `label` type, `radius-md`, `space-5` padding.
- States: hover `pane-hover` (primary brightens), pressed adds 4% `ink`, keyboard focus a 2px `focus` ring 1px outside, disabled `ink-faint` on no fill (primary: `ink-muted` on `accent-soft`).
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h('div', { className: 'mr-row' },
    h(M.Button, { variant: 'primary', shortcut: ['⌘', '↵'] }, 'Move 3 messages to archive'),
    h(M.Button, { icon: 'download' }, 'Export'),
    h(M.Button, { variant: 'quiet', icon: 'copy' }, 'Copy ID'),
    h(M.Button, { variant: 'danger' }, 'Delete notebook'),
    h(M.Button, { variant: 'danger-quiet', icon: 'undo-2' }, 'Discard')),
  h('div', { className: 'mr-row' },
    h(M.Button, { loading: true }, 'Syncing…'),
    h(M.Button, { disabled: true }, 'Send'),
    h(M.Button, { variant: 'primary', disabled: true }, 'Commit'),
    h(M.Button, { size: 'sm', icon: 'list-filter' }, 'Filter'),
    h(M.Button, { size: 'sm', variant: 'quiet', trailingIcon: 'chevron-down' }, 'Newest first'),
    h(M.ButtonConfirmationDemo))));
""")

add("SplitButton", "Actions", 120, """
# SplitButton

A default command with separately reachable alternatives. Flutter:
`MeridianSplitButton`. The primary half uses Button; the caret uses IconButton
and anchors the menu to the whole compound control.

- Supply localized `label`, `optionsLabel`, `entries`, `onPressed`, and an `icon`
  for `compact` mode. `primaryKey` and `optionsKey` identify the two controls.
- `onPressed: null` disables only the default command. `optionsEnabled` controls
  the caret independently; unsupported folder Save must not hide file Save As.
- `loading` suppresses primary activation while retaining its focus, and uses
  Button's delayed spinner. `success` uses Button's edge-triggered confirmation.
  The menu remains independently available; consumers disable affected entries.
- Compact mode keeps the accessible command name and renders an icon with the
  same loading/confirmation owner. It is a primary Button, not a copied spinner.
- Keep both controls in start-to-end reading order and let labels grow at 200%
  text. Escape dismisses the menu and returns keyboard focus to its caret.
- Size, rank, focus nodes and disabled reasons follow the existing primitives.
  The consumer owns output, busy admission, localization and menu decisions.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.SplitButton, { icon: 'save', optionsLabel: 'Save options', entries: ['Save as…', 'Copy as file'] }, 'Save')));
""")

add("IconButton", "Actions", 72, """
# IconButton

A single-icon command for toolbars, island headers and row hover actions. Flutter: `MeridianIconButton`.

- The consumer provides `icon`, a required `label` (the tooltip and the accessible name), `onPressed`, `size: small` in rows and headers, `active` for toggles (`accent-soft` fill, `accent-ink` icon) and `onGround` when it sits on `ground` (hover `ground-hover`; defaults to the surface it is in).
- Hover follows the surface: on a hovered or selected row (or inside a field) the button darkens that fill instead of painting `pane-hover`, so it never vanishes into a hovered row. Rows publish their fill through `MeridianSurfaceScope`; a custom table wraps its cells in `MeridianSurfaceScope.withFill`.
- `canRequestFocus: false` for row actions of a tree or table and find-bar arrows: a click leaves keyboard focus with the list or field. Offer the same command through the list's keys or menu.
- Idle icons are `ink-muted` and turn `ink` on hover. On a solid `accent` fill (a focused selection) they are `on-accent-muted` and turn `on-accent` on hover, whatever `color` asks for, so row actions stay visible on the selected row. Use an icon button only where the icon is unambiguous (search, close, more, pin). Anything else is a Button with a label.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.IconButton, { icon: 'search', label: 'Search' }),
  h(M.IconButton, { icon: 'layout-grid', label: 'Show as grid', active: true }),
  h(M.IconButton, { icon: 'list', label: 'Show as list', active: false }),
  h(M.IconButton, { icon: 'ellipsis', label: 'More' }),
  h(M.IconButton, { icon: 'pin', label: 'Pin', size: 'sm' }),
  h(M.IconButton, { icon: 'archive', label: 'Archive', size: 'sm' }),
  h(M.IconButton, { icon: 'trash-2', label: 'Delete', disabled: true })));
""")

add("ToolbarButton", "Actions", 80, """
# ToolbarButton

A primary command in a desktop title bar: an 18px icon (1.75 stroke) over a `caption` label, on `ground`. Flutter: `MeridianToolbarButton`.

- The consumer provides `icon`, `label`, `onPressed`, an optional `badge` (a count to act on, shown as an `accent` Count) and `menu` (a split caret for variants: Send → Send later, Pull → Rebase) with `menuLabel` naming the caret ("More send options"). The badge is read as the button's value; the menu opens under the whole split button and at least as wide.
- Commands go left, the app's centre piece (GitLama's Compass, a search field) in the middle, view toggles and settings right as IconButtons. No border; hover `ground-hover`. Hide the caption with `showLabel: false` in narrow windows; the label stays the tooltip.
- A click does not take focus, as in native title bars: focus stays where the person was working, and a dialog the command opens hands it back there. Tab still reaches the buttons.
""", """
mount(h('div', { className: 'mr-demo' },
  h(M.ToolbarButton, { icon: 'square-plus', label: 'New' }),
  h(M.ToolbarButton, { icon: 'refresh-cw', label: 'Refresh', badge: 4 }),
  h(M.ToolbarButton, { icon: 'send', label: 'Send', menu: true }),
  h(M.ToolbarButton, { icon: 'archive', label: 'Archive' }),
  h(M.ToolbarButton, { icon: 'trash-2', label: 'Delete', disabled: true })));
""")

add("FloatingButton", "Actions", 110, """
# FloatingButton

The one prominent command of a touch screen that floats over its content: create a notebook, compose a message. Flutter: `MeridianFloatingButton`.

- The consumer provides `icon`, `label` (always the tooltip and the accessible name), `onPressed` (`null` disables it) and `extended` to show the label next to the icon.
- `accent` fill with an `on-accent` icon, `radius-lg`, `shadow-float`, 56px square (a pill when extended); hover brightens like a primary Button, pressed adds 4% `ink`. Disabled: `ink-muted` on `accent-soft`, no shadow.
- At most one per screen, at the bottom trailing corner (`space-8` in), clear of the content's last row. Desktop layouts put the command in the toolbar instead.
""", """
mount(h('div', { className: 'mr-demo mr-touch' },
  h(M.FloatingButton, { icon: 'plus', label: 'New notebook' }),
  h(M.FloatingButton, { icon: 'scan-line', label: 'Scan pages', extended: true }),
  h(M.FloatingButton, { icon: 'plus', label: 'New notebook', disabled: true })));
""")

# ------------------------------------------------------------------ Inputs
add("ShortcutField", "Inputs", 220, """
# Shortcut field

An explicitly armed keyboard recorder. Flutter: `MeridianShortcutField`.

- The consumer supplies localized `label`, `emptyLabel`, `recordingLabel`,
  `preparingLabel` and `clearLabel`, displayed `keys`, controlled `recording`
  and `preparing` state, record/cancel/clear callbacks and an optional `conflict`
  slot. `showLabel: false` keeps the accessible label in a settings row.
- The application owns registration, validation, conflicts and persistence.
  Suspend global shortcut admission before setting `recording: true`. Use
  `preparing` while that admission drains. Close or retire the recording owner
  when its surface unmounts; the primitive owns only its two focus nodes.
- One real non-modifier key-down emits a `MeridianShortcutStroke` with physical
  and logical key identities and modifier booleans; it never copies the typed
  character. Modifier-only, synthesized and repeated events do not emit.
- Unmodified Escape cancels. Plain Tab and Shift+Tab cancel and leave normal
  traversal intact. The application may support modified Escape/Tab chords.
  Losing capture focus or disabling the field cancels; the application decides
  when to exit recording after an accepted stroke.
- Keycaps wrap at narrow widths. Height is the density control minimum and grows
  with enlarged text. Clear is a separately named keyboard/semantic action;
  disabled fields record and clear nothing. Conflict content is a live region.
- Use Meridian interaction fills and focus feedback, `control-edge`, `pane`,
  `radius-md`, body/label text, space-3/4 and `MeridianKbd`. Do not put native
  hotkey registration, OS key-name assumptions or app error codes in the field.
""", """
mount(h('div', { className: 'mr-demo pane start' },
  h(M.ShortcutFieldDemo, { label: 'Capture area', keys: ['Ctrl', 'Shift', '4'], width: 260 }),
  h(M.ShortcutFieldDemo, { label: 'History', width: 260 }),
  h(M.ShortcutFieldDemo, { label: 'Unavailable', keys: ['Ctrl', 'H'], disabled: true, width: 260 })));
""")

add("TextField", "Inputs", 180, """
# TextField

Single- or multi-line text input. Flutter: `MeridianTextField`.

- The consumer provides `label` (above the field; in a settings row the row's label is used instead), `placeholder`, `controller`/`onChanged`, optional leading `icon`, `trailingText` (match counter, character count) or a `trailing` widget, `variant: search`, `size: small`, `monospace` for identifiers and paths, `minLines`/`maxLines` for multi-line (`minLines` alone grows without limit), `expands` to fill a bounded height (an editor pane), `scrollController` to read and drive a multi-line field's scroll offset (an editor kept in step with a neighbouring pane), `height` for a taller single-line field that leads a form (a composer's subject line), `error` and `message`. `showLabel: false` keeps the label as the accessible name without showing it, for a palette query or a filter beside its list. `fieldKey` keys the inner editable field for tests; `spellCheckConfiguration` turns on the platform spell checker for prose.
- The edge is `control-edge` (3:1). Focus paints a `focus` edge plus a 1px `focus` ring. The **search** variant is a filled `pane-alt` well with no edge until focused, for filters in island headers and toolbars.
- An `error` replaces the message: a `danger` edge and one `caption` line that says what is wrong and how to fix it ("Enter a host name without https://"). Never a floating label, never a Material outline.
- Density and explicit single-line `height` are minimums. The field grows to fit its actual text style and ambient text scale plus both border edges; never constrain its parent below that line height. Multi-line sizing is unchanged.
- In a Row, give the field a `width` or wrap it in Expanded.
- The **plain** variant has no edge, well, ring or inset: it types inside a surface that is already a field, such as the chips of a recipient field.
- `clearLabel` adds a clear button (its tooltip and accessible name) while the field holds text: search and filter fields. `onTap` reports taps, for a field that opens more options.
- `underlay` paints marks inside the well under the text, its selection and the caret, filling the text area: an editor's line marks such as a merge result's chosen blocks. Keep marks clear of `accent-soft`, the selection colour, so a selection over a mark stays visible. The underlay takes no taps and is not announced; the consumer keeps it in step with the text and `scrollController`.
- It brings its own Material ancestor, so it works on a `MeridianGround` without a Scaffold.
- Inside a Dialog a single-line field submits the dialog: Enter runs the dialog's primary action (or shakes the dialog when that action is disabled) and focus stays in the field. A field with its own `onSubmitted`, a multi-line or read-only field keeps Enter. Set `submitsDialog: false` for a field whose Enter means something else (adding a chip, picking a suggestion).
""", """
mount(h('div', { className: 'mr-demo pane start' },
  h(M.TextField, { label: 'Display name', placeholder: 'Michael', message: 'Shown to people you write to.', width: 240 }),
  h(M.TextField, { label: 'Server', value: 'https://cloud.example.org', error: 'Enter a host name without https://', width: 240 }),
  h(M.TextField, { variant: 'search', placeholder: 'Filter processes', trailing: '12 / 480', width: 220 }),
  h(M.TextField, { variant: 'search', value: 'invoice', clear: 'Clear search', width: 220 }),
  h(M.TextField, { label: 'Notes', multiline: true, rows: 2, placeholder: 'Add a note', width: 240 })));
""")

add("Checkbox", "Inputs", 96, """
# Checkbox

An option that applies when a command runs ("Include attachments", "Sign this commit"). Flutter: `MeridianCheckbox`.

- The consumer provides `label`, `value`, `onChanged` (`null` disables), optional `description` (a `caption` line) and `tristate` for a partial selection (`null` value shows the mixed state, announced as mixed rather than checked).
- 16px box, `control-edge` border, `accent` fill with an `on-accent` check when on. Clicking the label toggles it; Space toggles it when focused.
- Settings that apply straight away are Switches, not checkboxes.
""", """
mount(h('div', { className: 'mr-demo pane start', style: { gap: 'var(--space-7)' } },
  h(M.Checkbox, { checked: true }, 'Include attachments'),
  h(M.Checkbox, { mixed: true }, 'Some pages selected'),
  h(M.Checkbox, { description: 'Uses your saved signing key.' }, 'Sign this commit'),
  h(M.Checkbox, { disabled: true, checked: true }, 'Encrypt (always on)')));
""")

add("Switch", "Inputs", 72, """
# Switch

A setting that applies straight away ("Check mail automatically", "Show live CPU tint"). Flutter: `MeridianSwitch`.

- The consumer provides `label` (required: it is also the accessible name), `value`, `onChanged`, an optional `description` (a `caption` line under the label, read as the hint), `showLabel: false` when a settings row already shows the label, `labelFirst` for touch settings lists (label left, track at the end).
- Track `line-strong` with a `control-edge` edge when off, `accent` when on; the thumb is `pane`. It grows at touch density. The change is confirmed by the switch itself: no Save button, no toast.
""", """
mount(h('div', { className: 'mr-demo pane', style: { gap: 'var(--space-7)' } },
  h(M.Switch, { checked: true }, 'Check mail automatically'),
  h(M.Switch, { description: 'One finger writes; two fingers scroll and zoom.' }, 'Finger drawing'),
  h(M.Switch, null, 'Show live CPU tint'),
  h(M.Switch, { disabled: true }, 'Sync over mobile data')));
""")

add("Radio", "Inputs", 110, """
# Radio

One choice from a short, visible set (two to five options). Flutter: `MeridianRadio` (build a group as a column of radios sharing `groupValue`).

- The consumer provides `value`, `groupValue`, `onChanged`, `label` and an optional `description`.
- Round 16px, `accent` fill with an `on-accent` centre dot when chosen. More than five options, or options that switch a view, go to Select or Segmented.
""", """
mount(h('div', { className: 'mr-demo pane start' },
  h(M.RadioGroup, { label: 'Message list', value: 'thread', options: [
    { value: 'thread', label: 'Group by conversation', description: 'Replies stay under the first message.' },
    { value: 'flat', label: 'Show every message' }] })));
""")

add("Segmented", "Inputs", 72, """
# Segmented

Picks one of two to four peer options that change a view: list or tree, day or week, light or dark. Flutter: `MeridianSegmented` with `MeridianSegment`s.

- The consumer provides `label` (the group's accessible name), `segments` (`value`, `label` and/or `icon`; icon-only segments need a `tooltip`), `value`, `onChanged`, `size: small`, `expand` to fill the width on touch. Without `expand` the control hugs its labels; in a space narrower than that, the segments share it and ellipsize their labels rather than overflow.
- Density sets the minimum track height. Larger text grows the tiles and the track to fit the scaled labels; a narrow control ellipsizes horizontally and never clips the glyphs vertically.
- Track `pane-alt` with a `line` edge; the selected segment is a `pane` tile with a `line-strong` edge and `shadow-control`. Arrow keys move the selection. With `manualActivation` they move only the focus ring, and Space or Enter selects: use it when a change is expensive (a filter that reloads a list). The focus ring shows for the keyboard only, never after a click; at touch density each segment is a 48px target.
- A segment with `enabled: false` is an option that exists but is unavailable right now: its label and icon read `ink-faint`, it takes no click, tap, Space or Enter, and the arrow keys (and Home and End) step over it. Its `tooltip` says why and still shows on hover; screen readers hear its label as a disabled button. It may be the selected value: the tile stays on it, with muted ink. Hide an option instead when it never applies here.
- Never for commands. More than four options is a Select.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.Segmented, { label: 'Layout', value: 'list', options: [{ value: 'list', label: 'List', icon: 'list' }, { value: 'tree', label: 'Tree', icon: 'list-tree' }, { value: 'grid', icon: 'layout-grid', tooltip: 'Grid' }] }),
  h(M.Segmented, { label: 'Theme', value: 'dark', options: [{ value: 'light', label: 'Light', icon: 'sun' }, { value: 'dark', label: 'Dark', icon: 'moon' }, { value: 'system', label: 'System', icon: 'monitor' }] }),
  h(M.Segmented, { label: 'Range', size: 'sm', value: '1m', options: [{ value: '1m', label: '1 min' }, { value: '5m', label: '5 min' }, { value: '1h', label: '1 h' }] }),
  h(M.Segmented, { label: 'View', value: 'list', options: [{ value: 'list', label: 'List' }, { value: 'tree', label: 'Tree' }, { value: 'graph', label: 'Graph', disabled: true, tooltip: 'Needs a repository' }] })));
""")

add("Slider", "Inputs", 100, """
# Slider

A continuous value: stroke width, zoom, opacity, a before/after comparison. Flutter: `MeridianSlider`.

- The consumer provides `label`, `value`, `onChanged`, `min`/`max`, optional `step` (snapping and the keyboard step; default 5% of the range), `valueLabel` (how to announce the value: "2.5 pt") and `onChangeEnd` (called with the final value after a drag, a tap or each keyboard step).
- A 2px `line-strong` rail with an `accent` fill and a 12px `pane` thumb ringed in `accent` (20px at touch density). Arrow keys (following the reading direction), Home and End move it. `min == max` is allowed; without a bounded width it takes 160px. Show the number next to it when the exact value matters.
- `track` replaces the rail and fill with a gradient for a colour channel (hue, red, brightness): 8px tall (12px at touch density) with a 1px `line-strong` edge. Build it with `AlignmentDirectional` ends so it turns with a right-to-left slider.
""", """
mount(h('div', { className: 'mr-demo pane col' },
  h('div', { className: 'mr-row' }, h('span', { style: { width: 110 } }, 'Stroke width'), h(M.Slider, { label: 'Stroke width', value: 0.35, width: 220 }), h('span', { className: 'mr-caption mr-numeric' }, '2.5 pt')),
  h('div', { className: 'mr-row' }, h('span', { style: { width: 110 } }, 'Opacity'), h(M.Slider, { label: 'Opacity', value: 0.8, width: 220 }), h('span', { className: 'mr-caption mr-numeric' }, '80%'))));
""")

add("RangeSlider", "Inputs", 100, "# Range slider\n\nSelect an interval with `MeridianRangeSlider` and immutable `MeridianRangeValues`.\n\n- Provide distinct localized `startLabel` and `endLabel`, ordered `values`, and `onChanged`. The consumer owns the confirmed values; use `onChangeEnd` to commit a completed gesture. `valueLabel` announces domain units. `min`, `max` and optional `step` share the slider contract.\n- The handles never cross. Clicking the rail selects the nearest endpoint; coincident handles retain the last focused endpoint. Each handle has its own keyboard focus and slider semantics. Tab visits start then end, arrows follow reading direction, Home/End reach that handle's permitted bounds.\n- A null callback or zero span disables input. An unbounded parent uses the default slider width. Use the standard density thumb and hit-height tokens, accent interval fill, line-strong rail, keyboard focus ring and MM-15 thumb emphasis. Reduced motion removes enlargement.\n- Preview is a static design specimen. Flutter owns interaction and accessible stepping.\n", "mount(h('div', {className:'mr-demo pane col'}, h('div', {className:'mr-row'}, h('span', {style:{width:110}}, 'Interval'), h(M.RangeSlider, {startLabel:'Range start',endLabel:'Range end',start:0.2,end:0.8,width:220}), h('span', {className:'mr-caption mr-numeric'}, '20–80%'))));")

add("Select", "Inputs", 250, """
# Select

A trigger that shows the current value and opens a Menu of the choices, the current one checked. Flutter: `MeridianSelect`.

- The consumer provides `value`, `values`, `valueLabel`, `onChanged`, an accessible `label` ("Sort by"), optional `width`, `minWidth` and `size: small`. In forms and dialogs set `showLabel` to show the label above the trigger (as a TextField does) and `expand` to fill the width.
- Without a `width` the trigger fits its longest choice, at least `minWidth` (160px), so it keeps its size when the value changes; the chevron sits at the trailing edge. Pass `minWidth: 0` for a picker that usually holds one short name (a remote).
- Density sets the minimum trigger height. Larger text increases it to fit the scaled value and vertical padding; a narrow trigger ellipsises horizontally and never clips the glyphs vertically.
- The trigger looks like a secondary Button: `pane`, `line-strong` edge, `shadow-control`, `chevron-down` in `ink-muted`. The menu opens below it (above when there is no room) and is at least as wide as the trigger.
- Use it for five or more options, or for fewer when they do not switch a view (sort order, account, language).
""", """
mount(h('div', { className: 'mr-demo pane start col' },
  h(M.Select, { value: 'Newest first', label: 'Sort by' }),
  h(M.Menu, { width: 200, items: [
    { label: 'Newest first', checked: true, highlighted: true },
    { label: 'Oldest first', checked: false },
    { label: 'Sender', checked: false },
    { label: 'Size', checked: false }] })));
""")

add("ColorSwatch", "Inputs", 90, """
# ColorSwatch

One colour in a palette: a pen colour, a cover colour, a label colour. Flutter: `MeridianColorSwatch`; build a palette as a `Wrap` of swatches `space-2` apart.

- The consumer provides `color` (content, not a theme token: it never changes with the theme), `label` (names the colour for the tooltip and assistive technology: "Blue", "Ink #18304F"), `selected` and `onPressed` (`null` disables it).
- A disc with a 1px `line-strong` edge, so white still reads on white; hover darkens the edge to `ink-muted`. Selected adds a check in a colour that contrasts with the disc and a 2px `accent` ring 2px outside. 24px, 32px at touch density with a 48px target. Disabled fades the disc to 50%.
- Selection is also announced (selected state), never shown by colour alone.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.ColorSwatch, { color: '#18304F', label: 'Ink', selected: true }),
  h(M.ColorSwatch, { color: '#24715C', label: 'Green' }),
  h(M.ColorSwatch, { color: '#315FA6', label: 'Blue' }),
  h(M.ColorSwatch, { color: '#943A55', label: 'Plum' }),
  h(M.ColorSwatch, { color: '#F4D864', label: 'Yellow', light: true }),
  h(M.ColorSwatch, { color: '#FFFFFF', label: 'White', light: true }),
  h(M.ColorSwatch, { color: '#444B55', label: 'Graphite', disabled: true })));
""")

add("ColorPicker", "Inputs", 1000, """
# ColorPicker

Choosing any colour by eye or by number: a pen, a label, a highlight. Flutter: `MeridianColorPicker`. Offer a short palette of `ColorSwatch`es first; open the picker (in a dialog, sheet or popover) for everything else.

- The consumer provides `color` (content, not a theme token; the picker keeps its alpha), `onChanged` (every drag and keystroke; `null` disables it), `onChangeEnd` (when a drag ends, a swatch is chosen, a hex value is submitted or a slider steps: save here), optional `original` (the colour before the edit, which a tap restores), `groups` (titled rows of swatches: a palette, recent colours, colours already in the document; empty rows are left out), `model` (the sliders start on HSB or RGB) and `labels` (every string; each unset one comes from Meridian's own English or German strings, by locale; see Localization below).
- From the top: the groups, a hue and saturation wheel (hue around the centre, saturation outwards, always at full brightness so dark colours are still picked by eye; 200px, 240px at touch density, narrower in a narrow space), the original colour above the new one beside the hex field, a Segmented control for HSB or RGB, and three sliders with gradient `track`s showing each channel's range, each with its name in `caption` and its value in `label` type.
- The wheel's thumb shows the colour in a 3px `pane` ring with a 1px `ink` edge, so it reads on any hue. A drag on the wheel never scrolls the surface it sits in.
- Every value can be set exactly from the keyboard: the wheel turns the hue a degree with Left and Right and moves the saturation a percent with Up and Down (ten with Shift); the sliders step one degree, percent or level; the hex field takes `#RRGGBB`, `RRGGBB` or `#RGB` and shows an error until a valid value is submitted or the colour changes.
- A grey or black keeps the hue the wheel was turned to, so turning the brightness back up returns the same hue.
- `layout` arranges it: `stacked` puts the wheel above the controls (a sheet, a narrow panel), `wide` puts it at the start with the hex field, model and sliders beside it, `space-8` apart (a desktop dialog or popover). `auto`, the default, is `wide` from 440px at a desktop density and `stacked` otherwise.
- **Localization.** Meridian's widgets that show their own words (the picker, the find bar, the colour names, the split pane's value) read `MeridianLocalizations`: English and German ship with the library and follow the nearest locale with no setup. Add `MeridianLocalizations.delegate` to the app's `localizationsDelegates` to resolve them with the app's catalogs, or put a `MeridianLocalizationsScope` above a subtree to supply another language. A label passed to a widget always wins.
""", """
mount(h('div', { className: 'mr-demo pane start col' },
  h(M.ColorPicker, { wide: true, width: 440, original: '#943A55', groups: [
    { title: 'Palette', colors: ['#18304F', '#0B6477', '#315FA6', '#943A55', '#444B55', '#F4D864'], light: ['#F4D864'] }] }),
  h(M.ColorPicker, { original: '#943A55', groups: [
    { title: 'Palette', colors: ['#18304F', '#0B6477', '#315FA6', '#943A55', '#444B55', '#F4D864'], light: ['#F4D864'] },
    { title: 'Recent', colors: ['#1A5F3C', '#C2410C'] }] })));
""")

add("ColorWell", "Inputs", 90, """
# ColorWell

Any other colour, beside a palette: the swatch at the end of a row of `ColorSwatch`es that opens a `ColorPicker` in a popover, as a desktop app offers a custom colour. Flutter: `MeridianColorWell`.

- The consumer provides `color` (the custom colour, `null` while there is none), `label` ("Custom colour"), `onChanged` (every change while the picker is open, so the owner shows it at once; `null` disables the well), optional `onChangeEnd`, `selected` (the custom colour is the chosen one), `initial` (where the picker starts without a `color`: usually the palette colour in use) and the picker's `groups`, `model` and `labels`.
- A swatch-sized disc of hues around the custom colour, edged and ringed like a `ColorSwatch`; without a colour, the hues around a `pane` centre with a plus. Selected adds the 2px `accent` ring.
- Its popover is 472px wide and holds a wide `ColorPicker` with the colour before the edit as its original. A click outside or Escape closes it and focus returns to the well. Keep a Cancel in the surrounding dialog: changes apply while the popover is open.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.ColorSwatch, { color: '#315FA6', label: 'Blue' }),
  h(M.ColorSwatch, { color: '#24715C', label: 'Green' }),
  h(M.ColorSwatch, { color: '#943A55', label: 'Plum' }),
  h(M.ColorWell, { color: '#C2410C', label: 'Custom colour', selected: true }),
  h(M.ColorWell, { label: 'Custom colour' })));
""")

# ------------------------------------------------------------------ Menus
add("Suggestions", "Inputs", 230, """
# Suggestions

Wrap the search field and results in `MeridianResultNavigation` to keep typing focus while Up/Down wrap the selected index and Enter activates it. The owner resets selection when filtering, scrolls the selected row into view, and rejects disabled actions. Empty lists consume these keys without activation.

Completions under a field while the person types: branch names, recipients, tags, paths. Flutter: `MeridianSuggestionSurface` with `MeridianSuggestionRow` and `MeridianSuggestionHeader`.

- The field keeps keyboard focus and the caret. Up and Down move the highlight, Enter or Tab accepts it, Escape closes the list; the rows never take focus. A pointer click accepts a row directly.
- A row provides `label`, `onTap`, optional `icon` or `leading` (a picture such as a recipient's avatar), `hint` (where it comes from: a remote, a path) and `highlighted` for the one Enter accepts. Group rows under `MeridianSuggestionHeader`s (`overline`, in capitals) when they come from different sources.
- `raised`, `radius-xl`, `shadow-float`, `space-2` padding, at most 240px tall (`maxHeight`) and scrolling beyond that; rows at the density's row height. The highlighted row is solid `accent` with `on-accent` text and `on-accent-muted` hint, like a keyboard-highlighted menu row; hover paints `pane-hover`.
- It is a form control, not a menu: it filters as the person types and never holds commands. For a fixed list of choices use Select; for commands use Menu.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h(M.TextField, { label: 'Base branch', value: 'fea', icon: 'git-branch', width: 280 }),
  h(M.Suggestions, { width: 280, items: [
    { type: 'header', label: 'Local branches' },
    { label: 'feature/search', hint: 'ahead 3', icon: 'git-branch', highlighted: true },
    { label: 'feature/offline-sync', icon: 'git-branch' },
    { type: 'header', label: 'Remote branches' },
    { label: 'origin/feature/search', hint: 'origin', icon: 'cloud' },
  ] }),
  h(M.Suggestions, { width: 280, items: [
    { label: 'Ada Lovelace', hint: 'ada@example.com', avatar: 'Ada Lovelace', highlighted: true },
    { label: 'Charles Babbage', hint: 'charles@example.com', avatar: 'Charles Babbage' },
  ] })));
""")

add("Menu", "Menus", 300, """
# Menu

A floating list of commands, for context menus, split buttons and Select. Flutter: `MeridianMenuAnchor` (wraps a trigger), `showMeridianContextMenu` (at the pointer), `MeridianMenuSurface` (docked), with `MeridianMenuItem`, `MeridianMenuHeader`, `MeridianMenuDivider` and `MeridianMenuCustom`.

- An item provides `label` with the object's real name ("Move Quarterly report to archive"), `onSelected` (`null` disables; it runs after the menu has closed, so it may open a dialog), optional `icon` or `leading` (a picture in the icon slot: a label's colour dot, an avatar), `shortcut`, `hint` (a count or path at the right), `checked`, `danger`, and `labelStyle` for an item that previews itself (a font set in that font).
- Anchored and context menus dispatch selection once after the reverse transition finishes and the route's overlay entries are removed. Completing the route's result alone is too early for follow-up UI. Cancellation or an unmounted invoking context does not dispatch a selected action.
- An item with `children` opens a submenu beside its row (before it when there is no room), after the pointer rests on it for 200ms, with →, Enter or a click. ← and Escape close it again; choosing an item in it closes the whole menu. A chevron marks such items. Keep submenus one level deep where you can: "Move to" with the folders, "Label as" with the labels.
- `MeridianMenuCustom` holds a short block of the app's own content that is not a command, such as the person a contact menu is about. The arrow keys and type-ahead skip it.
- `raised`, `radius-xl`, `shadow-float`, `space-2` padding, rows at the density's row height. The highlighted row is solid `accent` with `on-accent` text. Arrow keys, Home and End move the highlight (scrolling it into view), typing the first letters of a label jumps to it, Enter runs it, Escape closes (`onDismiss` on a docked `MeridianMenuSurface`). Opened from the keyboard, it starts on the checked item (else the first); opened by pointer, nothing is highlighted (`initialHighlight`).
- Order: the most common command first, groups under `overline` headers or split by dividers, destructive commands last in `danger` after a divider. Every hover action in a row also appears in its context menu.
- Desktop apps may keep OS-native menus (GitLama does). Put a `MeridianMenuPresenter` above the app and every Meridian menu (anchors, split toolbar buttons, Select, context menus) goes to its `present` callback with the same entries: order, headers, dividers, checked state, shortcuts and `danger`. The presenter shows the native menu at the anchor (items with `children` as native submenus) and runs the chosen item's `onSelected` after it has closed. A menu with a `MeridianMenuCustom` block stays a Meridian menu, since a native menu cannot show it. Its optional `textContextMenuBuilder` replaces the cut, copy and paste toolbar of every `MeridianTextField` the same way.
""", """
mount(h('div', { className: 'mr-demo start' },
  h(M.Menu, { items: [
    { type: 'header', label: 'Message' },
    { label: 'Reply', icon: 'reply', shortcut: ['⌘', 'R'] },
    { label: 'Forward', icon: 'forward', highlighted: true },
    { label: 'Move to archive', icon: 'archive', hint: 'A' },
    { label: 'Label as', icon: 'tag', submenu: true },
    { label: 'Mark as spam', icon: 'shield-alert', disabled: true },
    { type: 'divider' },
    { label: 'Delete message', icon: 'trash-2', danger: true }] })));
""")

# ------------------------------------------------------------------ Navigation
add("Popover", "Menus", 260, """
# Popover

A floating panel under a trigger for a small task that is more than a list of commands: a filtered folder picker, a label picker with check boxes, a colour palette. Flutter: `MeridianPopoverAnchor` (wraps a trigger), `showMeridianPopover` (at a rect, returns what the content pops), `MeridianPopoverSurface` (docked).

- The consumer provides the content and optionally `width` (280px by default) and `maxHeight` (the content scrolls beyond it). The content owns its focus; the popover's route autofocuses into it.
- `raised`, `radius-xl`, `shadow-float`, like Menu. It opens below the trigger (above when there is no room). Escape and a click outside close it; the content closes it with `Navigator.pop`, optionally with a result.
- `showMeridianPopover` returns that result after the reverse transition and overlay removal complete. Wait for it before resizing the host, releasing caller-owned presentation state or opening follow-up UI; check that the invoking context is still mounted before using it.
- Use a Menu for commands; use a popover when the content needs a field, check boxes or its own layout. Keep it to one task; bigger work belongs in a Dialog.
""", """
mount(h('div', { className: 'mr-demo start' },
  h(M.Popover, { width: 260 },
    h(M.TextField, { variant: 'search', placeholder: 'Filter folders', width: 236 }),
    h(M.Menu, { items: [
      { label: 'Inbox', icon: 'inbox', highlighted: true },
      { label: 'Archive', icon: 'archive' },
      { label: 'Receipts', icon: 'folder' }] }))));
""")

add("Tabs", "Navigation", 120, """
# Tabs

A row of tabs. Flutter: `MeridianTabs` with `MeridianTab`s.

- **underline** (default) switches views inside an island: `label` type, `ink-muted` idle, `ink` and semibold when active, with a 2px `accent` rule that slides under the active tab.
- **pill** switches open documents on `ground` (repositories, mailboxes, notebooks): the active tab is a `pane` pill with `shadow-pane`, so it reads as the top of the island below. A 6px `warning` dot marks unsaved changes; `onClose` adds a close button on hover, on keyboard focus and on the active tab (hidden close buttons take no clicks; screen readers always find them, named by `closeLabel`).
- The consumer provides `tabs` (`label`, optional `icon`, `count`, `dirty`, `enabled`, `semanticLabel`), `index`, `onChanged`, and `dirtyLabel` to localize how a dirty tab is announced. The count and dirty state are read with the label ("Drafts, 3, unsaved changes").
- Arrow keys, Home and End move the selection and keyboard focus together, skip disabled tabs, follow the reading direction and scroll the tab into view.
""", """
mount(h('div', { className: 'mr-demo col', style: { gap: 'var(--space-5)' } },
  h(M.Island, null, h('div', { style: { padding: '0 var(--space-3)' } }, h(M.Tabs, { index: 1, tabs: [{ label: 'Overview' }, { label: 'Threads', count: 12 }, { label: 'Environment' }, { label: 'Open files' }] }))),
  h(M.Tabs, { variant: 'pill', closable: true, index: 0, tabs: [{ label: 'GitLama', dirty: true }, { label: 'CrossProton' }, { label: 'Mimameidr' }] })));
""")

add("TabStrip", "Navigation", 120, """
# TabStrip

A browser-style strip of open documents (repositories, notebooks, mailboxes) with drag reordering and tab groups. Flutter: `MeridianTabStrip` with `MeridianStripTab`s and `MeridianStripGroup`s. Use pill `Tabs` for a short fixed set of documents; use the strip when people arrange their own.

- Tabs sit on `ground` and share the width between 110 and 200 px; they scroll when they no longer fit. The active tab is a `pane` pill with `shadow-pane` that glides between tabs (`motion-select`). Resting tabs have no fill; a `line-strong` hairline in the gap separates two of them. A `warning` dot marks unsaved changes (it pops in on `spring-pop`); a close button shows on hover and on the active tab, and a middle click closes. New tabs grow in and closed tabs collapse out (`motion-layout`).
- A group is a 20 px `radius-md` chip before its tabs, tinted 18% (28% hovered) with the group's colour (normally a `series` colour), showing an optional icon in that colour and the name, or a lone colour dot. A 2 px rule in the colour runs under the chip and its tabs. A click collapses the group to its chip, which then shows the tab count in `ink-muted`; the tabs fold away.
- Dragging is direct, as in browsers: a press that moves 4 px picks the tab up (`MeridianLift`), the others slide aside while it passes them (`motion-layout`), and it settles where it is dropped. A tab joins a group once it passes the group's chip or between two of its tabs; at the group's end the rule shows whether it is in, and a short nudge outwards (24 px) takes it out. Dragging a chip carries the whole group; it never lands inside another group, and a collapsed group's folded tabs stay with its chip. Escape cancels a drag; the strip scrolls when a drag reaches its edge.
- The owner keeps the order: `onMoveTab(tab, index, group)` and `onMoveGroup(group, index)` report drops (indices among the other tabs), and the strip shows the dropped order until the new tabs arrive. A second click on the active tab, or `renameTab`, names it in place; `renameGroup` names a group. `onContextMenu` and `onGroupContextMenu` get the menu key and Shift+F10 as well as a right click; show native menus there.
- Each tab announces its label and unsaved state, offers move left and right actions to assistive technology, and every string is passed through `MeridianTabStripLabels` for localisation.
""", """
mount(h('div', { className: 'mr-demo start' },
  h(M.TabStrip, { active: 'GitLama',
    groups: [{ id: 1, name: 'Apps', icon: 'star', color: 'var(--series-6)' }, { id: 2, color: 'var(--series-2)', collapsed: true }],
    tabs: [{ label: 'GitLama', icon: 'folder', dirty: true }, { label: 'CrossProton', icon: 'folder', group: 1 }, { label: 'Mimameidr', icon: 'folder', group: 1 }, { label: 'Nibluma', icon: 'folder', group: 2 }, { label: 'meridian_ui', icon: 'folder', group: 2 }] })));
""")

add("NavRow", "Navigation", 275, """
# NavRow

Rows of a navigation sidebar (folders, labels, views, branches), grouped under a NavSection. Flutter: `MeridianNavRow` inside `MeridianNavSection`.

- The sidebar sits straight on `ground`, not in an island. Rows are `size-row` tall with `radius-sm` inset hover on `ground-hover`. The active row is `accent-soft`; while the sidebar has keyboard focus it is solid `accent`.
- NavSection provides `title` (set as an `overline`), an optional `count`, and an `action` icon button revealed on hover or keyboard focus (always visible on touch); `collapsible` sections fold from their header (a 48px target at touch density), with Enter and Space as well as a click.
- NavRow provides `label`, `icon` (with optional `iconColor`, a `series` colour for labels), `count` (quiet by default; `accent` for unread), `depth` (14px per level), `expandable`/`expanded` with `onToggleExpanded`, `current` (where the person is: a check mark and `body-strong`), `selected`, `enabled`, `onTap`, `onContextMenu`. Arrow right and left expand and collapse; the chevron is its own focusable target (48px at touch density) and assistive technology gets expand and collapse actions.
- `leading` puts a picture in the icon slot instead of `icon` (an app's own icon, an avatar), at the density's small icon size.
- Rows grow past `size-row` only when large text needs the room.
- On phones the same rows go in a Drawer (`MeridianDrawer`) that the app bar's menu button opens.
- `drop` shows feedback while something is dragged over the row (mail onto a folder): `accept` paints `accent-soft` with an `accent` edge and `accent-ink` text, `reject` fades the row to `ink-faint`. The app owns the drag target.""", """
mount(h('div', { className: 'mr-nav', style: { width: 260 } },
  h(M.NavSection, { title: 'Mailbox', action: 'plus', actionLabel: 'New folder' },
    h(M.NavRow, { name: 'Inbox', icon: 'inbox', count: 12, countTone: 'accent', state: 'selected' }),
    h(M.NavRow, { name: 'Drafts', icon: 'file-text', count: 2 }),
    h(M.NavRow, { name: 'Projects', icon: 'folder', expandable: true, open: true }),
    h(M.NavRow, { name: 'Meridian', icon: 'tag', depth: 1, iconColor: 'var(--series-6)' }),
    h(M.NavRow, { name: 'Archive', icon: 'archive' })),
  h(M.NavSection, { title: 'Branches', count: 3 },
    h(M.NavRow, { name: 'main', icon: 'git-branch', current: true }),
    h(M.NavRow, { name: 'design-system', icon: 'git-branch', state: 'focused' }))));
""")

add("ListRow", "Navigation", 230, """
# ListRow

A row in a list: messages, processes, notebooks, files. Flutter: `MeridianListRow`.

- The consumer provides `title`, optional `leading` (icon, Avatar, status glyph), `subtitle` (inline, or on a second line with `twoLine`), `meta` (right-aligned `caption` in tabular figures: a date, a size), `trailing`, `hoverActions` (small IconButtons revealed on hover or keyboard focus in place of `meta`, always also in the context menu; `trailing` stays), `selected`, `emphasized` (`body-strong`: unread, current), `dimmed` (45%: filtered out, terminated), `enabled` (off fades everything to `ink-faint`), `onTap`, `onDoubleTap`, `onContextMenu`. `match` is the active filter or search text: its occurrences in the title are set bold, underlined and in `accent` (`on-accent` on a solid selection). `titleTrailing` is a small count or status that stays right after the title; `semanticValue` names state the title does not say ("Current").
- The selection is an inset rounded bar (`radius-sm`, `space-3` in from the island edge), never full-bleed. In the island that has keyboard focus it is solid `accent` with `on-accent` / `on-accent-muted` text; elsewhere `accent-soft`. You can tell where your arrow keys go at a glance.
- On one line the title comes first: it keeps its natural width (with `titleTrailing`) up to the row less the `space-4` gap and a subtitle ellipsis, and the inline subtitle takes the rest and truncates first, so a long name never ellipsizes beside empty space. When not even the subtitle's ellipsis fits, the title takes the whole line. With `twoLine` each line has the full width.
- Row height follows density: 24 / 28 / 32 on desktop, 48 at touch (two-line rows add 16 or 20). Rows grow past it only when large text needs the room, never to fill the space they are given.
- `onTap` runs on the first tap, never delayed; `onDoubleTap` runs on a second pointer tap within 300ms. Both are supplied by `MeridianInteraction`, also available for custom domain surfaces. Keyboard Enter and Space activate `onTap` only; they never trigger the double-tap action. Hover actions stay while keyboard focus is inside them, so Tab reaches them.
- `checked` makes the row an item of a multi-select checklist (files to stash, items to export). `null`, the default, draws no checkbox. Otherwise the row starts with the Checkbox mark, `space-4` before `leading` and the title, with the Checkbox's visuals and motion; it follows the row's hover and press, and fades with `enabled`. The mark is not a separate focus stop: a click, Space or Enter on the row runs `onTap`, and the app toggles the value. The row reads as a checkbox with that state instead of a button. A checklist usually leaves `selected` off; on a solid selection the mark inverts to `on-accent` so it stays legible. Don't use it for a single option that applies when a command runs (use Checkbox) or for a setting that applies at once (use Switch).
- Put rows in a `MeridianList` (or `MeridianList.builder` for long and live lists): it adds the `space-3` inset on every side.
""", """
mount(h('div', { className: 'mr-demo col' },
  h(M.Island, { title: 'Inbox', subtitle: '3 of 1,204', focused: true, actions: [h(M.IconButton, { key: 1, icon: 'list-filter', label: 'Filter', size: 'sm' })] },
    h('div', { className: 'mr-list' },
      h(M.ListRow, { avatar: 'Anna Berg', title: 'Anna Berg', subtitle: 'Quarterly report draft', meta: '09:41', emphasized: true, actions: [{ icon: 'archive', label: 'Archive' }, { icon: 'trash-2', label: 'Delete' }] }),
      h(M.ListRow, { avatar: 'Proton', title: 'Proton', subtitle: 'Your security key was added', meta: '08:12', state: 'focused' }),
      h(M.ListRow, { avatar: 'Jonas Weber', title: 'Jonas Weber', subtitle: 'Re: Mimameidr beta 14', meta: 'Yesterday' }),
      h(M.ListRow, { icon: 'cpu', title: 'flutter_tester', subtitle: 'PID 4812', meta: '0.0%', dimmed: true })))));
""")

add("Breadcrumbs", "Navigation", 120, """
# Breadcrumbs

A one-line trail of where the person is: a commit, the folders of a path, a file. Flutter: `MeridianBreadcrumbs` with `MeridianBreadcrumb`s.

- Each crumb takes a `label`, an optional `leading` (a small icon, or an icon with a short code such as a commit hash), `mono` (the label in `code-sm` for identifiers), `onActivate` (click, Enter or Space; without it the crumb is plain text), `onContextMenu` (a secondary click, the context-menu key or Shift+F10, with the global position for the app's native menu), `semanticLabel` and `emphasis` (`body-strong` in `ink`: the current location, usually the last crumb).
- The trail takes `crumbs`, `onOverflow` (the hidden crumbs and a position: the app shows them in a native menu), an optional `overflowLabel` for the `…` crumb and a `semanticLabel` that names the trail as a header.
- Crumbs are separated by a small `chevron-right` (`chevron-left` right to left) in `ink-faint`. Labels are `body` in `ink-muted` and turn `ink` on hover.
- The first and last crumbs never fold. When the row is too narrow, the middle crumbs fold from the second onwards into one `…` crumb, keeping the crumbs nearest the end; then the first crumb's label ellipsizes (down to 48px), and only then the last's. Folded crumbs leave the focus order.
- Interactive crumbs are `size-control-sm` tall with `space-2` padding and `radius-sm`; hover `pane-hover` (following the surface), pressed adds 4% `ink`, keyboard focus the `focus` ring. A click does not move focus. They read as buttons; a crumb with only a context menu reads as text with a long-press action.
- Activating a crumb moves to that place; it never changes the crumbs' order. Keep the trail short: one target, its folders, one leaf. Don't put commands in it; they go in the bar's buttons and the crumbs' context menus.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h(M.Breadcrumbs, { crumbs: [{ label: 'Move Meridian to 1.1.1', icon: 'git-commit-horizontal', code: '434cdea0' }, { label: 'lib' }, { label: 'app' }, { label: 'workspace' }, { label: 'commit_files.dart', mono: true, current: true }] }),
  h(M.Breadcrumbs, { crumbs: [{ label: 'Move Meridian to 1.1.1', icon: 'git-commit-horizontal', code: '434cdea0' }, { label: 'lib' }, { label: 'app' }, { label: 'workspace' }, { label: 'commit_files.dart', mono: true, current: true }], fold: 2, width: 320 })));
""")

add("Steps", "Navigation", 110, """
# Steps

A compact line of named steps showing which are done, which is current and which are still to come: a guided workflow such as resolving a merge conflict (Pick, Review, Resolve, Continue). Flutter: `MeridianSteps` with `MeridianStep`s.

- The consumer provides `steps` (`MeridianStep`: a short `label` and an optional `key`; at least one), `current` (the active step's index; steps before it are done, steps after it upcoming, `steps.length` marks every step done) and an optional `semanticLabel` naming the line.
- One row. Each step is a round marker (`stepMarker`, 16px; 20px at touch density) and its label in `body`, `space-2` apart; steps are joined by a 16px `line-strong` hairline (`stepConnectorLength`) with `space-3` on either side.
- Done: a `success` check on `success-bg`, the label in `ink-muted`. Current: a filled `accent` marker with its number in `on-accent`, the label in `body-strong` `ink`. Upcoming: a `line-strong` outlined marker with its number and label in `ink-muted`. Numbers use the Count type (10px, tabular).
- When the line is narrower than every label needs, the labels of all but the current step hide (their markers stay) and the current label ellipsizes; narrower than the markers themselves, the line clips. It never overflows.
- Steps are not interactive: they show progress, they do not navigate. Every step announces its label, its state (done, current, upcoming) and its position ("2 of 4"), also while its label is hidden.
- Keep labels to a word or two and the line to a handful of steps. Put it at the top of the workflow it tracks; the workflow's own buttons move between steps.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h(M.Steps, { steps: ['Pick', 'Review', 'Resolve', 'Continue'], current: 2, label: 'Resolve conflicts' }),
  h(M.Steps, { steps: ['Pick', 'Review', 'Resolve', 'Continue'], current: 1, compact: true, label: 'Resolve conflicts' })));
""")

add("AppBar", "Navigation", 250, """
# AppBar

The top bar of a touch screen, on `ground`. Flutter: `MeridianAppBar`.

- The consumer provides `title` (`heading` type), an optional `subtitle` (a `caption` line in `ink-muted`: the save state, a location), `leading` (back or menu IconButton), `actions` (IconButtons), `elevated` (a `line` hairline once content scrolls under it) and `centerTitle`.
- Without `leading` it shows a back button when the route can be popped, or a menu button that opens the Scaffold's Drawer (`automaticallyImplyLeading`).
- 56px tall plus the status bar inset (the hairline is drawn over the bar, not added to it), no elevation, no colour fill. The title follows large text up to 134% and shows in full as its tooltip, so the bar never grows. Desktop windows use the toolbar (ToolbarButtons on `ground`) instead.
""", """
mount(h('div', { className: 'mr-demo' }, h('div', { className: 'mr-phone mr-touch' },
  h(M.AppBar, { leading: 'arrow-left', leadingLabel: 'Back', title: 'Linear algebra', subtitle: 'Saved on this device', elevated: true, actions: [{ icon: 'search', label: 'Search' }, { icon: 'ellipsis-vertical', label: 'More' }] }),
  h('div', { style: { padding: 'var(--space-3)' } }, h(M.Island, null, h('div', { className: 'mr-list' },
    h(M.ListRow, { icon: 'notebook', title: 'Week 3: eigenvalues', subtitle: 'Edited 5 min ago', twoLine: true }),
    h(M.ListRow, { icon: 'scan', title: 'Lecture scan', subtitle: '4 pages', twoLine: true })))))));
""")

# ------------------------------------------------------------------ Display
add("Kbd", "Display", 60, """
# Kbd

Keyboard keys for a shortcut, in menus, tooltips, buttons and the palette footer. Flutter: `MeridianKbd`. Keycaps wrap under bounded width; a long label wraps within its cap rather than clipping at enlarged text sizes.

- Pass `keys` in the platform's glyphs: ⌘ ⇧ ⌥ ↵ on macOS, the words Ctrl, Shift, Alt, Enter elsewhere. Never mix a spelled-out modifier with glyphs in one app. `onAccent` inside an `accent` fill (primary button, highlighted menu row).
- Hints on permanent chrome (buttons, a title-bar field) set `reveal: whileModifierHeld`: the keycaps appear, and take space, only while one of their command modifiers (⌘, Ctrl, ⌥) is held, so the hint shows when the person reaches for the shortcut. Shift never reveals; keys without a command modifier always show. Menus, the palette and shortcut references keep the default `always`.
- 18px keycaps on `pane-alt` with a `line-strong` edge and a 1px lip, `caption` type of the active density in `ink-muted`; keycaps grow with large text.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.Kbd, { keys: ['⌘', 'K'] }), h(M.Kbd, { keys: ['⌘', '⇧', '↵'] }), h(M.Kbd, { keys: ['Ctrl', 'Shift', 'P'] }), h(M.Kbd, { keys: ['Esc'] })));
""")

add("Count", "Display", 60, """
# Count

A pill number: unread mail, items to act on, section totals. Flutter: `MeridianCount`.

- The consumer provides `label` and `tone`: **neutral** (`line`), **accent** (something actionable: unread, commits to pull), **attention** (work to do: conflicts, pending review), **danger** (failures), **quiet** (a bare `ink-muted` number in section headers).
- 16px tall (it grows with large text instead of clipping), 10px semibold tabular figures. Give it a `semanticLabel` ("12 unread") when the number alone is ambiguous.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.Count, null, '3'), h(M.Count, { tone: 'accent' }, '12'), h(M.Count, { tone: 'attention' }, '2'), h(M.Count, { tone: 'danger' }, '1'), h(M.Count, { tone: 'quiet' }, '480')));
""")

add("MiddleEllipsis", "Display", 96, """
# MiddleEllipsis

One line of text that keeps both ends when it is too long: a branch, a file path, an identifier. Flutter: `MeridianMiddleEllipsis`.

- Use it where the end of a name tells instances apart (`feature/login-form` and `feature/login-flow`). Titles, sentences and labels keep the end ellipsis of `Text`.
- The consumer provides the `text`, an optional `style` merged over the ambient text style, and an optional `semanticsLabel`. Assistive technology always reads the complete text.
- The width follows the shown text up to the available width, so a chip or pill around it hugs the name and never reserves its maximum. Give the parent a maximum width, not a fixed one.
- The text never wraps, and whole characters are kept: an emoji or a combined letter is not split. Show the complete text in a tooltip where the shortened one can appear.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h('div', { className: 'mr-row' },
    h(M.Chip, null, h(M.MiddleEllipsis, { width: 180 }, 'main')),
    h(M.Chip, null, h(M.MiddleEllipsis, { width: 180 }, 'origin/feature/update-route-dialog-when-offline')),
    h(M.Chip, null, h(M.MiddleEllipsis, { width: 120 }, 'release/2026-09-candidate')))));
""")

add("Avatar", "Display", 64, """
# Avatar

A person's initials on a categorical colour (`series-1` … `series-8`) picked from a stable hash of their name, so the same person keeps the same colour everywhere. Flutter: `MeridianAvatar`.

- The consumer provides `name`, optional `colorKey` (hash an email address instead), `size` (16px in rows, 20px in touch rows, 28px in headers, 40px `xLarge` for a person's card), `monogram` (the app's own initials, at most two characters) and `image` (a picture replaces the fill, same size and shape; the initials show while it loads and when it fails; a loaded picture sits on `pane`, so a logo with a transparent background never shows the fill or initials through it).
- Decorative: it always sits next to the name as text, so it is hidden from assistive technology.
- `onPressed` makes it a button for something about the person (a profile, an offer to load pictures): it gets the focus ring and pressed state, `tooltip` (the name by default) on hover, and is announced as a button with that name.
- The initials scale down to fit the circle at large text sizes; the circle keeps its size.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.Avatar, { name: 'Michael Lamers' }), h(M.Avatar, { name: 'Anna Berg' }), h(M.Avatar, { name: 'Jonas Weber' }),
  h(M.Avatar, { name: 'Proton', size: 'md' }), h(M.Avatar, { name: 'Release Bot', size: 'lg' }), h(M.Avatar, { name: 'Kai Sommer', size: 'lg' }), h(M.Avatar, { name: 'Ada Lovelace', size: 'xl' })));
""")

add("Chip", "Display", 96, """
# Chip

A compact label: a filter, a tag, a recipient, an attachment. Flutter: `MeridianChip`.

- The consumer provides `label` and optionally `icon`, `dotColor` (a `series` colour for a category; the text always goes with it), `tone` (neutral outline, `accent`, or a status tint), `selected` (a filter toggle: `accent-soft` with a check), `onPressed`, `onRemove` with its `removeLabel` ("Remove Anna"), and `enabled` (off shows `ink-faint` on a `line` edge and ignores input).
- At least 22px tall (32px at touch density), `radius-sm`, `label` type. The pill grows for enlarged text instead of clipping its line; the width remains bounded by the consumer’s `maxWidth` and truncates with an ellipsis.
- Every tone hovers except a selected filter: outlined chips take `pane-hover`, tinted chips darken by 4% `ink`; pressing adds another 4%.
- The remove button is its own button for assistive technology and the keyboard, and a 48px target at touch density (it may reach past the pill).
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.Chip, { selected: true }, 'Unread'), h(M.Chip, { selected: false }, 'Has attachment'),
  h(M.Chip, { removable: true }, 'anna@example.org'),
  h(M.Chip, { dot: 'var(--series-2)' }, 'Work'), h(M.Chip, { dot: 'var(--series-5)' }, 'Family'),
  h(M.Chip, { tone: 'success', icon: 'lock' }, 'Encrypted'), h(M.Chip, { tone: 'attention', icon: 'circle-alert' }, 'Review'),
  h(M.Chip, { selected: true, icon: 'pencil', style: { fontSize: '24px', lineHeight: '32px', maxWidth: '360px' } }, 'Danach bearbeiten')));
""")

add("StatusDot", "Display", 60, """
# StatusDot

A 6px state dot with its label: running, synced, offline. Flutter: `MeridianStatusDot`.

- The consumer provides `tone` (`neutral`, `accent`, `success`, `warning`, `danger`, `attention`), `label` (or `semanticLabel` when the label is elsewhere in the row) and `halo` for a live or running state.
- Never colour alone: the label or a glyph always goes with it.
""", """
mount(h('div', { className: 'mr-demo pane', style: { gap: 'var(--space-7)' } },
  h(M.StatusDot, { tone: 'success', halo: true }, 'Running'), h(M.StatusDot, null, 'Sleeping'),
  h(M.StatusDot, { tone: 'warning' }, 'Stopped'), h(M.StatusDot, { tone: 'danger' }, 'Zombie'), h(M.StatusDot, { tone: 'accent' }, 'Syncing')));
""")

# ------------------------------------------------------------------ Feedback
add("Banner", "Feedback", 250, """
# Banner

A persistent inline message about the state of the island or screen it sits in. Flutter: `MeridianBanner`.

- The consumer provides `message`, an optional bold `title` sentence, `tone` (`info`, `success`, `warning`, `attention`, `error`), at most two small `actions` (asserted in debug builds), and `onDismiss`.
- `radius-lg`, tinted in the tone's `-bg` colour, no border, the tone's icon. Use **attention** (orange) for work to do (a paused sync, a conflict to resolve); **error** only for failures.
- Say what happened, then what to do: "Could not send “Quarterly report”. The attachment is larger than 25 MB. Remove it or share a link instead." Transient results ("Archived 3 messages") are Toasts, not banners.
- Actions sit at the right, centred on the text; at touch density, below 480px wide and with enlarged text they go under the text instead. A bounded scrolling feedback area keeps the complete message and recovery controls reachable.
- Assistive technology reads the title and message as one node (a live region for `error` and `attention`); the actions stay separate buttons.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h(M.Banner, { tone: 'attention', title: 'Sync paused.' }, 'The server asked for a new password. Sign in again to continue.'),
  h(M.Banner, { tone: 'error', title: 'Could not send “Quarterly report”.', actions: h(M.Button, { size: 'sm' }, 'Open draft') }, 'The attachment is larger than 25 MB. Remove it or share a link instead.'),
  h(M.Banner, null, 'Messages older than 30 days are kept on the server only.')));
""")

add("Toast", "Feedback", 175, """
# Toast

A transient confirmation that floats at the bottom of the window: "Archived 3 messages", with at most one action, usually Undo. Flutter: `showMeridianToast` (renders a `MeridianToast`).

- The consumer provides `message`, `tone` (`neutral`, `success`, `warning`, `error`), optional `actionLabel` and `onAction`, and `duration` (`motion-toast`, 4 s; `motion-toast-action`, 8 s with an action). `overlay` sends it to another window's or route's overlay, for a toast that must outlive the surface it comes from (Undo send after a composer window closed).
- `raised`, `radius-xl`, `shadow-float`, 360px at most; it arrives on a spring (see Motion). Errors that need a decision are banners or dialogs, never toasts. Apps with an operation log (GitLama's Logbook) put results there instead.
- For a result that arrives after the screen that started the work has closed, take `Overlay.of(context, rootOverlay: true)` before the `await` and call `showMeridianToastIn(overlay, …)`. `hideMeridianToast()` fades out a toast whose news has been superseded.
- A long action or enlarged text moves the action below the message when they cannot fit beside each other. Both rows stay within the toast width; the message remains complete.
- One toast at a time: a new one replaces the current one. Hovering or focusing it pauses the countdown, which resumes when the pointer and focus leave. It fades out when it goes, is announced to assistive technology on every platform, and keeps local `Theme` overrides.
""", """
mount(h('div', { className: 'mr-demo col start', style: { gap: 'var(--space-5)' } },
  h(M.Toast, { tone: 'success', action: 'Undo' }, 'Archived 3 messages'),
  h(M.Toast, null, 'Link copied'),
  h(M.Toast, { tone: 'error' }, 'Export failed: the disk is full')));
""")

add("Progress", "Feedback", 150, """
# Progress

Spinner, progress bar and meter. Flutter: `MeridianSpinner`, `MeridianProgressBar`, `MeridianMeter`.

- **Spinner**: 12px, replaces an icon while something runs (a loading Button keeps its label). Turns once per 700ms, 2s with reduce motion.
- **ProgressBar**: a 2px `accent` rule; indeterminate (a sliding 30% bar) until progress is known, then determinate; the indeterminate bar sweeps ease-in-out over 1.1s (`motion-progress`) and holds still with reduce motion. Set `track` for a standalone bar on a `line` track; leave it off when it runs along an edge (the bottom of a title pill, the top of an island).
- **Meter**: a 3px value bar for a metric (CPU, storage, quota), always next to its number. The fill animates toward new values and turns `warning` or `danger` past `warningAt` and `dangerAt`.
- ProgressBar and Meter need a bounded width (a `SizedBox`, `Expanded` or stretched column); debug builds assert it.
""", """
mount(h('div', { className: 'mr-demo col pane start' },
  h('div', { className: 'mr-row' }, h(M.Spinner), h('span', { className: 'mr-caption' }, 'Fetching origin…')),
  h(M.ProgressBar, { track: true, width: 320, label: 'Importing' }),
  h(M.ProgressBar, { track: true, value: 0.62, width: 320, label: 'Exporting' }),
  h('div', { className: 'mr-metric' }, h('span', null, 'CPU'), h('span', { className: 'v' }, '78.4%'), h(M.Meter, { value: 0.784, warningAt: 0.5, dangerAt: 0.9 })),
  h('div', { className: 'mr-metric' }, h('span', null, 'Memory'), h('span', { className: 'v' }, '1.2 GB'), h(M.Meter, { value: 0.31, warningAt: 0.5, dangerAt: 0.9 }))));
""")

add("EmptyState", "Feedback", 265, """
# EmptyState

What an empty list or screen says. Flutter: `MeridianEmptyState`.

- The consumer provides `title` (what is true: "No messages match “invoice 2025”"), an optional `icon`, `message` (one sentence on what to do), one `action`, and `headline` for first-run and welcome screens (the `display` style).
- `heading` title, `ink-muted` message, 24px `ink-muted` icon, centred at most 360px wide; it scrolls rather than overflows in a short space. No mascots, no emoji, no exclamation marks.
- `progress` is the loading state of the same place: a 24px Spinner in `ink-muted` replaces the icon (it waits 150ms, so quick loads never flash), the title says what is loading ("Loading history…") and is announced politely. `progressValue` adds a determinate bar under the title when the share is known. Use it, not a bare centred text or spinner, wherever a pane waits for its content.
- `compact` is the in-pane size for small islands and detail panes: `body` title, `caption` message, `space-6` around it. Every empty, loading and failed state of one app uses the same size in the same kind of place.
""", """
mount(h('div', { className: 'mr-demo col' }, h(M.Island, { title: 'Search results' },
  h(M.EmptyState, { icon: 'text-search', title: 'No messages match “invoice 2025”', action: h(M.Button, null, 'Search all folders') }, 'Try fewer words or search all folders.'))));
""")

add("Skeleton", "Feedback", 160, """
# Skeleton

A placeholder bar for content that is loading. Flutter: `MeridianSkeleton`.

- The consumer provides `width` and `height` (10px by default). Use a few bars of different widths per row, matching the row they stand in for. `pane-hover` on `radius-xs`; it breathes gently, with no shimmer, so a loading list stays calm.
- Show skeletons only for loads that take longer than about 300ms: pass `delay: MeridianDurations.skeletonDelay` and the bar appears only after it (its space is kept meanwhile).
""", """
mount(h('div', { className: 'mr-demo col' }, h(M.Island, null, h('div', { style: { padding: 'var(--space-5)', display: 'grid', gap: 'var(--space-5)' } },
  [0, 1, 2].map(function (i) { return h('div', { key: i, style: { display: 'grid', gridTemplateColumns: '16px 1fr 40px', gap: 'var(--space-4)', alignItems: 'center' } },
    h(M.Skeleton, { width: 16, height: 16 }), h('div', { style: { display: 'grid', gap: 6 } }, h(M.Skeleton, { width: ['60%', '45%', '70%'][i] }), h(M.Skeleton, { width: ['85%', '70%', '50%'][i] })), h(M.Skeleton)); })))));
""")

# ------------------------------------------------------------------ Containers
add("Island", "Containers", 260, """
# Island

The rounded work surface. Flutter: `MeridianIsland` on a `MeridianGround`.

- Islands sit on `ground` 6px (`space-3`) apart and 6px from the window edge: `pane`, `radius-lg`, `shadow-pane` (the shadow is the edge; no border). The gutter between islands is the divider and the splitter. Islands never nest.
- The consumer provides `child`, optional `title` (`body-strong`), `icon` or `leading` (before the title), `count` (a quiet count after it), `subtitle` (metadata in `caption`, tabular figures), `actions` (small IconButtons and Buttons) for the 36px header (48px at touch density), `headerDivider` (the hairline under the header; off when the content starts with its own edge), `expandChild` for lists and editors, `padding`, and `color` to override `pane` (a document's paper). The header is a SectionHeader; never hand-build a 36px strip.
- The island tracks keyboard focus: while focus is inside, it draws a 1px `accent-soft` halo and its rows paint the selection solid `accent`. Only one island has focus at a time.
- Chrome (sidebar, toolbar, tab strip, touch app bar) sits straight on `ground`, not in an island, so the islands read as the content.
""", """
mount(h('div', { className: 'mr-islands', style: { height: 220 } },
  h('div', { style: { width: 200 } }, h(M.NavSection, { title: 'Views' }, h(M.NavRow, { name: 'All processes', icon: 'list-tree', state: 'selected' }), h(M.NavRow, { name: 'Spawned', icon: 'circle-plus', count: 3 }))),
  h(M.Island, { title: 'Processes', subtitle: '482', focused: true, style: { flex: 1 }, actions: [h(M.IconButton, { key: 1, icon: 'search', label: 'Search', size: 'sm' })] },
    h('div', { className: 'mr-list' }, h(M.ListRow, { icon: 'cpu', title: 'WindowServer', meta: '12.4%', state: 'focused' }), h(M.ListRow, { icon: 'cpu', title: 'Mimameidr', meta: '3.1%' }))),
  h(M.Island, { title: 'Inspector', style: { width: 240 } }, h('div', { style: { padding: 'var(--space-6)' } }, h('div', { style: { fontSize: 15, lineHeight: '20px', fontWeight: 600 } }, 'WindowServer'), h('div', { className: 'mr-caption', style: { fontFamily: 'var(--font-mono)' } }, 'PID 412 · macOS')))));
""")

add("Disclosure", "Containers", 150, """
# Disclosure

A collapsible group with a chevron header, instead of Material's ExpansionTile. Flutter: `MeridianDisclosure`.

- The consumer provides `title`, `child`, `initiallyExpanded` or a controlled `expanded` with `onExpansionChanged`, an optional `trailing` widget (read separately by assistive technology) and `enabled`. `header` replaces the title text with richer content (a commit subject with its author line); the header grows to fit it and `title` stays the accessible name.
- A row-height header: 12px `chevron-right`/`chevron-down` in `ink-muted`, a `label` title, `pane-hover` on hover (`ground-hover` on `ground`), plus 4% `ink` while pressed, `ink-faint` when disabled; the body indents 16px. It exposes its expanded state to assistive technology.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h(M.Disclosure, { title: 'Command details', open: true }, h('pre', { style: { margin: 'var(--space-3) 0', padding: 'var(--space-4) var(--space-5)', background: 'var(--pane-alt)', borderRadius: 'var(--radius-md)', fontFamily: 'var(--font-mono)', fontSize: 11, lineHeight: '16px' } }, 'git push --force-with-lease origin main')),
  h(M.Disclosure, { title: 'Advanced options' })));
""")

add("Dialog", "Containers", 270, """
# Dialog

A modal question, asked only when the answer is needed before the app can go on: confirming a destructive step, or choosing options for an operation. Flutter: `MeridianDialog` with `showMeridianDialog`, or `showMeridianConfirm` for yes/no.

- The consumer provides `title` (the full command with real names: "Delete Linear algebra"), `description` (the consequence, in numbers: "42 pages and 3 scans are removed from this device."), optional `content` (options, a preview), `aside` (option checkboxes, bottom left), `actions` (Cancel first, the verb last) and `onSubmit` (the primary action, run by Enter unless a button has focus). `showMeridianDialog` takes `barrierDismissible` for the scrim and `dismissOnEscape` (on by default, also when the scrim cannot close it).
- **The primary button carries the verb** of the title ("Delete branch", "Rename notebook", "Discard 3 files"), never "OK", "Confirm", "Continue" or "Yes". Cancel is always "Cancel".
- **Yes/no questions use `showMeridianConfirm`**, never a hand-built title, text and two buttons. It takes `title`, `confirmLabel` (the verb), `description` and/or `content` (a widget for what a sentence cannot say: the affected items, a command preview, an option), `destructive`, `width`, `barrierDismissible` and `confirmIcon`, and returns whether the person confirmed. A destructive confirmation has a `danger` verb and starts with focus on Cancel, so a hasty Enter or Space cancels; any other starts on the verb. Turn `barrierDismissible` off when the question must be answered with a button (it loses work either way); Escape always cancels.
- **Enter submits.** In a form dialog give `onSubmit` the primary action and `submitDisabled` while it is unavailable: Enter in any single-line `TextField` then runs it (see TextField), and on a disabled action the dialog shakes and shows the action's disabled reason. A dialog with its own layout puts a `MeridianDialogSubmitScope` around its fields.
- **Three widths**, by what the dialog does: `dialogConfirmWidth` (460px) for a question with at most a short list or one option; `dialogFormWidth` (560px) for a form of a few fields or settings rows (a name and a target, credentials, the options of one operation); `dialogWorkflowWidth` (760px) for a workflow that shows its material while it asks (a list to pick from, a preview, a command and its output, several steps). Dialogs of the same kind use the same width; never pick a width per dialog.
- `raised`, `radius-xl`, `shadow-float`, 460px wide by default, `space-7` padding (`space-8` on touch), on `scrim`; it grows in (see Motion). Enter runs the primary action, Escape cancels. For destructive verbs the confirm button is `danger` and focus starts on Cancel. On narrow touch screens the buttons stack full width, the verb on top; elsewhere they wrap onto their own lines when they do not fit. The body scrolls within 85% of the screen height while the buttons stay in view. Local `Theme` overrides where it was opened carry into the dialog. A dialog opened from another dialog or a menu keeps the scrim that is already there instead of dimming twice.
- **Dialogs that inform or manage close with ✕.** A dialog that asks nothing (details, a reference, a list to manage such as hosts) has nothing to cancel: give it `onClose` and it shows a close button at the end of the title row, like a Panel, instead of a footer "Close" button. Its `actions` keep only real commands ("Add host…"). Questions never get `onClose`; they end with Cancel and the verb. Escape closes both.
- Dialogs with their own layout (a command palette, a settings window, a full-window review) put their content in a `MeridianDialogSurface`: the same `raised` surface, radius and shadow, `maxWidth` (460px by default, `double.infinity` to fill), `maxHeight` (85% of the window by default), `margin`, `alignment` (a tool palette at the top edge on the writing hand's side) and a `semanticLabel` that names the route. Both rise above the on-screen keyboard.
""", """
mount(h('div', { className: 'mr-scrim' }, h(M.Dialog, { title: 'Delete Linear algebra', description: '42 pages and 3 scans are removed from this device. Copies on your Nextcloud stay.',
  aside: h(M.Checkbox, null, 'Also delete from Nextcloud'),
  actions: [h(M.Button, { key: 1, variant: 'quiet' }, 'Cancel'), h(M.Button, { key: 2, variant: 'danger' }, 'Delete notebook')] })));
""")

add("Sheet", "Containers", 300, """
# Sheet

A bottom sheet for touch layouts: tool options, pickers, secondary flows. Flutter: `MeridianSheet` with `showMeridianSheet`.

- The consumer provides `child`, an optional `title` (`title` type) and header `actions` (Done), and `showHandle`.
- `raised`, top corners `radius-xl`, `shadow-float`, a 36×4 grab handle, at most 560px wide, on `scrim`. It slides up over 240ms (`motion-sheet`) and is dismissed by dragging down or tapping the scrim. It rises above the on-screen keyboard. Desktop apps use a Dialog or a Panel instead.
""", """
mount(h('div', { className: 'mr-demo', style: { padding: 0 } }, h('div', { className: 'mr-phone mr-touch', style: { height: 300, display: 'flex', flexDirection: 'column' } },
  h('div', { className: 'mr-sheetwrap', style: { flex: 1 } }, h(M.Sheet, { title: 'Pen', actions: h(M.Button, { variant: 'quiet' }, 'Done') },
    h('div', { className: 'mr-row' }, h('span', { style: { width: 90 } }, 'Width'), h(M.Slider, { label: 'Stroke width', value: 0.3, width: 180 })),
    h(M.Segmented, { label: 'Tool', expand: true, value: 'pen', options: [{ value: 'pen', label: 'Pen', icon: 'pen-line' }, { value: 'marker', label: 'Marker', icon: 'highlighter' }, { value: 'eraser', label: 'Eraser', icon: 'eraser' }] }))))));
""")

add("Panel", "Containers", 230, """
# Panel

A floating panel with a header and a close button, anchored by the app: an inspector, an operations log, a filter builder. Flutter: `MeridianPanel`.

- The consumer provides `title`, `child`, `onClose`, header `actions`, `width` (420px, `panelWidth`) and `padding` (no top padding: the header spaces the body).
- `raised`, `radius-xl`, `shadow-float`, a 44px header (48px at touch density, so its buttons keep their target); it grows in from its `origin`. It floats above the islands without a scrim and closes with Escape (while focus is inside) or its close button.
""", """
mount(h('div', { className: 'mr-demo start' }, h(M.Panel, { title: 'Operations' },
  h('div', { style: { display: 'grid', gap: 'var(--space-4)' } },
    h('div', { className: 'mr-row' }, h(M.StatusDot, { tone: 'success' }, 'Fetched origin'), h('span', { className: 'mr-caption mr-numeric', style: { marginLeft: 'auto' } }, '2 min')),
    h('div', { className: 'mr-row' }, h(M.Spinner), h('span', null, 'Pushing main to origin…')),
    h(M.ProgressBar, { value: 0.4, track: true })))));
""")

add("SettingsRow", "Containers", 230, """
# SettingsRow

A settings form row. Flutter: `MeridianSettingsRow` inside `MeridianSettingsGroup`.

- On desktop the label is right-aligned in a 200px column, the controls sit left in the next column, and `help` goes below them in `caption` `ink-muted` (at most 380px). Below 520px wide and at touch density the label stacks above the controls.
- The consumer provides `label`, `children` (the controls) and `help`. SettingsGroup lays rows out 16px apart under an optional `overline` title.
- In a dialog form set `fitLabels` on the SettingsGroup: the label column hugs the group's widest label (never wider than 200px) with 12px to the controls, so a short label such as "Remote" sits beside its control instead of floating in a wide column. A row with an empty label lines a checkbox up with the controls above it. The fitted form stacks only when the controls would get narrower than a select.
- Changes apply straight away, confirmed by the control's own state: no Save button, no floating labels, no cards.
""", """
mount(h('div', { className: 'mr-demo col pane' }, h(M.SettingsGroup, { title: 'Appearance' },
  h(M.SettingsRow, { label: 'Theme', help: 'Follows the system unless you pick one.' }, h(M.Segmented, { label: 'Theme', value: 'system', options: [{ value: 'light', label: 'Light' }, { value: 'dark', label: 'Dark' }, { value: 'system', label: 'System' }] })),
  h(M.SettingsRow, { label: 'Density' }, h(M.Select, { value: 'Regular', label: 'Density' })),
  h(M.SettingsRow, { label: 'Notifications' }, h(M.Switch, { checked: true }, 'Show new mail on the lock screen'))),
  h('div', { className: 'mr-overline', style: { margin: 'var(--space-7) 0 var(--space-5)' } }, 'Dialog form (fitLabels)'),
  h(M.SettingsGroup, { fit: true },
    h(M.SettingsRow, { label: 'Remote' }, h(M.Select, { value: 'origin', label: 'Remote' })),
    h(M.SettingsRow, { label: '' }, h(M.Checkbox, { checked: true }, 'Fetch all remotes')))));
""")

add("SettingsDialog", "Containers", 380, """
# SettingsDialog

An app's settings window: pages listed at the start, the selected page beside them. Flutter: `MeridianSettingsDialog` with `showMeridianDialog`.

- Use it once settings outgrow one column of SettingsRows (more than about two screens, or groups as different as appearance, columns and remote hosts). A handful of rows stays a `MeridianDialog` with a SettingsGroup.
- The consumer provides `title` ("Settings", "Preferences"), `pages` (`MeridianSettingsPage`: `label`, `icon`, `description` saying what the page covers, and a `builder` for its SettingsGroups), `initialPage` (open on the page the person came for), `onPageChanged`, `onClose` (pops the route by default) and `footer`. A page's `key` names its list entry for tests. An app that moves between pages itself (a link from one page to another) passes `page` and stores what `onPageChanged` reports.
- `footer` is a line under the pages, in view while the page scrolls, for what the person must know about their last change ("That shortcut is already taken", "The settings could not be saved"): a `caption` in a live region, `danger` for failures. Leave it out when there is nothing to say.
- A title bar with ✕ over a hairline; the page list on `ground` (`settingsDialogPageListWidth`, 200px) with NavRows, a vertical hairline, and the page on `raised`: its label in `title`, the description in `caption` `ink-muted`, then the rows. 840px wide (`settingsDialogWidth`) so SettingsRows keep label and control side by side; 640px tall (`settingsDialogHeight`, at most 85% of the window) and the height holds while pages change. Each page scrolls on its own and starts at the top.
- Changes apply straight away: no Save, no Cancel, no footer. It closes with ✕ or Escape, like a Dialog that manages. A question a page needs (removing a host) opens its own Dialog on top.
- The selected NavRow is `accent-soft`, solid `accent` while the list has keyboard focus. Tab reaches the list, Up and Down move between pages, Enter or Space picks one.
- Below 600px of dialog width (`settingsDialogPagedBreakpoint`) and at touch density the list becomes a full-width Select above the page.
- Don't put commands that act on the whole dialog in a page, nest pages, or hide a page the person may need; show it with an explanation instead.
""", """
mount(h('div', { className: 'mr-scrim' }, h(M.SettingsDialog, { title: 'Settings', page: 'Remote hosts',
  pages: [{ label: 'Appearance', icon: 'palette' }, { label: 'Process tree', icon: 'list-tree' }, { label: 'Remote hosts', icon: 'server' }, { label: 'Updates', icon: 'download' }],
  description: 'Computers ProcessLama reaches through your SSH configuration.' },
  h(M.SettingsGroup, null,
    h(M.SettingsRow, { label: 'Background refresh' }, h(M.Select, { value: 'Slow (5 s)', label: 'Background refresh' })),
    h(M.SettingsRow, { label: 'Icon cache', help: '90 KB used of 64 MB' }, h(M.Select, { value: '64 MB', label: 'Icon cache' }))))));
""")

add("Drawer", "Containers", 260, """
# Drawer

The navigation drawer of a phone layout: the app's destinations on a side sheet that slides in from the leading edge over `scrim`. Flutter: `MeridianDrawer` in `Scaffold.drawer`.

- The consumer provides the `child` (NavRows in a padded list, wrapped in a `SafeArea`), an optional `semanticLabel` (defaults to the platform's "Navigation menu") and `width` (304px, never more than the window minus 56px).
- `pane`, trailing corners `radius-xl`, `shadow-float`. `MeridianAppBar` shows the menu button that opens it; the scrim closes it.
- Wider layouts show the same NavRows in a sidebar instead of a drawer. With reduce motion an app may show them in a Sheet.
""", """
mount(h('div', { className: 'mr-demo', style: { padding: 0 } }, h('div', { className: 'mr-phone mr-touch mr-scrim', style: { height: 240, display: 'flex' } },
  h(M.Drawer, { width: 240 },
    h(M.NavRow, { name: 'Library', icon: 'book-open', state: 'selected' }),
    h(M.NavRow, { name: 'Archive', icon: 'archive' }),
    h(M.NavRow, { name: 'Trash', icon: 'trash-2' }),
    h(M.NavRow, { name: 'Settings', icon: 'settings' })))));
""")

add("Scrollbar", "Containers", 230, """
# Scrollbar

The scrollbar of one scroll view that decides when its thumb shows. Flutter: `MeridianScrollbar`.

- Use it for a sidebar or a list beside the content, where a thumb that is always there competes with the rows. The main content keeps the scrollbar of the platform.
- The consumer provides the `controller` of the scroll view, the `child` that holds this view, and `visibility`: **hover** (the default) shows the thumb while the pointer is over the view and while it scrolls, **scrolling** only while it scrolls, **always** as long as the view has more than it shows.
- The thumb fades in and out and takes no room: rows keep their width. 6px wide, 8px under the pointer, `radius-pill`, `line-strong`, `control-edge` while hovered or dragged.
- On touch there is no pointer to hover: the thumb shows while a finger scrolls.
- Wrap one scroll view, not a screen: the scroll views below lose the scrollbar the platform adds. Never hide the only sign that a view scrolls where its content gives none, such as a list that ends exactly at a row edge; use **always** there.
""", """
mount(h('div', { className: 'mr-demo pane', style: { display: 'flex', gap: 16 } },
  h(M.Scrollbar, { height: 180, width: 200 },
    ['main', 'develop', 'feature/login-form', 'feature/login-flow', 'fix/clone-timeout', 'release/2026-09', 'release/2026-10', 'topic/graph-filter', 'topic/sidebar'].map(function (name) {
      return h(M.NavRow, { key: name, name: name, icon: 'git-branch' }); })),
  h(M.Scrollbar, { height: 180, width: 200, visibility: 'always' },
    ['Inbox', 'Drafts', 'Sent', 'Archive', 'Spam', 'Trash', 'Receipts', 'Travel', 'Work'].map(function (name) {
      return h(M.NavRow, { key: name, name: name, icon: 'archive' }); }))));
""")

# ------------------------------------------------------------------ Documents
add("Canvas", "Documents", 300, """
# Canvas

The desk behind documents: page feeds, scan and image viewers, print previews. Flutter: `MeridianCanvas`.

- Paints `canvas`, which sits one step away from `ground` so that pages read as objects resting on a surface, not as islands. A brand may set its own `canvas` in its neutrals (Nibluma lifts it in dark so white paper glares less).
- Pages on it are Paper. Tools float over it in a ToolDock; nothing else floats there except menus, popovers and toasts.
- Text straight on the canvas is chrome only (a page number, a zoom level) in `ink` or `ink-muted`. Anything longer goes in a raised surface.
""", """
mount(h('div', { className: 'mr-demo col', style: { alignItems: 'stretch' } }, h(M.Canvas, { height: 260 },
  h(M.Paper, { label: 'Page 1 of 3' }), h(M.Paper, { label: 'Page 2 of 3', selected: true }), h(M.Paper, { label: 'Page 3 of 3' }))));
""")

add("Paper", "Documents", 300, """
# Paper

A document page resting on the Canvas. Flutter: `MeridianPaper`.

- The consumer provides `color` (the page's paper: document content, never a theme colour, so it does not invert in dark), the `child` that draws the page, the page's `aspectRatio`, `selected` and a `semanticLabel` ("Page 3 of 12").
- `shadow-pane` is its edge; corners are 2px (`paperRadius`): paper, not a card. A selected page gets a 2px `accent` ring outside the edge; the paper itself never changes colour.
- Content drawn on paper (ink, scans, templates) uses the document's own colours, never theme tokens.
""", """
mount(h('div', { className: 'mr-demo col', style: { alignItems: 'stretch' } }, h(M.Canvas, { height: 260 },
  h(M.Paper, { label: 'Page 1', width: 120 }), h(M.Paper, { label: 'Page 2, selected', width: 120, selected: true }))));
""")

add("ToolDock", "Documents", 300, """
# ToolDock

The floating tool palette of a document screen: pen, eraser, selection, a few colours, undo. Flutter: `MeridianToolDock` with `MeridianToolDockDivider`.

- `raised`, `radius-xl`, `shadow-float`, 4px padding; buttons 2px apart; `line-strong` dividers between tool groups. It hugs its content, horizontally (`axis: Axis.horizontal`) or as a vertical rail.
- The consumer provides `children`: IconButtons (the current tool with `active`), ColorSwatches and dividers, plus a `semanticLabel` ("Tools"). The screen places the dock (bottom centre on phones, top centre or the writing hand's side on tablets), keeps it clear of the writing palm and decides what moves into an overflow menu (keep the moved item's label and selected state).
- One dock per screen. It floats over the Canvas without a scrim and never over the page being written on mid-stroke.
""", """
mount(h('div', { className: 'mr-demo col', style: { alignItems: 'stretch' } }, h(M.Canvas, { height: 260 },
  h(M.Paper, { label: 'Page 1', width: 120 }),
  h(M.ToolDock, { label: 'Tools' },
    h(M.IconButton, { icon: 'pencil', label: 'Pen', active: true }), h(M.IconButton, { icon: 'eraser', label: 'Eraser' }), h(M.IconButton, { icon: 'lasso-select', label: 'Select' }),
    h(M.ToolDockDivider),
    h(M.ColorSwatch, { color: '#18304F', label: 'Blue-black', selected: true }), h(M.ColorSwatch, { color: '#0B6477', label: 'Petrol' }), h(M.ColorSwatch, { color: '#943A55', label: 'Berry' }),
    h(M.ToolDockDivider),
    h(M.IconButton, { icon: 'undo-2', label: 'Undo' })))));
""")

# ------------------------------------------------------------------ Data
add("Waveform", "Data", 100, """
# Waveform

A bounded decorative audio peak envelope. Flutter: `MeridianWaveform`.

- Provide at most1,024 finite normalized `peaks` (0–1), in chronological order. The consumer owns decoding, aggregation and loading/error state; do not pass PCM or one sample per audio frame. Input is copied so later caller mutation cannot change an existing picture.
- Optional confirmed `progress` (0–1) fills the elapsed portion with `accent`; the rest uses `ink-muted`. Reading direction determines the timeline origin. The waveform uses the available bounded width and `waveformHeight`, or a caller-provided height. It never animates incoming data or delays playback.
- This is decorative, has no pointer target, keyboard focus, label or slider role. Provide a separately labelled Slider or RangeSlider for seeking/trimming and announce those confirmed times. Loading, unavailable and silent audio are distinct consumer states; an empty peak list paints no data.
- Peak allocation and painting are bounded; rendering does not decode media or infer frame/sample rates. Brand/density/reduced-motion behavior follows shared tokens. It is not a spectrogram, editor, recorder or interactive timeline.
""", "mount(h('div', {className:'mr-demo pane col'}, h(M.Waveform, {peaks:[0.1,0.3,0.8,0.4,0.2,0.7,1,0.5,0.2,0.6,0.4,0.1],progress:0.37,width:320,height:24})));" )

add("PropertyList", "Data", 170, """
# PropertyList

A read-only list of labelled values for inspectors and detail islands: a process's parent and user, a commit's author and date, a message's headers. Flutter: `MeridianPropertyList` of `MeridianProperty`.

- The consumer provides `properties`: each a `label` (sentence case), a `value` (text; say "Unknown" or "-" rather than leaving it empty), `monospace` for identifiers, paths, numbers and commands, `selectable` (on by default, so values can be copied) and `maxLines` to clamp long values.
- Wide layouts put the `caption` label in an `ink-muted` 112px column (`labelWidth`) beside the value; below 2.5 label columns and at touch density the label stacks above it. Rows are `space-3` apart. Values are `body` in `ink`, or `code` with tabular figures when monospace.
- Group long lists with an `overline` heading or a hairline, not cards. Editable values belong in a SettingsRow, not here.
""", """
mount(h('div', { className: 'mr-demo col pane', style: { alignItems: 'stretch' } },
  h(M.PropertyList, { items: [{ label: 'Parent PID', value: '1', mono: true }, { label: 'User', value: 'michael (501)' }, { label: 'Status', value: 'Running' }, { label: 'Executable', value: '/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock', mono: true }] })));
""")

add("ColumnHeader", "Data", 90, """
# ColumnHeader

A column heading of a table: the label, and the sort arrow on the column the table is sorted by. Flutter: `MeridianColumnHeader`.

- The consumer provides `label` (short, sentence case), `sortDirection` (`ascending`, `descending`, or `null` when the table is not sorted by it), `alignEnd` for numeric columns so the heading sits over the numbers, `onPressed` (sort by it, or reverse the order) and `onContextMenu` (the column menu at the pointer: show, hide and reset columns). `sortedAscendingLabel` and `sortedDescendingLabel` are announced with the label.
- It fills the header cell it sits in. Put the header row on `pane-alt` with a `line` hairline below; the heading hovers with `pane-hover`. `caption` type in `ink-muted`; the sorted column is `ink` at weight 600 with a 12px arrow.
- Resizing and reordering columns stay with the table: put a resize grip on the cell's edge and offer every drag as a menu item too.
""", """
mount(h('div', { className: 'mr-demo col pane', style: { alignItems: 'stretch' } },
  h('div', { className: 'mr-colheads' },
    h(M.ColumnHeader, { width: 220 }, 'Name'),
    h(M.ColumnHeader, { width: 80, end: true }, 'PID'),
    h(M.ColumnHeader, { width: 80, end: true, sort: 'desc' }, 'CPU'),
    h(M.ColumnHeader, { width: 96, end: true }, 'Memory'))));
""")

# ------------------------------------------------------------------ Window
add("ResizeHandle", "Window", 150, """
# ResizeHandle

Resizes the islands on either side of the gutter it sits in: a sidebar, an inspector, a split between two lists. Flutter: `MeridianResizeHandle`.

- It is the `space-3` gap itself, invisible at rest: hover shows a 2px `line-strong` rule, dragging turns it `accent`, keyboard focus `focus`. The cursor is the resize cursor for its `direction`.
- The consumer provides `semanticLabel` ("Resize inspector"), `onDrag` (the movement along `direction` in logical pixels; the consumer decides which island grows and clamps it), `onReset` (a double click or Enter restores the default size) and `keyboardStep` (arrow keys move it, 16px by default).
- Never draw a divider line between islands; the gap is the divider. Persist the size the person chose.
- For two panes that share a space, use SplitPane: it owns the handle, the sizes, the minimums and the announcement.
""", """
mount(h('div', { className: 'mr-islands', style: { height: 120 } },
  h('div', { className: 'mr-island', style: { flex: 1 } }),
  h(M.ResizeHandle, { label: 'Resize inspector', state: 'hover' }),
  h('div', { className: 'mr-island', style: { width: 160 } }),
  h(M.ResizeHandle, { label: 'Resize log', state: 'dragging' }),
  h('div', { className: 'mr-island', style: { width: 120 } })));
""")

add("StatusBar", "Window", 70, """
# StatusBar

The window's bottom strip on `ground`: live state and totals ("Polling every second", "412 processes"), never commands. Flutter: `MeridianStatusBar`.

Its token height is a minimum. It grows to fit enlarged caption text and
consumer content; do not wrap it in a fixed-height box.

- The consumer provides `leading` items (state, usually a StatusDot) and `trailing` items (totals). They are `space-5` apart; leading items shrink and ellipsize first.
- 24px tall, `caption` type in `ink-muted` with tabular figures, `space-5` from the window edges, no hairline: the islands above end with the island gap.
- Put commands in the toolbar and transient results in toasts; the status bar only reports.
- `MeridianStatusBarItem` is one item: an optional small `icon` (or `leading`), a one-line `label` that swaps with a rise when it changes and ellipsizes at `maxWidth`. With `onPressed` it becomes a quiet button that opens more about what it shows (the About window, the branch list, the connected host), with `tooltip` on hover; it never runs a command.
""", """
mount(h('div', { style: { background: 'var(--ground)', padding: 'var(--space-3) 0' } },
  h(M.StatusBar, { leading: h(M.StatusDot, { tone: 'success', halo: true }, 'Live, polling every second'), trailing: '412 processes' })));
""")

# ------------------------------------------------------------------ Workspace (1.6.0)
add("FindBar", "Inputs", 120, """
# FindBar

Finds text in the content it sits above: a diff, a file, a log, a history. Flutter: `MeridianFindBar`.

- A search TextField (`search` variant, `small`) showing where the current match is ("3 of 12", localized; "No matches"; "Searching…"), then Previous and Next, optional toggles for case (`case-sensitive`), whole words (`whole-word`) and regular expressions (`regex`), the owner's `trailing` controls (search scopes, apply as a filter) and Close.
- The consumer owns the search: it provides `onChanged`, `onNext`, `onPrevious`, `matchCount`, `currentMatch` (from 0) and `searching`, the toggles' values with their `on…Changed` callbacks (a toggle shows only with its callback), `onClose` (no Close button without), `error` (an invalid expression) and `labels` (each falls back to Meridian's own strings). Never show a raw "3/12".
- Keyboard: Enter goes to the next match and Shift+Enter to the previous one, also before the first search (so Enter can run it); Escape clears the query and, on an empty field, closes the bar. Bind the app's own Find and Find Next shortcuts to focus the field and to `onNext`.
- The field is 200px (`findFieldWidth`) and gives way first; when even 120px (scaled with the text) does not fit beside the buttons, the field takes the whole width and the buttons move below it. Previous and Next are disabled until there are matches. `visible` reveals and collapses the bar, at once under reduced motion.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h('div', { className: 'mr-row' },
    h(M.TextField, { variant: 'search', size: 'sm', value: 'greeting', trailing: '3 of 12', clear: 'Clear search', width: 220 }),
    h(M.IconButton, { icon: 'chevron-up', label: 'Previous match', size: 'sm' }),
    h(M.IconButton, { icon: 'chevron-down', label: 'Next match', size: 'sm' }),
    h(M.IconButton, { icon: 'case-sensitive', label: 'Match case', size: 'sm', active: true }),
    h(M.IconButton, { icon: 'x', label: 'Close find', size: 'sm' })),
  h('div', { className: 'mr-row' },
    h(M.TextField, { variant: 'search', size: 'sm', value: 'invoice 2025', trailing: 'No matches', width: 220 }),
    h(M.IconButton, { icon: 'chevron-up', label: 'Previous match', size: 'sm', disabled: true }),
    h(M.IconButton, { icon: 'chevron-down', label: 'Next match', size: 'sm', disabled: true }))));
""")

add("ColorChoiceRow", "Inputs", 90, """
# ColorChoiceRow

Choosing a colour for something the person names: a label, a tab group, a repository, a calendar. Flutter: `MeridianColorChoiceRow`.

- The theme's eight categorical colours (`series-1` … `series-8`) as ColorSwatches, optionally led by a "No colour" swatch (`allowNone`) and followed by a ColorWell for any other colour (`allowCustom`). A categorical choice follows light and dark; a custom one stays the same in both.
- The consumer provides `value` (a `MeridianSeriesColor`, a `MeridianCustomColor` or `null` for none) and `onChanged` (`null` disables the row); optional `series` (which colours, in order), `noneLabel`, `customLabel`, `seriesLabels` and `pickerLabels`.
- The swatches are named with Meridian's own localized colour names: Blue, Teal, Amber, Orange, Rose, Violet, Cyan, Olive (Blau, Petrol, Bernstein, Orange, Rosa, Violett, Cyan, Oliv). The well is named by its hex value once it holds a colour, and keeps a custom colour while a palette colour is chosen, so it can be chosen again.
- Swatches wrap `space-2` apart; at touch density each keeps its 48px target.
""", """
mount(h('div', { className: 'mr-demo pane' },
  h(M.ColorSwatch, { color: 'var(--ink-muted)', label: 'No colour' }),
  ['#1F6FD6', '#0B8A7A', '#B26A00', '#D4521E', '#C7306B', '#7A55D3', '#0784A8', '#5D8A12'].map(function (c, i) {
    return h(M.ColorSwatch, { key: i, color: c, selected: i === 1, label: ['Blue', 'Teal', 'Amber', 'Orange', 'Rose', 'Violet', 'Cyan', 'Olive'][i] }); }),
  h(M.ColorWell, { label: 'Custom colour' })));
""")

add("SectionHeader", "Containers", 150, """
# SectionHeader

The 36px strip that names an island, a pane or a section inside one and holds its actions. Flutter: `MeridianSectionHeader` (the Island header is one).

- The consumer provides `title` (or a richer `titleChild`, such as a path with a muted directory; `title` stays the accessible name), `icon` or `leading`, `count` (quiet, with an optional `countLabel`), `caption` (metadata in `caption` `ink-muted` with tabular figures), `middle` (content that takes all the width the heading leaves, the heading keeping its natural width up to half the strip: a filter field, a row of view controls; let a row of controls scroll so it never pushes the actions out), `actions` (small IconButtons and Buttons, `space-1` apart), `divider` (the `line` hairline under it, on by default), `color` (transparent by default; `pane-alt` for a section inside an island) and `size` (`regular` in `body-strong` for an island or pane, `small` in `label` for a section inside one).
- Height `size-island-header` (36px; 48px at touch density so its buttons keep their target), `space-5` before and `space-3` after. The title ellipsizes first, then the caption; the actions never leave the strip.
- One strip per section. Never hand-build a header row with its own height or padding; never put two divider lines on top of each other (turn `divider` off when the content starts with an edge).
""", """
mount(h('div', { className: 'mr-demo col' },
  h('section', { className: 'mr-island', style: { width: '100%' } },
    h('header', { className: 'mr-ihead' }, h(M.Icon, { name: 'folder', size: 'sm' }), h('span', { className: 'title' }, 'Unstaged'), h(M.Count, { tone: 'quiet' }, '12'), h('span', { className: 'sub' }, '3 selected'), h('span', { className: 'grow' }),
      h(M.IconButton, { icon: 'plus', label: 'Stage all', size: 'sm' }), h(M.IconButton, { icon: 'ellipsis', label: 'More', size: 'sm' })),
    h('div', { className: 'mr-ibody', style: { padding: 'var(--space-5)' } }, 'The list starts below the hairline.'))));
""")

add("SplitPane", "Containers", 170, """
# SplitPane

Two panes that share a space, with a ResizeHandle between them: a list beside its detail, staged above unstaged changes, a sidebar beside the work. Flutter: `MeridianSplitPane`.

- `axis: horizontal` puts `first` at the start and `second` at the end; `vertical` stacks them. The panes are usually Islands; the `space-3` gap between them is the handle. Set `divider` only for panes inside one island, which have no gap of `ground` between them.
- Sizes are either a **ratio** (`ratio`, the first pane's share; or uncontrolled from `initialRatio`) with `onRatioChanged` during the drag and `onRatioChangeEnd` once it ends (persist here), or an **extent** (`extent` in logical pixels of the `pinned` pane, the other takes the rest) with `onExtentChanged` / `onExtentChangeEnd`.
- Neither pane gets smaller than `firstMinExtent` / `secondMinExtent` (200px by default); when both do not fit they shrink evenly, so the split never overflows.
- Drag the gap, or Tab to it and use the arrow keys (16px a press); double click or Enter calls `onReset` (an uncontrolled ratio returns to `initialRatio`). `focusable: false` keeps it out of the Tab order where the panes have their own resize command. It is announced as an adjustable control named `semanticLabel` ("Resize lists") whose value is the first pane's share ("40%"). Right-to-left layouts mirror the drag.
""", """
mount(h('div', { className: 'mr-islands', style: { height: 150 } },
  h(M.Island, { title: 'Staged', style: { width: '40%' } }, h('div', { style: { padding: 'var(--space-5)' } }, '2 files')),
  h(M.ResizeHandle, { label: 'Resize lists', state: 'hover' }),
  h(M.Island, { title: 'Unstaged', style: { flex: 1 } }, h('div', { style: { padding: 'var(--space-5)' } }, '12 files'))));
""")

add("CodeLines", "Data", 220, """
# CodeLines

Numbered lines of monospace text, read-only: a file at a revision, a log, a command's output, the lines around a conflict. Flutter: `MeridianCodeLines`, built from `MeridianCodeGutter`, `MeridianLineMarks`, `MeridianSharedHorizontalScroll` and `MeridianHorizontalShift`, which a richer view (a diff, a blame) composes itself.

- The consumer provides `lines`, `firstLineNumber`, `marks` (ranges behind a line's text, by line: search hits in `attention-bg`), `highlightedLines` (whole lines in `pane-hover`: lines with a match), `currentLine` (`accent-soft`: the current match), `markers` (a sign in the gutter's marker column: `+` in `success`, a conflict marker; give it a `semanticLabel`), `wrap`, `selectable`, `showLineNumbers`, the vertical `controller` (to jump to a match) and a `semanticLabel` naming the view.
- **Gutter** (`MeridianCodeGutter`): one or more 44px number cells (`codeGutterWidth`; two for a unified diff, old and new), right-aligned in `code-sm` `ink-muted` with tabular figures and `space-4` before the text, an optional 18px marker column (`codeMarkerWidth`) and an optional `line` hairline. `highlighted` fills the numbers `accent-soft`. `MeridianCodeGutter.widthFor` gives its width for layout.
- **Shared horizontal offset**: without `wrap` long lines do not wrap and every line scrolls sideways together under one horizontal scrollbar, while gutters, line fills and headers keep the viewport's width. While the text is wider than its column the scrollbar takes a 12px strip below the rows (`scrollbarGutter`), so it never covers the last line. A custom view wraps its rows in `MeridianSharedHorizontalScroll` (the widest text, the fixed part of a row, the number of side-by-side columns) and the scrolling part of each row in `MeridianHorizontalShift`.
- Lines are 18px (`codeLineHeight`) in `code`, read left to right whatever the app's direction. Domain meaning (additions, deletions, conflicts, blame) stays in the app; this view only shows numbered text and marks.
- **Syntax colours**: `syntax` gives category runs by line (`MeridianSyntaxRun`: a UTF-16 range and a `MeridianSyntaxKind`: comment, keyword, string, number, type, function, variable, constant, operator, punctuation, attribute, tag). Plain code stays `ink`; each category takes its `syntax-*` colour (`MeridianTheme.syntax`), shared by every brand and at least 4.5:1 on `pane`, `pane-alt`, `raised`, `pane-hover`, `success-bg` and `danger-bg`. Colour is the only change: never bold, italic or another size, so coloured and plain lines measure the same. The categories come from the app's parser; Meridian does not parse code.
- A custom view (a diff) colours a line with `MeridianSyntaxPalette`, built once per surface combination from the opaque colours behind the text (the line fill, a mark, a blended selection). A category that reads below 4.5:1 on any of them keeps `ink`, so marks and selections keep their meaning and the text stays readable. `palette.span(text, runs)` returns the exact text; runs that are out of order, overlap, leave the text or split a surrogate pair leave the whole line plain. Colours never mean added, removed or failed: those stay backgrounds, rails and signs.
""", """
mount(h('div', { className: 'mr-demo col pane', style: { fontFamily: 'var(--font-mono)', fontSize: 12, lineHeight: '18px' } },
  ['import "package:meridian_ui/meridian_ui.dart";', '', 'void main() {', '  final greeting = "Hello, Meridian";', '  print(greeting);', '}'].map(function (line, i) {
    return h('div', { key: i, style: { display: 'flex', background: i === 3 ? 'var(--accent-soft)' : i === 4 ? 'var(--pane-hover)' : undefined } },
      h('span', { style: { width: 44, paddingRight: 8, textAlign: 'right', color: 'var(--ink-muted)', boxSizing: 'border-box', fontSize: 11 } }, String(i + 1)),
      h('span', { style: { width: 18, textAlign: 'center', color: 'var(--success)' } }, i === 3 ? '+' : ''),
      h('span', { style: { whiteSpace: 'pre' } }, colour(line))); })));
function colour(line) {
  var pattern = /(\/\/.*$)|("(?:[^"\\]|\\.)*")|\b(import|void|final)\b|\b([A-Za-z_]\w*)(?=\()/g, out = [], last = 0, m;
  while ((m = pattern.exec(line))) {
    if (m.index > last) out.push(line.slice(last, m.index));
    var kind = m[1] ? 'comment' : m[2] ? 'string' : m[3] ? 'keyword' : 'function';
    out.push(h('span', { key: m.index, style: { color: 'var(--syntax-' + kind + ')' } }, m[0]));
    last = pattern.lastIndex;
  }
  out.push(line.slice(last));
  return out;
}
""")

# ------------------------------------------------------------------ Collections (0.5.0)
add("Pagination", "Navigation", 90, """
# Pagination

Numbered pages of a collection that loads one page at a time: search results, a server-paged list. Flutter: `MeridianPagination`.

- The consumer provides `page` (from 1), `pageCount`, `onPageSelected`, the localized `previousLabel` and `nextLabel`, a `pageLabel` for page buttons ("Page 3"), and optionally `jumpLabel` with `jumpSemanticLabel` and `pageCountLabel` for a field that jumps to a page ("Page [3] of 12"). Set `enabled: false` while a page loads.
- Up to seven pages show in full; beyond that the first, the last and the current page's neighbours, with `…` for the gaps. The current page is `accent-soft` with `accent-ink`; the others are quiet and hover like icon buttons. Numbers use tabular figures.
- Small controls. The jump field accepts digits only, selects its text on focus, clamps to the range and runs on Enter. Nothing shows for a single page.
- Prefer continuous scrolling for lists that can load more on their own; pagination is for sources that are paged.
""", """
mount(h('div', { className: 'mr-demo col pane' },
  h(M.Pagination, { page: 3, pages: [1, 2, 3, 4, 5, null, 12] }),
  h(M.Pagination, { page: 7, pages: [1, null, 6, 7, 8, null, 12], jump: true })));
""")

add("SelectionBar", "Navigation", 90, """
# SelectionBar

The strip that replaces a list's header while items are selected: how many, the commands for them, and Clear. Flutter: `MeridianSelectionBar` with `MeridianSelectionAction`s.

- The consumer provides `label` (the count: "3 selected", announced as it changes), `actions`, `clearLabel` with `onClear`, `overflowLabel` for the "more" menu, and an optional `leading` control (a select-all menu).
- An action is its control in the bar (usually a small IconButton or a menu anchor) and, optionally, the same command as a menu entry (`overflow`). When the bar is too narrow, actions with an overflow entry move, last first, into a trailing "more" menu; actions without one stay.
- `accent-soft`, the count in `accent-ink` with tabular figures and never more than a third of the width; controls in it hover relative to that fill. Keep its commands the same as the items' context menu.
""", """
mount(h('div', { className: 'mr-demo col' }, h(M.Island, null,
  h(M.SelectionBar, { label: '3 selected', overflow: true, actions: [{ icon: 'archive', label: 'Archive' }, { icon: 'trash-2', label: 'Delete' }, { icon: 'mail-open', label: 'Mark as read' }] }))));
""")

add("DropZone", "Inputs", 150, """
# DropZone

A dashed area that takes dropped files: attachments, imports. Flutter: `MeridianDropZone`.

- The consumer provides `label` ("Drop files to attach"), an optional `message` ("Up to 25 MB"), `icon` (`upload` by default), `state` and `onBrowse`, which makes the zone a button that opens a file picker (click, Enter or Space): a drop is never the only way in.
- **idle**: a 1px dashed `line-strong` edge, `ink-muted`. **active** (acceptable files are over it): `accent` edge on `accent-soft`, `accent-ink`. **invalid**: `danger` edge and text. Hover darkens the edge to `ink-muted`.
- `radius-lg`, at least 104px tall, `space-6` padding, a 24px icon over a `label` and a `caption`. The app owns the drag transport and sets `state`; over an editor, show the zone as an overlay only while files are dragged over the window.
""", """
mount(h('div', { className: 'mr-demo pane', style: { gap: 'var(--space-5)', alignItems: 'stretch' } },
  h('div', { style: { flex: 1 } }, h(M.DropZone, { label: 'Drop files to attach', message: 'Up to 25 MB', browse: true })),
  h('div', { style: { flex: 1 } }, h(M.DropZone, { label: 'Drop to attach', state: 'active' })),
  h('div', { style: { flex: 1 } }, h(M.DropZone, { label: 'Folders cannot be attached', state: 'invalid' }))));
""")

add("Calendar", "Inputs", 300, """
# Calendar

A month of days to pick one from, inline or in a dialog. Flutter: `MeridianCalendar` and `showMeridianDatePicker`.

- The consumer provides `value`, `firstDate`, `lastDate` and `onChanged`. `showMeridianDatePicker` shows it in a 300px dialog with Cancel and OK and returns the day (or `null`); `title`, `confirmLabel` and `cancelLabel` default to the localized "Select date", OK and Cancel.
- The month and year in `body-strong` with previous and next buttons, the weekdays in the locale's order and narrow names (`caption`, `ink-muted`), and 32px day cells: today has an `accent` ring and `accent-ink`, the chosen day is solid `accent` with `on-accent`, days outside the range are `ink-faint` and cannot be chosen. Names come from `MaterialLocalizations`.
- The grid is one tab stop: arrow keys move a day or a week (following the reading direction), Page Up and Page Down a month, Home and End to the ends of the week, Enter or Space chooses. In the dialog a second Enter on the chosen day confirms.
- For a date a person types more easily than they pick (a birthday), use a TextField.
""", """
mount(h('div', { className: 'mr-demo start' }, h('div', { className: 'mr-menu', style: { padding: 'var(--space-5)' } },
  h(M.Calendar, { month: 'March 2026', offset: 6, days: 31, selected: 18, today: 12, before: 5 }))));
""")

add("BusyOverlay", "Feedback", 170, """
# BusyOverlay

Covers a page or island while a blocking operation runs (signing in, verifying a code): the content dims under a light `scrim` and takes no input, and a `raised` pill shows a spinner with what is happening. Flutter: `MeridianBusyOverlay`.

- The consumer provides an optional `message` ("Verifying…"), announced when the overlay appears, and an optional `action`, usually a quiet Cancel button, that stays usable at the pill's end. Stack it over the surface that waits, not over the whole window, and keep keyboard focus out of the covered content too.
- Say what is happening in the user's words ("Merging main into release…"), not how it is recorded.
- Prefer a Button's `loading` state and keep the rest usable; use the overlay only when nothing on the surface may change until the operation ends.
""", """
mount(h('div', { className: 'mr-demo col' },
  h(M.BusyOverlay, null, 'Verifying…'),
  h(M.BusyOverlay, { action: h(M.Button, { variant: 'quiet' }, 'Cancel') }, 'Merging main into release…')));
""")

# Motion bullets (design/project/guides/40-motion.md), appended to each
# component's guideline. Keep them to one sentence per row and name the
# property that drives it.
MOTION = {
    "Button": "Presses to 0.97 and springs back; `loading` swaps the icon for a spinner after 150ms; `success` holds a check for 900ms, optionally replacing the whole label while preserving width; `onSuccessFinished` reports only a completed hold (MM-02, MM-03, MM-04).",
    "IconButton": "Presses to 0.97; `active` changes fade over `motion-select`; `turns` rotates a chevron; `nudge` moves the icon 2px on activation (MM-02, MM-05, MM-07).",
    "ToolbarButton": "Presses to 0.97; `nudge` moves the icon in its direction (Push up, Pull and Fetch down, Refresh a turn); the `badge` pops in, rolls, and shrinks away (MM-02, MM-06, MM-07).",
    "FloatingButton": "Presses to 0.97 and springs back (MM-02).",
    "TextField": "Focus grows a 1px halo over `motion-quick`; `rejectCount` shakes the field once and the message rises in; a numeric `trailingText` rolls (MM-08, MM-09, MM-10).",
    "Checkbox": "The fill pops from 0.6 on `spring-pop` and the check draws in 140ms after 40ms; unchecking fades and erases it (MM-11).",
    "Switch": "The thumb springs across on `spring-snappy` and stretches towards its travel while pressed (MM-12).",
    "Radio": "The dot pops in on `spring-pop` and shrinks out over `motion-exit` (MM-13).",
    "Segmented": "The raised tile glides to the chosen segment on `spring-snappy` (MM-14).",
    "Slider": "The thumb grows to 1.15 while hovered or dragged; the fill follows the pointer exactly (MM-15).",
    "Select": "The chevron turns half a turn while the menu is open (MM-16).",
    "Kbd": "`pressed` (or holding the whole chord) sinks the cap 1px and drops its lip (MM-17).",
    "ListRow": "In a `MeridianList.builder` with `selectedIndex` the selection bar glides between rows; hover actions slide in; `revealKey` grows a new row in once; `attention` tints a changed row (MM-20 to MM-23).",
    "NavRow": "Sections reveal their rows and stagger the first six in; the current check travels between rows of a section (MM-24, MM-25).",
    "Breadcrumbs": "The hover fill fades in over `motion-hover`; folding and unfolding the middle is instant, so the trail never moves under the pointer.",
    "Tabs": "The rule or pill glides to the active tab; `tabKeys` grow new tabs in and collapse closed ones (MM-26, MM-27).",
    "Pagination": "The current page's pill glides (MM-29).",
    "SelectionBar": "`visible` lets it rise in from 12px on `spring-gentle` and leave downwards; a leading count rolls (MM-30).",
    "Menu": "Grows from its anchor over `motion-overlay` and leaves in `motion-exit`; the highlight moves to the hovered or keyboard row at once, without gliding; submenus enter from their side (MM-40 to MM-43).",
    "Popover": "Grows from its anchor over `motion-overlay` and leaves in `motion-exit` (MM-40, MM-41).",
    "Suggestions": "Grows from its field like a popover (MM-40, MM-41).",
    "Dialog": "Grows from 0.96 and rises 8px over `motion-dialog`; leaves in `motion-exit`; `submitDisabled` shakes it when Enter hits a disabled primary (MM-45 to MM-47).",
    "Sheet": "Slides in over `motion-sheet` on the enter curve and closes over `motion-exit` (MM-48).",
    "Panel": "Grows from its `origin` like an overlay (MM-40).",
    "Toast": "Arrives from below (and the trailing side on desktop) on `spring-gentle`; an action toast shows a shrinking time rule that pauses on hover; it leaves 8px outwards (MM-49, MM-50).",
    "Progress": "The sweep morphs into the value bar; at 100% the bar holds 300ms and fades unless `persistent`; the Spinner waits 150ms before it shows (MM-60 to MM-63).",
    "Skeleton": "Breathes between 0.55 and 1; `MeridianSkeleton.swap` crossfades the loaded content in (MM-64).",
    "Banner": "`visible` reveals and collapses it; a tone change fades the colours and swaps the icon (MM-65, MM-66).",
    "EmptyState": "Icon, headline, text and action enter one after the other, once (MM-67); the progress spinner waits 150ms before it shows.",
    "FindBar": "`visible` reveals and collapses it (MM-24 reveal), at once with reduce motion; the counter swaps with a roll (MM-70).",
    "SplitPane": "150ms into a hover the handle's `accent` line grows from its centre (MM-75); the panes follow the pointer exactly.",
    "BusyOverlay": "Blocks input at once and shows after 150ms (MM-68).",
    "StatusDot": "`live` pulses a halo; it holds still with reduce motion (MM-69).",
    "Count": "Whole numbers roll digit by digit; `emphasizeIncrease` pops on increase (MM-70).",
    "Avatar": "A loaded image fades in over the initials (MM-71).",
    "Chip": "Presses to 0.97; `visible: false` fades it and collapses its width (MM-02, MM-72).",
    "Island": "The focus halo fades in and out; `contentKey` swaps content with a rise, instantly while scrubbing (MM-73, MM-74).",
    "Disclosure": "The chevron turns and the body reveals (MM-24).",
    "ResizeHandle": "150ms into a hover an `accent` line grows from its centre (MM-75).",
    "StatusBar": "Text items swap with a 3px rise (MM-76).",
    "DropZone": "While a drag is over it the dashed edge marches (MM-77).",
}

PREVIEW = """<!-- @dsCard group="{group}" height={height} -->
<!doctype html>
<html>
<head><meta charset="utf-8"><title>{name} · Meridian</title></head>
<body>
<div id="root"></div>
<script>
var M = window.Meridian, h = React.createElement;
function mount(el) {{ ReactDOM.createRoot(document.getElementById('root')).render(el); }}
{js}
</script>
</body>
</html>
"""

if __name__ == "__main__":
    for name, group, height, readme, js in C:
        if name in MOTION:
            readme = readme.rstrip("\n") + f"\n- Motion: {MOTION[name]}\n"
        d = OUT / name
        d.mkdir(parents=True, exist_ok=True)
        (d / "README.md").write_text(readme)
        (d / "preview.html").write_text(PREVIEW.format(group=group, height=height, name=name, js=js))
    print(f"{len(C)} components")
