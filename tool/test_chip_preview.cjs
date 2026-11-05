// The enlarged-label guideline exercises the generated React rendition.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');
const React = require('react');
const Renderer = require('react-test-renderer');
const context = { window: { React } };
vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../design/project/components/bundle.js'), 'utf8'), context);

test('enlarged chip keeps its label, selection and requested typography', () => {
  const style = { fontSize: '24px', lineHeight: '32px', maxWidth: '360px' };
  let renderer;
  Renderer.act(() => {
    renderer = Renderer.create(React.createElement(context.window.Meridian.Chip,
      { selected: true, icon: 'pencil', style }, 'Danach bearbeiten'));
  });
  try {
    const button = renderer.root.findByType('button');
    assert.equal(button.props['aria-pressed'], 'true');
    assert.deepEqual(button.props.style, style);
    assert.deepEqual(renderer.root.findByProps({ className: 'nm' }).children, ['Danach bearbeiten']);
  } finally { Renderer.act(() => renderer.unmount()); }
});
