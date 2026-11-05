// Headless web-rendition contract. Install React 18.3.1 and react-test-renderer
// 18.3.1 in an isolated directory, then supply that directory through NODE_PATH.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const React = require('react');
const Renderer = require('react-test-renderer');
const root = path.resolve(__dirname, '..');
const hold = fs.readFileSync(path.join(root, 'design/project/motion.css'), 'utf8')
  .match(/--motion-hold:\s*([^;]+);/)[1];

function fixture(initial = {}) {
  let now = 0, serial = 0;
  const timers = new Map();
  const context = {
    window: { React },
    getComputedStyle: () => ({ getPropertyValue: () => hold }),
    setTimeout: (callback, duration) => {
      const id = ++serial;
      timers.set(id, { callback, deadline: now + duration });
      return id;
    },
    clearTimeout: id => timers.delete(id),
  };
  vm.runInNewContext(fs.readFileSync(path.join(root, 'design/project/components/bundle.js'), 'utf8'), context);
  const Button = context.window.Meridian.Button;
  let props = { successReplacesLabel: true, ...initial };
  const render = () => React.createElement(Button, props, 'Kennung kopieren');
  let renderer;
  Renderer.act(() => { renderer = Renderer.create(render(), { createNodeMock: () => ({}) }); });
  return {
    get button() { return renderer.root.findByType('button'); },
    get checked() { return renderer.root.findByType('button').props.className.split(' ').includes('checked'); },
    get pending() { return timers.size; },
    update(changes) {
      props = { ...props, ...changes };
      Renderer.act(() => renderer.update(render()));
    },
    advance(duration) {
      const target = now + duration;
      Renderer.act(() => {
        while (true) {
          const due = [...timers.entries()].filter(([, timer]) => timer.deadline <= target)
            .sort((a, b) => a[1].deadline - b[1].deadline)[0];
          if (!due) break;
          now = due[1].deadline;
          timers.delete(due[0]);
          due[1].callback();
        }
        now = target;
      });
    },
    dispose() { Renderer.act(() => renderer.unmount()); },
  };
}

test('confirmation keeps the accessible name and reports only its accepted callback', () => {
  let first = 0, later = 0;
  const f = fixture({ success: false, onSuccessFinished: () => first++ });
  try {
    const button = f.button;
    f.update({ success: true });
    assert.equal(f.button, button);
    assert.equal(f.checked, true);
    assert.equal(f.button.props['aria-label'], 'Kennung kopieren');
    f.update({ onSuccessFinished: () => later++ });
    f.advance(899);
    assert.equal(first, 0);
    f.advance(1);
    assert.equal(first, 1);
    assert.equal(later, 0);
    assert.equal(f.checked, false);
    f.advance(900);
    assert.equal(first, 1);
  } finally { f.dispose(); }
  assert.equal(f.pending, 0);
});

for (const reason of ['cleared success', 'new loading', 'unmount']) {
  test(`${reason} cancels the confirmation report`, () => {
    let calls = 0;
    const f = fixture({ success: false, onSuccessFinished: () => calls++ });
    f.update({ success: true });
    f.advance(100);
    if (reason === 'unmount') f.dispose();
    else f.update(reason === 'new loading' ? { loading: true } : { success: false });
    f.advance(900);
    assert.equal(calls, 0);
    assert.equal(f.pending, 0);
    if (reason !== 'unmount') f.dispose();
  });
}

test('loading suppresses activation without removing the button', () => {
  let calls = 0;
  const f = fixture({ onClick: () => calls++ });
  try {
    const button = f.button;
    f.update({ loading: true });
    f.button.props.onClick({});
    assert.equal(calls, 0);
    assert.equal(f.button, button);
    assert.equal(f.button.props['aria-busy'], 'true');
    f.update({ loading: false });
    f.button.props.onClick({});
    assert.equal(calls, 1);
  } finally { f.dispose(); }
});

test('mounting successful output does not replay an earlier confirmation', () => {
  let calls = 0;
  const f = fixture({ success: true, onSuccessFinished: () => calls++ });
  try {
    assert.equal(f.checked, false);
    f.advance(900);
    assert.equal(calls, 0);
    f.update({ success: false });
    f.update({ success: true });
    f.advance(900);
    assert.equal(calls, 1);
  } finally { f.dispose(); }
});

test('a fresh success edge cancels the old timer and gets one complete hold', () => {
  let calls = 0;
  const f = fixture({ success: false, onSuccessFinished: () => calls++ });
  try {
    f.update({ success: true });
    f.advance(100);
    f.update({ success: false });
    f.update({ success: true });
    f.advance(800);
    assert.equal(calls, 0);
    f.advance(100);
    assert.equal(calls, 1);
  } finally { f.dispose(); }
});
