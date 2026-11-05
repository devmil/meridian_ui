// Uses the same isolated React 18.3.1 fixture as test_button_preview.cjs.
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
const Split = context.window.Meridian.SplitButton;

function fixture(props = {}) {
  let renderer, focus = 0;
  Renderer.act(() => {
    renderer = Renderer.create(React.createElement(Split, {
      icon: 'save', optionsLabel: 'Save options', entries: ['Save as…'], ...props,
    }, 'Save'), { createNodeMock: () => ({ focus: () => focus++ }) });
  });
  return { renderer, get buttons() { return renderer.root.findAllByType('button'); },
    get focus() { return focus; }, close() { Renderer.act(() => renderer.unmount()); } };
}

test('disabled command leaves alternatives available and restores focus', () => {
  const selected = [];
  const f = fixture({ disabled: true, onSelected: value => selected.push(value) });
  assert.equal(f.buttons[0].props.disabled, true);
  Renderer.act(() => f.buttons[1].props.onClick());
  assert.equal(f.buttons[1].props['aria-expanded'], true);
  Renderer.act(() => f.buttons[2].props.onClick());
  assert.deepEqual(selected, ['Save as…']);
  assert.equal(f.buttons.length, 2);
  assert.equal(f.focus, 1);
  f.close();
});

test('compact loading retains its accessible name and ignores command activation', () => {
  let invoked = 0;
  const f = fixture({ compact: true, loading: true, onClick: () => invoked++ });
  assert.equal(f.buttons[0].props['aria-label'], 'Save');
  assert.equal(f.buttons[0].props['aria-busy'], 'true');
  Renderer.act(() => f.buttons[0].props.onClick());
  assert.equal(invoked, 0);
  f.close();
});

test('Escape closes the menu and disabled options cannot reopen it', () => {
  const f = fixture();
  Renderer.act(() => f.buttons[1].props.onClick());
  let prevented = 0;
  Renderer.act(() => f.renderer.root.findAllByType('span')[0].props.onKeyDown({
    key: 'Escape', preventDefault: () => prevented++,
  }));
  assert.equal(f.buttons.length, 2);
  assert.equal(prevented, 1);
  assert.equal(f.focus, 1);
  f.close();
  const disabled = fixture({ optionsEnabled: false });
  Renderer.act(() => disabled.buttons[1].props.onClick());
  assert.equal(disabled.buttons.length, 2);
  disabled.close();
});
