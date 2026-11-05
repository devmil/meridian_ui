const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const React = require('react');
const Renderer = require('react-test-renderer');
const context = { window: { React }, setTimeout, clearTimeout };
vm.runInNewContext(fs.readFileSync(path.join(__dirname,
  '../design/project/components/bundle.js'), 'utf8'), context);
const Field = context.window.Meridian.ShortcutField;

function fixture(overrides = {}) {
  let renderer, requested = 0, cancelled = 0, cleared = 0, focused = 0;
  const strokes = [];
  let props = {
    label: 'Capture', keys: ['Ctrl', '4'], emptyLabel: 'No shortcut',
    recordingLabel: 'Press a shortcut', preparingLabel: 'Preparing', clearLabel: 'Clear shortcut',
    onRecordRequested: () => requested++, onCancelRecording: () => cancelled++,
    onClear: () => cleared++, onRecorded: value => strokes.push(value), ...overrides,
  };
  Renderer.act(() => {
    renderer = Renderer.create(React.createElement(Field, props), {
      createNodeMock: () => ({ focus: () => focused++ }),
    });
  });
  return {
    renderer, strokes,
    get buttons() { return renderer.root.findAllByType('button'); },
    get counts() { return { requested, cancelled, cleared, focused }; },
    update(next) { props = { ...props, ...next }; Renderer.act(() => renderer.update(React.createElement(Field, props))); },
    key(code, extra = {}) {
      let prevented = 0;
      Renderer.act(() => this.buttons[0].props.onKeyDown({ code,
        preventDefault: () => prevented++, stopPropagation() {}, ...extra }));
      return prevented;
    },
    close() { Renderer.act(() => renderer.unmount()); },
  };
}

test('controlled arming and physical metadata never retain a character', () => {
  const f = fixture();
  Renderer.act(() => f.buttons[0].props.onClick());
  assert.equal(f.counts.requested, 1);
  assert.equal(f.key('KeyZ', { key: 'y' }), 0);
  assert.equal(f.strokes.length, 0);
  f.update({ recording: true });
  assert.equal(f.counts.focused, 1);
  f.key('KeyZ', { key: 'y', ctrlKey: true, shiftKey: true, altKey: true, metaKey: true });
  assert.equal(JSON.stringify(f.strokes[0]), JSON.stringify({ physicalCode: 'KeyZ', control: true, shift: true, alt: true, meta: true }));
  assert.equal(f.buttons[0].props['aria-label'], 'Capture: Press a shortcut');
  f.update({ recording: false });
  assert.equal(f.buttons[0].props['aria-label'], 'Capture: Ctrl + 4');
  f.close();
});

test('modifiers, repeats and composition never emit', () => {
  const f = fixture({ recording: true });
  for (const code of ['ControlLeft', 'ShiftRight', 'AltRight', 'MetaLeft', 'Fn']) f.key(code);
  f.key('KeyA', { repeat: true });
  f.key('KeyA', { isComposing: true });
  f.key('');
  assert.equal(f.strokes.length, 0);
  f.key('Enter');
  f.key('Space');
  assert.equal(f.strokes.length, 2);
  f.close();
});

for (const [code, shiftKey, prevents] of [['Escape', false, 1], ['Tab', false, 0], ['Tab', true, 0]]) {
  test(`${code}, shift=${shiftKey} cancels once even before the owner acknowledges`, () => {
    const f = fixture({ recording: true });
    assert.equal(f.key(code, { shiftKey }), prevents);
    Renderer.act(() => f.buttons[0].props.onBlur());
    f.key('KeyA');
    assert.equal(f.counts.cancelled, 1);
    assert.equal(f.strokes.length, 0);
    f.update({ recording: false });
    f.update({ recording: true });
    f.key('KeyA');
    assert.equal(f.strokes.length, 1);
    f.close();
  });
}

test('disable cancels once, preparing ignores activation and clear stays separately named', () => {
  const f = fixture({ recording: true });
  f.update({ enabled: false });
  f.update({ preparing: true });
  assert.equal(f.counts.cancelled, 1);
  Renderer.act(() => { f.buttons[0].props.onClick(); f.buttons[1].props.onClick(); });
  f.key('KeyA');
  assert.equal(f.counts.requested, 0);
  assert.equal(f.counts.cleared, 0);
  assert.equal(f.strokes.length, 0);
  assert.equal(f.buttons[1].props['aria-label'], 'Clear shortcut');
  f.update({ enabled: true, preparing: false, recording: false });
  Renderer.act(() => f.buttons[1].props.onClick());
  assert.equal(f.counts.cleared, 1);
  f.close();
});
