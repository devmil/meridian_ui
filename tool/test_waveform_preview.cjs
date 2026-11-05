// Check the generated decorative SVG without a DOM or media decoder.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const React = { createElement: (type, props, ...children) => ({ type, props, children }) };
const context = { window: { React } };
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../design/project/components/bundle.js'), 'utf8'), context);
const waveform = context.window.Meridian.Waveform;

test('chronological amplitudes and progress mirror in RTL', () => {
  for (const rtl of [false, true]) {
    const svg = waveform({ peaks: [0.25, 1], width: 80, height: 40, progress: 0.5, rtl });
    assert.equal(svg.type, 'svg');
    assert.equal(svg.props['aria-hidden'], 'true');
    assert.equal(svg.props.style.pointerEvents, 'none');
    assert.equal(svg.children[0].props.d, rtl ? 'M40.25 15h39.5v10h-39.5Z M0.25 0h39.5v40h-39.5Z' : 'M0.25 15h39.5v10h-39.5Z M40.25 0h39.5v40h-39.5Z');
    assert.equal(svg.children[1].props.style.clipPath, rtl ? 'inset(0 0 0 50%)' : 'inset(0 50% 0 0)');
  }
});
test('bounded validation preserves empty, zero-width and silent states', () => {
  assert.equal(waveform({ peaks: [], width: 0 }).props.width, 0);
  assert.equal(waveform({ peaks: [] }).children[0].props.d, '');
  assert.match(waveform({ peaks: [0], height: 24 }).children[0].props.d, /v1h/);
  for (const peaks of [null, [NaN], [Infinity], [-0.1], [1.1], new Array(1025).fill(0)]) {
    assert.throws(() => waveform({ peaks }), /bounded normalized peaks/);
  }
  for (const height of [0, -1, NaN, Infinity]) assert.throws(() => waveform({ peaks: [], height }), /valid geometry/);
  for (const width of [-1, NaN, Infinity]) assert.throws(() => waveform({ peaks: [], width }), /valid geometry/);
  for (const progress of [-0.1, 1.1, NaN, Infinity]) assert.throws(() => waveform({ peaks: [], progress }), /valid progress/);
});
