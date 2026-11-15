(function () {
  var React = window.React, h = React.createElement, useState = React.useState;
  var ICONS = __ICONS__;
  function cx() { var o = []; for (var i = 0; i < arguments.length; i++) if (arguments[i]) o.push(arguments[i]); return o.join(' '); }
  function omit(p, keys) { var o = {}; for (var k in p) if (keys.indexOf(k) < 0) o[k] = p[k]; return o; }
  var SERIES = ['var(--series-1)', 'var(--series-2)', 'var(--series-3)', 'var(--series-4)', 'var(--series-5)', 'var(--series-6)', 'var(--series-7)', 'var(--series-8)'];
  var ORDER = [0, 1, 5, 4, 6, 3, 2, 7];

  function Icon(p) {
    var inner = ICONS[p.name] || ICONS['circle-dot'];
    return h('svg', { className: cx('mr-icon', p.size === 'sm' && 'sm', p.className), viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', strokeWidth: p.stroke || 2, strokeLinecap: 'round', strokeLinejoin: 'round', 'aria-hidden': 'true', style: p.style, dangerouslySetInnerHTML: { __html: inner } });
  }
  Icon.names = Object.keys(ICONS);

  function Kbd(p) {
    var keys = p.keys || [p.children];
    return h('span', { className: 'mr-kbds' }, keys.map(function (k, i) { return h('kbd', { key: i, className: 'mr-kbd' }, k); }));
  }

  function Count(p) { return h('span', { className: cx('mr-count', p.tone && p.tone !== 'neutral' && p.tone) }, p.children); }

  function Spinner() { return h('span', { className: 'mr-spin', 'aria-hidden': 'true' }); }

  function Button(p) {
    var v = p.variant || 'secondary';
    var checkedState = useState(false), checked = checkedState[0], setChecked = checkedState[1];
    var previous = React.useRef(!!p.success);
    var element = React.useRef(null);
    React.useEffect(function () {
      var rising = p.success && !previous.current;
      previous.current = !!p.success;
      if (p.loading || !p.success) { setChecked(false); return; }
      if (!rising) return;
      setChecked(true);
      // Bind this report to the owner of the success edge, just like Flutter.
      var finished = p.onSuccessFinished;
      var token = getComputedStyle(element.current).getPropertyValue('--motion-hold').trim();
      var hold = parseFloat(token) * (token.endsWith('ms') ? 1 : 1000);
      var timer = setTimeout(function () { setChecked(false); if (finished) finished(); }, hold);
      return function () { clearTimeout(timer); };
    }, [p.success, p.loading]);
    var rest = omit(p, ['variant', 'size', 'iconOnly', 'icon', 'trailingIcon', 'shortcut', 'loading', 'success', 'successReplacesLabel', 'onSuccessFinished', 'expand', 'children', 'className', 'onClick']);
    var normal = h('span', { className: 'mr-btn-content', 'aria-hidden': p.successReplacesLabel ? 'true' : undefined },
      p.loading ? h(Spinner) : (checked && !p.successReplacesLabel ? h(Icon, { name: 'check', size: 'sm' }) : (p.icon ? h(Icon, { name: p.icon, size: 'sm' }) : null)),
      p.iconOnly ? null : p.children,
      p.trailingIcon ? h(Icon, { name: p.trailingIcon, size: 'sm' }) : null,
      p.shortcut ? h(Kbd, { keys: p.shortcut }) : null);
    return h('button', Object.assign({ type: 'button', ref: element }, rest, {
      className: cx('mr-btn', v !== 'secondary' && v, p.size === 'sm' && 'sm', p.expand && 'expand', p.iconOnly && 'icon-only', p.successReplacesLabel && 'label-confirmation', checked && 'checked', p.success && 'success', p.className),
      'aria-label': (p.successReplacesLabel || p.iconOnly) ? (p['aria-label'] || p.children) : p['aria-label'],
      'aria-busy': p.loading ? 'true' : undefined,
      onClick: function (event) { if (!p.loading && p.onClick) p.onClick(event); }
    }), normal, p.successReplacesLabel ? h('span', { className: 'mr-btn-check', 'aria-hidden': 'true' }, h(Icon, { name: 'check', size: 'sm' })) : null);
  }

  function SplitButton(p) {
    var state = useState(false), expanded = state[0], setExpanded = state[1];
    var caret = React.useRef(null);
    function close() { setExpanded(false); if (caret.current) caret.current.focus(); }
    return h('span', { className: 'mr-split', onKeyDown: function (event) { if (event.key === 'Escape' && expanded) { event.preventDefault(); close(); } } },
      h(Button, { variant: 'primary', icon: p.icon, iconOnly: p.compact, disabled: p.disabled, loading: p.loading, onClick: p.onClick }, p.children),
      h('button', { ref: caret, type: 'button', className: 'mr-ibtn', disabled: p.optionsEnabled === false, 'aria-label': p.optionsLabel, 'aria-expanded': expanded, 'aria-haspopup': 'menu', onClick: function () { if (p.optionsEnabled !== false) setExpanded(!expanded); } }, h(Icon, { name: 'chevron-down' })),
      expanded ? h('span', { className: 'mr-split-menu', role: 'menu' }, (p.entries || []).map(function (entry) { return h('button', { key: entry, type: 'button', role: 'menuitem', className: 'mr-menu-item', onClick: function () { close(); if (p.onSelected) p.onSelected(entry); } }, entry); })) : null);
  }

  function ButtonConfirmationDemo() {
    var state = useState(false), success = state[0], setSuccess = state[1];
    return h(Button, { icon: 'copy', success: success, successReplacesLabel: true, disabled: success,
      onClick: function () { setSuccess(true); }, onSuccessFinished: function () { setSuccess(false); } }, 'Copy ID');
  }

  function IconButton(p) {
    var rest = omit(p, ['icon', 'label', 'size', 'active', 'onGround', 'className']);
    return h('button', Object.assign({ type: 'button' }, rest, { className: cx('mr-ibtn', p.size === 'sm' && 'sm', p.active && 'active', p.onGround && 'on-ground', p.className), 'aria-label': p.label, title: p.label, 'aria-pressed': p.active === undefined ? undefined : String(!!p.active) }),
      h(Icon, { name: p.icon, size: p.size === 'sm' ? 'sm' : undefined }));
  }

  function ToolbarButton(p) {
    var btn = h('button', { type: 'button', className: 'mr-tbtn', disabled: p.disabled, title: p.label },
      h(Icon, { name: p.icon, stroke: 1.75 }), p.showLabel === false ? null : h('span', { className: 'lbl' }, p.label),
      p.badge ? h(Count, { tone: 'accent' }, p.badge) : null);
    if (!p.menu) return btn;
    return h('span', { className: 'mr-tsplit' }, btn, h('button', { type: 'button', className: 'caret', 'aria-label': p.label + ' options' }, h(Icon, { name: 'chevron-down', style: { width: 10, height: 10 } })));
  }

  function ShortcutField(p) {
    var element = React.useRef(null), cancelled = React.useRef(false), previous = React.useRef(false);
    var enabled = p.enabled !== false && !p.preparing && !!p.onRecordRequested && !!p.onRecorded;
    function cancel() {
      if (!p.recording || cancelled.current) return;
      cancelled.current = true;
      if (p.onCancelRecording) p.onCancelRecording();
    }
    React.useEffect(function () {
      if (p.recording && !previous.current) {
        cancelled.current = false;
        if (enabled && element.current) element.current.focus();
      }
      previous.current = !!p.recording;
      if (p.recording && !enabled) cancel();
    }, [p.recording, enabled]);
    var keys = p.keys || [];
    var value = p.preparing ? p.preparingLabel : p.recording ? p.recordingLabel : keys.length ? keys.join(' + ') : p.emptyLabel;
    return h('div', { className: 'mr-shortcut-field', style: { width: p.width } },
      p.showLabel === false ? null : h('span', { className: 'mr-shortcut-label' }, p.label),
      h('div', { className: 'mr-shortcut-row' },
        h('button', { type: 'button', ref: element, disabled: !enabled, className: cx('mr-shortcut-control', p.recording && 'recording'),
          'aria-label': p.label + ': ' + value, 'aria-live': p.recording || p.preparing ? 'polite' : undefined,
          onClick: function () { if (enabled) { if (p.recording) cancel(); else p.onRecordRequested(); } },
          onBlur: cancel,
          onKeyDown: function (event) {
            if (!p.recording || !enabled) return;
            var command = event.ctrlKey || event.altKey || event.metaKey;
            if (!command && event.code === 'Tab') { cancel(); return; }
            event.preventDefault(); event.stopPropagation();
            if (cancelled.current || event.repeat || event.isComposing) return;
            if (!command && !event.shiftKey && event.code === 'Escape') { cancel(); return; }
            if (!event.code || /^(Control|Shift|Alt|Meta)(Left|Right)$/.test(event.code) || /^(Fn|FnLock|Hyper|Super|Symbol|SymbolLock)$/.test(event.code)) return;
            p.onRecorded({ physicalCode: event.code, control: !!event.ctrlKey, shift: !!event.shiftKey, alt: !!event.altKey, meta: !!event.metaKey });
          }
        }, keys.length && !p.recording && !p.preparing ? h(Kbd, { keys: keys }) : value),
        keys.length && p.onClear ? h(IconButton, { icon: 'x', label: p.clearLabel, disabled: !enabled, onClick: function () { if (enabled) p.onClear(); } }) : null),
      p.conflict ? h('div', { className: 'mr-shortcut-conflict', 'aria-live': 'polite' }, p.conflict) : null);
  }

  function ShortcutFieldDemo(p) {
    var chord = useState(p.keys || []), active = useState(false);
    return h(ShortcutField, Object.assign({}, p, {
      keys: chord[0], recording: active[0], enabled: !p.disabled,
      emptyLabel: 'No shortcut', recordingLabel: 'Press a shortcut', preparingLabel: 'Preparing recording', clearLabel: 'Clear shortcut',
      onRecordRequested: function () { active[1](true); }, onCancelRecording: function () { active[1](false); },
      onClear: function () { chord[1]([]); active[1](false); },
      onRecorded: function (stroke) {
        var caps = [];
        if (stroke.control) caps.push('Ctrl'); if (stroke.shift) caps.push('Shift'); if (stroke.alt) caps.push('Alt'); if (stroke.meta) caps.push('Meta');
        caps.push(stroke.physicalCode); chord[1](caps); active[1](false);
      }
    }));
  }

  function TextField(p) {
    var area = p.multiline;
    var field = h('label', { className: cx('mr-field', p.variant === 'search' && 'search', p.variant === 'plain' && 'plain', p.size === 'sm' && 'sm', p.error && 'error', area && 'area', p.monospace && 'mono'), style: p.width ? { width: p.width } : undefined },
      (p.icon || p.variant === 'search') ? h(Icon, { name: p.icon || 'search', size: 'sm' }) : null,
      area ? h('textarea', { rows: p.rows || 3, placeholder: p.placeholder, defaultValue: p.value, 'aria-label': p.label || p.placeholder })
        : h('input', { placeholder: p.placeholder, defaultValue: p.value, type: p.type, 'aria-label': p.label || p.placeholder, 'aria-invalid': p.error ? 'true' : undefined }),
      p.trailing ? h('span', { className: 'trail' }, p.trailing) : null,
      p.clear && p.value ? h(IconButton, { icon: 'x', label: p.clear, size: 'sm' }) : null);
    if (!p.label && !p.message && !p.error) return field;
    return h('span', { className: 'mr-fieldwrap' },
      p.label ? h('span', { className: 'lbl' }, p.label) : null,
      field,
      (p.error || p.message) ? h('span', { className: cx('msg', p.error && 'err') }, p.error || p.message) : null);
  }

  function Checkbox(p) {
    var s = useState(p.checked === undefined ? false : p.checked); var on = s[0], set = s[1];
    var mixed = p.mixed && !on;
    return h('label', { className: cx('mr-check', on && 'on', mixed && 'mixed', p.disabled && 'disabled', p.description && 'top'), onClick: function (e) { e.preventDefault(); if (!p.disabled) set(!on); } },
      h('span', { className: 'box', role: 'checkbox', tabIndex: p.disabled ? -1 : 0, 'aria-checked': mixed ? 'mixed' : String(on), 'aria-disabled': p.disabled ? 'true' : undefined },
        on ? h(Icon, { name: 'check', stroke: 3 }) : mixed ? h(Icon, { name: 'minus', stroke: 3 }) : null),
      h('span', null, p.children, p.description ? h('span', { className: 'desc' }, p.description) : null));
  }

  function Radio(p) {
    return h('label', { className: cx('mr-check radio', p.checked && 'on', p.disabled && 'disabled', p.description && 'top') },
      h('span', { className: 'box', role: 'radio', tabIndex: p.checked ? 0 : -1, 'aria-checked': String(!!p.checked) }),
      h('span', null, p.children, p.description ? h('span', { className: 'desc' }, p.description) : null));
  }

  function RadioGroup(p) {
    var s = useState(p.value); var val = s[0], set = s[1];
    return h('div', { role: 'radiogroup', 'aria-label': p.label, style: { display: 'flex', flexDirection: 'column', gap: 'var(--space-4)' } },
      p.options.map(function (o) { return h('div', { key: o.value, onClick: function () { set(o.value); } }, h(Radio, { checked: o.value === val, description: o.description }, o.label)); }));
  }

  function Switch(p) {
    var s = useState(!!p.checked); var on = s[0], set = s[1];
    return h('label', { className: cx('mr-switch', on && 'on', p.disabled && 'disabled'), onClick: function (e) { e.preventDefault(); if (!p.disabled) set(!on); } },
      h('span', { className: 'track', role: 'switch', tabIndex: 0, 'aria-checked': String(on), 'aria-label': p.children }),
      p.hideLabel ? null : p.description ? h('span', null, p.children, h('span', { className: 'desc' }, p.description)) : p.children);
  }

  function ColorSwatch(p) {
    var check = p.check || (p.light ? '#0F1B21' : '#FFFFFF'); // contrasts with the swatch (content), not the theme, as in Flutter
    return h('button', { type: 'button', className: cx('mr-swatch', p.selected && 'on'), disabled: p.disabled, title: p.label, 'aria-label': p.label, 'aria-pressed': String(!!p.selected) },
      h('span', { className: 'disc', style: { background: p.color, color: check } }, p.selected ? h(Icon, { name: 'check', size: 'sm', stroke: 3 }) : null));
  }

  // Colour arithmetic for the previews: the picker shows content colours.
  function hsvToHex(hue, sat, val) {
    function f(n) { var k = (n + hue / 60) % 6; return Math.round(255 * (val - val * sat * Math.max(0, Math.min(k, 4 - k, 1)))); }
    return '#' + [f(5), f(3), f(1)].map(function (c) { return c.toString(16).padStart(2, '0'); }).join('').toUpperCase();
  }

  function ColorPicker(p) {
    var hue = p.hue === undefined ? 212 : p.hue, sat = p.saturation === undefined ? 0.69 : p.saturation, val = p.value === undefined ? 0.31 : p.value;
    var color = hsvToHex(hue, sat, val), size = p.size || 200, r = sat * size / 2, a = hue * Math.PI / 180;
    function channel(name, shown, v, track) {
      return h('div', { className: 'channel' },
        h('div', { className: 'head' }, h('span', { className: 'mr-caption' }, name), h('span', { className: 'mr-numeric' }, shown)),
        h(Slider, { label: name, value: v, track: track }));
    }
    var hues = 'linear-gradient(90deg,' + [0, 60, 120, 180, 240, 300, 360].map(function (x) { return hsvToHex(x, 1, 1); }).join(',') + ')';
    var wheel = h('div', { className: 'wheel', role: 'slider', tabIndex: 0, 'aria-label': 'Hue and saturation', style: { width: size, height: size } },
      h('span', { className: 'thumb', style: { left: size / 2 + Math.cos(a) * r, top: size / 2 + Math.sin(a) * r, background: color } }));
    var controls = [
      h('div', { key: 'hex', className: 'mr-row' },
        h('span', { className: 'preview' }, p.original ? h('span', { title: 'Original colour', style: { background: p.original } }) : null, h('span', { style: { background: color } })),
        h(TextField, { value: color, monospace: true, label: 'Hex' })),
      h(Segmented, { key: 'model', label: 'Colour model', expand: true, value: 'hsv', options: [{ value: 'hsv', label: 'HSB' }, { value: 'rgb', label: 'RGB' }] }),
      h('div', { key: 'h' }, channel('Hue', hue + '°', hue / 360, hues)),
      h('div', { key: 's' }, channel('Saturation', Math.round(sat * 100) + '%', sat, 'linear-gradient(90deg,' + hsvToHex(hue, 0, val) + ',' + hsvToHex(hue, 1, val) + ')')),
      h('div', { key: 'b' }, channel('Brightness', Math.round(val * 100) + '%', val, 'linear-gradient(90deg,#000000,' + hsvToHex(hue, sat, 1) + ')'))];
    return h('div', { className: cx('mr-colorpicker', p.wide && 'wide'), style: { width: p.width || 320 } },
      (p.groups || []).map(function (g) {
        return h('div', { key: g.title, className: 'group' }, h('span', { className: 'mr-caption' }, g.title),
          h('div', { className: 'mr-row' }, g.colors.map(function (c) { return h(ColorSwatch, { key: c, color: c, label: c, selected: c === color, light: g.light && g.light.indexOf(c) >= 0 }); })));
      }),
      p.wide ? h('div', { className: 'side' }, wheel, h('div', { className: 'controls' }, controls)) : [wheel].concat(controls));
  }

  function ColorWell(p) {
    return h('button', { type: 'button', className: cx('mr-swatch', 'mr-colorwell', p.selected && 'on'), disabled: p.disabled, title: p.label, 'aria-label': p.label, 'aria-pressed': String(!!p.selected), 'aria-haspopup': 'dialog' },
      h('span', { className: 'disc' }, h('span', { className: 'core', style: p.color ? { background: p.color } : undefined }, p.color ? null : h(Icon, { name: 'plus', size: 'sm' }))));
  }

  function FloatingButton(p) {
    return h('button', { type: 'button', className: cx('mr-fab', p.extended && 'extended'), disabled: p.disabled, title: p.label, 'aria-label': p.label },
      h(Icon, { name: p.icon }), p.extended ? h('span', null, p.label) : null);
  }

  function Segmented(p) {
    var s = useState(p.value !== undefined ? p.value : (p.options[0] && p.options[0].value)); var val = s[0], set = s[1];
    return h('div', { className: cx('mr-seg', p.size === 'sm' && 'sm', p.expand && 'expand'), role: 'group', 'aria-label': p.label },
      p.options.map(function (o) {
        return h('button', { key: o.value, type: 'button', 'aria-pressed': String(o.value === val), 'aria-disabled': o.disabled ? 'true' : undefined, title: o.tooltip, 'aria-label': o.disabled ? o.label || o.tooltip : o.tooltip || o.label, onClick: o.disabled ? undefined : function () { set(o.value); } },
          o.icon ? h(Icon, { name: o.icon, size: 'sm' }) : null, o.label);
      }));
  }

  function Slider(p) {
    var v = p.value === undefined ? 0.5 : p.value;
    return h('div', { className: cx('mr-slider', p.track && 'track'), role: 'slider', tabIndex: 0, 'aria-label': p.label, 'aria-valuenow': Math.round(v * 100), 'aria-valuemin': 0, 'aria-valuemax': 100, style: p.width ? { width: p.width } : undefined },
      h('span', { className: 'rail', style: p.track ? { background: p.track } : undefined }),
      p.track ? null : h('span', { className: 'fill', style: { width: 'calc((100% - 12px) * ' + v + ')' } }),
      h('span', { className: 'thumb', style: { left: 'calc(6px + (100% - 12px) * ' + v + ')' } }));
  }

  function RangeSlider(p) {
    var start = p.start === undefined ? 0.2 : p.start;
    var end = p.end === undefined ? 0.8 : p.end;
    return h('div', { className: 'mr-slider', style: p.width ? { width: p.width } : undefined },
      h('span', { className: 'rail' }),
      h('span', { className: 'fill', style: { left: 'calc(6px + (100% - 12px) * ' + start + ')', width: 'calc((100% - 12px) * ' + (end - start) + ')' } }),
      [start, end].map(function(value, index) {
        return h('span', { key: index, className: 'thumb', role: 'slider', tabIndex: 0,
          'aria-label': index ? p.endLabel : p.startLabel,
          'aria-valuenow': Math.round(value * 100), 'aria-valuemin': index ? Math.round(start * 100) : 0,
          'aria-valuemax': index ? 100 : Math.round(end * 100),
          style: { left: 'calc(6px + (100% - 12px) * ' + value + ')' } });
      }));
  }

  function Select(p) {
    return h('button', { type: 'button', className: 'mr-select', style: p.width ? { width: p.width } : undefined, 'aria-haspopup': 'menu', 'aria-label': p.label ? p.label + ': ' + p.value : undefined },
      h('span', null, p.value), h(Icon, { name: 'chevron-down', size: 'sm' }));
  }

  function Menu(p) {
    var reserve = p.items.some(function (it) { return it.icon || it.dot || it.checked !== undefined; });
    return h('div', { className: 'mr-menu', role: 'menu', style: p.width ? { width: p.width } : undefined }, p.items.map(function (it, i) {
      if (it.type === 'divider') return h('div', { key: i, className: 'sep', role: 'separator' });
      if (it.type === 'header') return h('div', { key: i, className: 'hdr' }, it.label);
      if (it.type === 'custom') return h('div', { key: i, className: 'custom' }, it.content);
      return h('div', { key: i, role: it.checked !== undefined ? 'menuitemradio' : 'menuitem', 'aria-checked': it.checked !== undefined ? String(!!it.checked) : undefined, 'aria-haspopup': it.submenu ? 'menu' : undefined, className: cx('item', it.highlighted && 'hl', it.danger && 'danger', it.disabled && 'disabled'), 'aria-disabled': it.disabled ? 'true' : undefined },
        reserve ? (it.checked ? h(Icon, { name: 'check' }) : it.dot ? h('span', { className: 'slot' }, h('span', { className: 'dot', style: { background: it.dot } })) : it.icon ? h(Icon, { name: it.icon }) : h('span', { className: 'slot' })) : null,
        h('span', { className: 'grow' }, it.label),
        it.hint ? h('span', { className: 'hint' }, it.hint) : null,
        it.shortcut ? h(Kbd, { keys: it.shortcut }) : null,
        it.submenu ? h(Icon, { name: 'chevron-right', size: 'sm' }) : null);
    }));
  }

  function Tabs(p) {
    var s = useState(p.index || 0); var idx = s[0], set = s[1];
    return h('div', { className: cx('mr-tabs', p.variant === 'pill' && 'pill'), role: 'tablist' },
      p.tabs.map(function (t, i) {
        return h('button', { key: i, type: 'button', role: 'tab', 'aria-selected': String(i === idx), tabIndex: i === idx ? 0 : -1, className: 'tab', onClick: function () { set(i); } },
          t.icon ? h(Icon, { name: t.icon, size: 'sm' }) : null,
          h('span', { className: 'nm' }, t.label),
          t.dirty ? h('span', { className: 'dirty', 'aria-label': 'unsaved changes' }) : null,
          t.count !== undefined ? h(Count, null, t.count) : null,
          p.closable ? h('span', { className: 'x', 'aria-label': 'Close ' + t.label }, h(Icon, { name: 'x' })) : null);
      }));
  }

  function TabStrip(p) {
    var s = useState(p.active || (p.tabs[0] && p.tabs[0].label)); var active = s[0], set = s[1];
    var groups = {}; (p.groups || []).forEach(function (g) { groups[g.id] = g; });
    var seen = {}, out = [];
    function tab(t, i) {
      return h('button', { key: 't' + i, type: 'button', role: 'tab', 'aria-selected': String(t.label === active), tabIndex: t.label === active ? 0 : -1, className: 'tab', onClick: function () { set(t.label); } },
        t.icon ? h(Icon, { name: t.icon, size: 'sm' }) : null,
        h('span', { className: 'nm' }, t.label),
        t.dirty ? h('span', { className: 'dirty', 'aria-label': 'unsaved changes' }) : null,
        h('span', { className: 'x', 'aria-label': 'Close ' + t.label }, h(Icon, { name: 'x' })));
    }
    p.tabs.forEach(function (t, i) {
      var g = t.group !== undefined ? groups[t.group] : null;
      if (!g) { out.push(tab(t, i)); return; }
      if (!seen[g.id]) {
        seen[g.id] = [];
        var members = p.tabs.filter(function (o) { return o.group === g.id; });
        out.push(h('span', { key: 'g' + g.id, className: cx('group', g.collapsed && 'collapsed'), style: { '--group': g.color } },
          h('span', { className: 'chip', role: 'button', 'aria-expanded': String(!g.collapsed), 'aria-label': (g.name || 'Unnamed group') + ', tab group, ' + members.length + ' tabs' },
            g.icon ? h(Icon, { name: g.icon, size: 'sm' }) : null,
            g.name ? h('span', null, g.name) : (g.icon ? null : h('span', { className: 'dot' })),
            g.collapsed ? h('span', { className: 'count' }, members.length) : null),
          g.collapsed ? null : members.map(function (m) { return tab(m, p.tabs.indexOf(m)); })));
      }
    });
    return h('div', { className: 'mr-tabs pill mr-tabstrip', role: 'tablist' }, out);
  }

  function NavSection(p) {
    return h('div', null,
      h('div', { className: 'mr-sec', role: 'heading', 'aria-level': 3 }, h('span', { className: 'grow' }, p.title),
        p.action ? h(IconButton, { icon: p.action, label: p.actionLabel || p.action, size: 'sm', onGround: true }) : null,
        p.count !== undefined ? h(Count, { tone: 'quiet' }, p.count) : null),
      p.children);
  }

  function NavRow(p) {
    var pad = { paddingLeft: 'calc(var(--space-4) + ' + ((p.depth || 0) * 14) + 'px)' };
    return h('div', { className: cx('mr-nrow', p.current && 'current', p.state), style: pad, role: 'treeitem', 'aria-selected': p.state ? 'true' : 'false', 'aria-expanded': p.expandable ? String(!!p.open) : undefined },
      p.expandable ? h(Icon, { name: p.open ? 'chevron-down' : 'chevron-right', className: 'chev' }) : (p.depth ? h('span', { className: 'spacer' }) : null),
      p.icon ? h(Icon, { name: p.icon, size: 'sm', style: p.iconColor && !p.current && p.state !== 'focused' ? { color: p.iconColor } : undefined }) : null,
      h('span', { className: 'name' }, p.name),
      p.current ? h(Icon, { name: 'check', size: 'sm' }) : null,
      p.count !== undefined ? h(Count, { tone: p.countTone || 'quiet' }, p.count) : null);
  }

  function Avatar(p) {
    var name = p.name || '?';
    var parts = name.trim().split(/[\s._@-]+/).filter(Boolean);
    var initials = parts.length === 0 ? '?' : parts.length === 1 ? parts[0][0].toUpperCase() : (parts[0][0] + parts[1][0]).toUpperCase();
    var key = (p.colorKey || name).toLowerCase(), hash = 0;
    for (var i = 0; i < key.length; i++) hash = (hash * 31 + key.charCodeAt(i)) & 0x7fffffff;
    return h('span', { className: cx('mr-avatar', p.size === 'xl' && 'xl', p.size === 'lg' && 'lg', p.size === 'md' && 'md'), 'aria-hidden': 'true', style: { background: SERIES[ORDER[hash % 8]] } }, p.monogram || initials);
  }

  function matched(text, query) {
    var q = (query || '').trim();
    if (!q) return text;
    var out = [], lower = text.toLowerCase(), lq = q.toLowerCase(), at = 0, i;
    while ((i = lower.indexOf(lq, at)) >= 0) {
      if (i > at) out.push(text.slice(at, i));
      out.push(h('mark', { key: i }, text.slice(i, i + q.length)));
      at = i + q.length;
    }
    if (at < text.length) out.push(text.slice(at));
    return out;
  }

  function Suggestions(p) {
    return h('div', { className: 'mr-menu mr-suggest', role: 'listbox', style: p.width ? { width: p.width } : undefined }, p.items.map(function (it, i) {
      if (it.type === 'header') return h('div', { key: i, className: 'hdr' }, it.label);
      return h('div', { key: i, role: 'option', 'aria-selected': String(!!it.highlighted), className: cx('item', it.highlighted && 'hl') },
        it.avatar ? h(Avatar, { name: it.avatar, size: 'md' }) : it.icon ? h(Icon, { name: it.icon }) : null,
        h('span', { className: 'grow' }, it.label),
        it.hint ? h('span', { className: 'hint' }, it.hint) : null);
    }));
  }

  function ListRow(p) {
    return h('div', { className: cx('mr-lrow', p.twoLine && 'two', p.emphasized && 'strong', p.state, p.dimmed && 'dim'), role: 'option', 'aria-selected': p.state ? 'true' : 'false' },
      p.avatar ? h(Avatar, { name: p.avatar, size: p.twoLine ? 'md' : undefined }) : p.icon ? h(Icon, { name: p.icon, size: 'sm', style: { color: p.state === 'focused' ? 'var(--on-accent)' : 'var(--ink-muted)' } }) : null,
      h('span', { className: 'main' }, h('span', { className: 't' }, matched(p.title, p.match)), p.titleTrailing || null, p.subtitle ? h('span', { className: 's' }, p.subtitle) : null),
      p.meta ? h('span', { className: 'meta' }, p.meta) : null,
      p.trailing || null,
      p.actions ? h('span', { className: 'acts' }, p.actions.map(function (a, i) { return h(IconButton, { key: i, icon: a.icon, label: a.label, size: 'sm' }); })) : null);
  }

  function Chip(p) {
    var tag = p.onClick || p.selected !== undefined ? 'button' : 'span';
    return h(tag, { type: tag === 'button' ? 'button' : undefined, style: p.style, className: cx('mr-chip', p.selected && 'selected', p.tone && p.tone !== 'neutral' && p.tone, p.removable && 'removable'), 'aria-pressed': p.selected !== undefined ? String(!!p.selected) : undefined },
      p.dot ? h('span', { className: 'dot', style: { background: p.dot } }) : p.selected && !p.icon ? h(Icon, { name: 'check', size: 'sm' }) : p.icon ? h(Icon, { name: p.icon, size: 'sm' }) : null,
      h('span', { className: 'nm' }, p.children),
      p.removable ? h('span', { className: 'rm', role: 'button', 'aria-label': 'Remove ' + p.children }, h(Icon, { name: 'x' })) : null);
  }

  function MiddleEllipsis(p) {
    var text = String(p.children), tail = Math.min(10, Math.floor(text.length / 2));
    return h('span', { className: 'mr-middle', title: text, style: p.width ? { maxWidth: p.width } : undefined },
      h('span', { className: 'start' }, text.slice(0, text.length - tail)), h('span', { className: 'end' }, text.slice(text.length - tail)));
  }

  function StatusDot(p) {
    return h('span', { className: cx('mr-status', p.tone, p.halo && 'halo') }, h('span', { className: 'dot' }), p.children);
  }

  function ProgressBar(p) {
    return h('div', { className: cx('mr-progress', p.track && 'track'), role: 'progressbar', 'aria-label': p.label, 'aria-valuenow': p.value !== undefined ? Math.round(p.value * 100) : undefined, style: p.width ? { width: p.width } : undefined },
      h('span', { className: cx('bar', p.value === undefined && 'indet'), style: p.value !== undefined ? { width: (p.value * 100) + '%' } : undefined }));
  }

  function Waveform(p) {
    var peaks = p.peaks === undefined ? [] : p.peaks, width = p.width === undefined ? 320 : p.width, height = p.height === undefined ? 24 : p.height;
    if (!Array.isArray(peaks) || peaks.length > 1024 || peaks.some(function (v) { return !Number.isFinite(v) || v < 0 || v > 1; })) throw new TypeError('Waveform requires bounded normalized peaks');
    if (!Number.isFinite(width) || width < 0 || !Number.isFinite(height) || height <= 0) throw new TypeError('Waveform requires valid geometry');
    var progress = p.progress;
    if (progress !== undefined && progress !== null && (!Number.isFinite(progress) || progress < 0 || progress > 1)) throw new TypeError('Waveform requires valid progress');
    var rtl = !!p.rtl, step = peaks.length ? width / peaks.length : 0, gap = Math.min(0.5, step / 3);
    var path = peaks.map(function (v, i) {
      var hgt = Math.max(Math.min(1, height), v * height), x = (rtl ? width - (i + 1) * step : i * step) + gap / 2, y = (height - hgt) / 2, w = step - gap;
      return 'M'+x+' '+y+'h'+w+'v'+hgt+'h'+(-w)+'Z';
    }).join(' ');
    return h('svg', {width: width, height: height, viewBox: '0 0 '+width+' '+height, preserveAspectRatio:'none', 'aria-hidden':'true', style:{pointerEvents:'none',maxWidth:'100%'}},
      h('path', {d:path,fill:'var(--ink-muted)'}),
      progress === undefined || progress === null ? null : h('path', {d:path,fill:'var(--accent)',style:{clipPath:rtl?'inset(0 0 0 '+((1-progress)*100)+'%)':'inset(0 '+((1-progress)*100)+'% 0 0)'}}));
  }

  function Meter(p) {
    var v = p.value, tone = p.dangerAt !== undefined && v >= p.dangerAt ? 'danger' : p.warningAt !== undefined && v >= p.warningAt ? 'warning' : null;
    return h('div', { className: cx('mr-meter', tone), 'aria-hidden': 'true', style: p.width ? { width: p.width } : undefined }, h('div', { className: 'bar', style: { width: (v * 100) + '%' } }));
  }

  var BANNER_ICON = { info: 'info', success: 'circle-check', warning: 'triangle-alert', attention: 'circle-alert', error: 'circle-x' };
  function Banner(p) {
    var tone = p.tone || 'info';
    return h('div', { className: cx('mr-banner', tone !== 'info' && tone), role: tone === 'error' || tone === 'attention' ? 'alert' : 'status' },
      h(Icon, { name: p.icon || BANNER_ICON[tone] }),
      h('div', { className: 'body' }, p.title ? h('b', null, p.title) : null, p.children),
      p.actions ? h('div', { className: 'acts' }, p.actions) : null,
      p.dismissible ? h(IconButton, { icon: 'x', label: 'Dismiss', size: 'sm' }) : null);
  }

  var TOAST_ICON = { success: 'circle-check', warning: 'triangle-alert', error: 'circle-x' };
  function Toast(p) {
    return h('div', { className: cx('mr-toast', p.tone), role: 'status' },
      h('div', { className: 'msg-row' },
        TOAST_ICON[p.tone] ? h(Icon, { name: TOAST_ICON[p.tone] }) : null,
        h('span', { className: 'msg' }, p.children),
        h(IconButton, { icon: 'x', label: 'Close', size: 'sm' })),
      p.action ? h('div', { className: 'act-row' }, h(Button, { variant: 'quiet', size: 'sm' }, p.action)) : null);
  }

  function EmptyState(p) {
    return h('div', { className: 'mr-empty' },
      p.icon ? h(Icon, { name: p.icon }) : null,
      h('h3', { className: p.headline ? 'display' : undefined }, p.title),
      p.children ? h('p', null, p.children) : null,
      p.action ? h('div', { className: 'act' }, p.action) : null);
  }

  function Skeleton(p) { return h('span', { className: 'mr-skel', style: { width: p.width || '100%', height: p.height } }); }

  function Island(p) {
    return h('section', { className: cx('mr-island', p.focused && 'focused'), style: p.style, 'aria-label': p.title },
      (p.title || p.actions) ? h('header', { className: 'mr-ihead' },
        p.title ? h('span', { className: 'title' }, p.title) : null,
        p.subtitle ? h('span', { className: 'sub' }, p.subtitle) : null,
        h('span', { className: 'grow' }),
        p.actions || null) : null,
      h('div', { className: 'mr-ibody', style: p.bodyStyle }, p.children));
  }

  function Disclosure(p) {
    var s = useState(!!p.open); var open = s[0], set = s[1];
    return h('div', { className: 'mr-disc' },
      h('div', { className: 'head', role: 'button', tabIndex: 0, 'aria-expanded': String(open), onClick: function () { set(!open); } },
        h(Icon, { name: open ? 'chevron-down' : 'chevron-right' }), p.title),
      open ? h('div', { className: 'body' }, p.children) : null);
  }

  function Dialog(p) {
    return h('div', { className: 'mr-dialog', role: 'dialog', 'aria-modal': 'true', 'aria-label': p.title },
      h('h2', null, p.title),
      p.description ? h('p', { className: 'desc' }, p.description) : null,
      p.children ? h('div', { className: 'content' }, p.children) : null,
      h('div', { className: 'foot' }, p.aside || null, h('span', { className: 'grow' }), p.actions));
  }

  function Sheet(p) {
    return h('div', { className: 'mr-sheet', role: 'dialog', 'aria-label': p.title },
      h('div', { className: 'handle' }),
      p.title ? h('div', { className: 'head' }, h('h2', null, p.title), p.actions || null) : null,
      h('div', { className: 'content' }, p.children));
  }

  function Panel(p) {
    return h('div', { className: 'mr-panel', role: 'region', 'aria-label': p.title },
      h('div', { className: 'head' }, h('span', { className: 'title' }, p.title), p.actions || null, h(IconButton, { icon: 'x', label: 'Close' })),
      h('div', { className: 'content' }, p.children));
  }

  function SettingsDialog(p) {
    return h('div', { className: 'mr-setdialog', role: 'dialog', 'aria-modal': 'true', 'aria-label': p.title },
      h('div', { className: 'head' }, h('h2', null, p.title), h(IconButton, { icon: 'x', label: 'Close' })),
      h('div', { className: 'body' },
        h('div', { className: 'pages' }, (p.pages || []).map(function (page) {
          return h(NavRow, { key: page.label, name: page.label, icon: page.icon, state: page.label === p.page ? 'selected' : undefined });
        })),
        h('div', { className: 'page' }, h('h3', null, p.page), p.description ? h('p', { className: 'desc' }, p.description) : null, p.children)));
  }

  function LicenseDialog(p) {
    var pkgs = p.packages || [];
    var current = pkgs.filter(function (pkg) { return pkg.name === p.page; })[0];
    return h('div', { className: 'mr-licdialog', role: 'dialog', 'aria-modal': 'true', 'aria-label': p.title || 'Licenses' },
      h('div', { className: 'head' }, h('h2', null, p.title || 'Licenses'), h(IconButton, { icon: 'x', label: 'Close' })),
      h('div', { className: 'body' },
        h('div', { className: 'pkgs' },
          p.app ? h('div', { className: 'app' }, h('div', { className: 'nm' }, p.app), p.version ? h('div', { className: 'ver' }, p.version) : null) : null,
          h('div', { className: 'filter' }, h(TextField, { variant: 'search', placeholder: 'Filter packages' })),
          h('div', { className: 'list' }, pkgs.map(function (pkg) {
            return h(NavRow, { key: pkg.name, name: pkg.name, count: pkg.count, state: pkg.name === p.page ? 'selected' : undefined });
          }))),
        h('div', { className: 'text' },
          h('h3', null, p.page),
          current ? h('p', { className: 'count' }, current.count === 1 ? '1 license' : current.count + ' licenses') : null,
          (p.licenses || []).map(function (text, i) {
            return h('div', { key: i, className: 'lic' }, text.split('\n\n').map(function (para, j) { return h('p', { key: j }, para); }));
          }))));
  }

  function Tooltip(p) {
    return h('span', { className: 'mr-tooltip', role: 'tooltip' }, p.children);
  }

  function SelectableText(p) {
    return h('span', { className: cx('mr-selectable', p.mono && 'mono') }, p.before, h('mark', null, p.selected), p.after);
  }

  function Scaffold(p) {
    return h('div', { className: 'mr-scaffold' },
      h(AppBar, { title: p.title, leading: 'menu', leadingLabel: 'Open navigation menu' }),
      h('div', { className: 'body' }, p.children),
      p.bottomBar ? h('div', { className: 'bottom' }, p.bottomBar) : null);
  }

  function SettingsGroup(p) {
    return h('div', null,
      p.title ? h('div', { className: 'mr-overline', style: { marginBottom: 'var(--space-5)' } }, p.title) : null,
      h('div', { className: cx('mr-settings', p.stacked && 'stacked', p.fit && 'fit') }, p.children));
  }

  function SettingsRow(p) {
    return h('div', { className: 'mr-setrow' },
      h('div', { className: 'lbl' }, p.label),
      h('div', { className: 'ctl' }, p.children, p.help ? h('div', { className: 'help' }, p.help) : null));
  }

  function AppBar(p) {
    return h('div', { className: cx('mr-appbar', p.elevated && 'elevated') },
      p.leading ? h(IconButton, { icon: p.leading, label: p.leadingLabel || 'Back', onGround: true }) : null,
      p.subtitle
        ? h('span', { className: 'titles' }, h('span', { className: 'title', role: 'heading', 'aria-level': 1 }, p.title), h('span', { className: 'subtitle' }, p.subtitle))
        : h('span', { className: 'title', role: 'heading', 'aria-level': 1 }, p.title),
      (p.actions || []).map(function (a, i) { return h(IconButton, { key: i, icon: a.icon, label: a.label, onGround: true }); }));
  }

  function PropertyList(p) {
    return h('dl', { className: cx('mr-props', p.stacked && 'stacked') }, (p.items || []).map(function (it, i) {
      return h('div', { key: i, className: 'prop' }, h('dt', null, it.label), h('dd', { className: it.mono ? 'mono' : undefined }, it.value));
    }));
  }

  function ColumnHeader(p) {
    return h('button', { type: 'button', className: cx('mr-colhead', p.sort && 'sorted', p.end && 'end'), style: p.width ? { width: p.width } : undefined, 'aria-sort': p.sort === 'asc' ? 'ascending' : p.sort === 'desc' ? 'descending' : undefined },
      h('span', { className: 'nm' }, p.children),
      p.sort ? h(Icon, { name: p.sort === 'asc' ? 'arrow-up' : 'arrow-down', style: { width: 12, height: 12 } }) : null);
  }

  function ResizeHandle(p) {
    return h('div', { className: cx('mr-resize', p.state), role: 'separator', tabIndex: 0, 'aria-orientation': 'vertical', 'aria-label': p.label || 'Resize' }, h('span', { className: 'rule' }));
  }

  function Drawer(p) {
    return h('nav', { className: 'mr-drawer', 'aria-label': p.label || 'Navigation menu', style: p.width ? { width: p.width } : undefined }, p.children);
  }

  function Canvas(p) {
    return h('div', { className: 'mr-canvas', style: p.height ? { height: p.height } : undefined }, p.children);
  }

  function Paper(p) {
    return h('div', { className: cx('mr-paper', p.selected && 'on'), role: 'img', 'aria-label': p.label, style: { width: p.width || 96, background: p.color || '#FFFFFF' } }, p.children);
  }

  function ToolDock(p) {
    return h('div', { className: cx('mr-dock', p.vertical && 'vertical'), role: 'toolbar', 'aria-label': p.label || 'Tools', 'aria-orientation': p.vertical ? 'vertical' : 'horizontal' }, p.children);
  }

  function ToolDockDivider() {
    return h('span', { className: 'mr-dock-divider', role: 'separator' });
  }

  function Popover(p) {
    return h('div', { className: 'mr-popover', role: 'dialog', style: p.width ? { width: p.width } : undefined }, p.children);
  }

  function Breadcrumbs(p) {
    var crumbs = p.crumbs || [], fold = p.fold || 0, out = [];
    function crumb(c, i) {
      var tag = c.current ? 'span' : 'button';
      return h(tag, { key: 'c' + i, type: c.current ? undefined : 'button', className: cx('crumb', c.mono && 'mono', c.current && 'cur'), 'aria-current': c.current ? 'location' : undefined },
        c.icon ? h(Icon, { name: c.icon, size: 'sm' }) : null,
        c.code ? h('code', null, c.code) : null,
        h('span', { className: 'lbl' }, c.label));
    }
    function sep(i) { return h(Icon, { key: 's' + i, name: 'chevron-right', size: 'sm', className: 'sep' }); }
    crumbs.forEach(function (c, i) {
      if (i > 0 && i <= fold && i < crumbs.length - 1) {
        if (i === 1) { out.push(sep(i)); out.push(h('button', { key: 'more', type: 'button', className: 'crumb', 'aria-label': crumbs.slice(1, fold + 1).map(function (x) { return x.label; }).join(', ') }, '…')); }
        return;
      }
      if (i > 0) out.push(sep(i));
      out.push(crumb(c, i));
    });
    return h('nav', { className: 'mr-crumbs', 'aria-label': p.label || 'Location', style: p.width ? { width: p.width } : undefined }, out);
  }

  function Steps(p) {
    var steps = p.steps || [], cur = p.current == null ? 0 : p.current, out = [];
    steps.forEach(function (label, i) {
      var state = i < cur ? 'done' : i === cur ? 'cur' : 'next';
      if (i > 0) out.push(h('span', { key: 'c' + i, className: 'conn', 'aria-hidden': 'true' }));
      out.push(h('li', { key: 's' + i, className: cx('step', state), 'aria-current': state === 'cur' ? 'step' : undefined,
        'aria-label': label + ', ' + (state === 'done' ? 'done' : state === 'cur' ? 'current' : 'upcoming') + ', ' + (i + 1) + ' of ' + steps.length },
        h('span', { className: 'mark', 'aria-hidden': 'true' }, state === 'done' ? h(Icon, { name: 'check', stroke: 3 }) : i + 1),
        h('span', { className: 'lbl', 'aria-hidden': 'true' }, label)));
    });
    return h('ol', { className: cx('mr-steps', p.compact && 'compact'), 'aria-label': p.label, style: p.width ? { width: p.width } : undefined }, out);
  }

  function Pagination(p) {
    var pages = p.pages || [1, 2, 3, 4, 5, null, 12], cur = p.page || 3;
    return h('nav', { className: 'mr-pages', 'aria-label': 'Pages' },
      h(IconButton, { icon: 'chevron-left', label: 'Previous page', size: 'sm' }),
      pages.map(function (pg, i) {
        return pg === null ? h('span', { key: i, className: 'gap' }, '…')
          : h('button', { key: i, type: 'button', className: cx('pg', pg === cur && 'cur'), 'aria-current': pg === cur ? 'page' : undefined }, pg);
      }),
      p.jump ? h('span', { className: 'jump' }, 'Page', h(TextField, { value: String(cur), size: 'sm', width: 56 }), 'of ' + pages[pages.length - 1]) : null,
      h(IconButton, { icon: 'chevron-right', label: 'Next page', size: 'sm' }));
  }

  function SelectionBar(p) {
    return h('div', { className: 'mr-selbar', role: 'toolbar', 'aria-label': p.label },
      h('span', { className: 'count' }, p.label),
      h('span', { className: 'acts' }, (p.actions || []).map(function (a, i) { return h(IconButton, { key: i, icon: a.icon, label: a.label, size: 'sm' }); }),
        p.overflow ? h(IconButton, { icon: 'ellipsis', label: 'More actions', size: 'sm' }) : null),
      h(Button, { variant: 'quiet', size: 'sm' }, 'Clear'));
  }

  function DropZone(p) {
    return h('div', { className: cx('mr-drop', p.state), role: p.browse ? 'button' : undefined, tabIndex: p.browse ? 0 : undefined },
      h(Icon, { name: p.icon || 'upload' }), h('b', null, p.label), p.message ? h('span', { className: 'msg' }, p.message) : null);
  }

  function Calendar(p) {
    var first = p.firstWeekday || 1, days = p.days || 31, offset = p.offset === undefined ? 6 : p.offset, sel = p.selected, today = p.today;
    var names = ['S', 'M', 'T', 'W', 'T', 'F', 'S'], cells = [];
    for (var i = 0; i < offset; i++) cells.push(h('span', { key: 'b' + i }));
    for (var d = 1; d <= days; d++) cells.push(h('button', { key: d, type: 'button', className: cx('day', d === sel && 'sel', d === today && 'today', p.before && d < p.before && 'off'), 'aria-pressed': String(d === sel) }, d));
    return h('div', { className: 'mr-cal' },
      h('div', { className: 'head' }, h('b', null, p.month || 'March 2026'), h(IconButton, { icon: 'chevron-left', label: 'Previous month', size: 'sm' }), h(IconButton, { icon: 'chevron-right', label: 'Next month', size: 'sm' })),
      h('div', { className: 'grid' }, names.map(function (_, i) { return h('span', { key: 'w' + i, className: 'wd' }, names[(first + i) % 7]); }), cells));
  }

  function BusyOverlay(p) {
    return h('div', { className: 'mr-busy', role: 'status' }, h('div', { className: cx('pill', p.action && 'with-action') }, h(Spinner), p.children, p.action));
  }

  function Scrollbar(p) {
    return h('div', { className: cx('mr-scroll', p.visibility || 'hover'), tabIndex: 0, style: { height: p.height, width: p.width } }, p.children);
  }

  function StatusBar(p) {
    return h('div', { className: 'mr-statusbar' }, h('div', { className: 'lead' }, p.leading), h('div', { className: 'trail' }, p.trailing));
  }

  var M = { Icon: Icon, Kbd: Kbd, Count: Count, Spinner: Spinner, Button: Button, SplitButton: SplitButton, ButtonConfirmationDemo: ButtonConfirmationDemo, IconButton: IconButton, ToolbarButton: ToolbarButton, TextField: TextField, ShortcutField: ShortcutField, ShortcutFieldDemo: ShortcutFieldDemo, Checkbox: Checkbox, Radio: Radio, RadioGroup: RadioGroup, Switch: Switch, Segmented: Segmented, Slider: Slider, RangeSlider: RangeSlider, Select: Select, Menu: Menu, Suggestions: Suggestions, Tabs: Tabs, TabStrip: TabStrip, NavSection: NavSection, NavRow: NavRow, ListRow: ListRow, AppBar: AppBar, Avatar: Avatar, Chip: Chip, StatusDot: StatusDot, MiddleEllipsis: MiddleEllipsis, ProgressBar: ProgressBar, Meter: Meter, Waveform: Waveform, Banner: Banner, Toast: Toast, EmptyState: EmptyState, Skeleton: Skeleton, Island: Island, Disclosure: Disclosure, Dialog: Dialog, Sheet: Sheet, Panel: Panel, SettingsDialog: SettingsDialog, LicenseDialog: LicenseDialog, Tooltip: Tooltip, SelectableText: SelectableText, Scaffold: Scaffold, SettingsGroup: SettingsGroup, SettingsRow: SettingsRow, PropertyList: PropertyList, ColumnHeader: ColumnHeader, ResizeHandle: ResizeHandle, StatusBar: StatusBar, Scrollbar: Scrollbar, ColorSwatch: ColorSwatch, ColorPicker: ColorPicker, ColorWell: ColorWell, FloatingButton: FloatingButton, Drawer: Drawer, Breadcrumbs: Breadcrumbs, Pagination: Pagination, Steps: Steps, SelectionBar: SelectionBar, DropZone: DropZone, Calendar: Calendar, BusyOverlay: BusyOverlay, Popover: Popover, Canvas: Canvas, Paper: Paper, ToolDock: ToolDock, ToolDockDivider: ToolDockDivider };
  window.Meridian = Object.assign(window.Meridian || {}, M);
})();
