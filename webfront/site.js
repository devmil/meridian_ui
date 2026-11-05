// The live preview: Widgetbook in preview mode, loaded on request.
(() => {
  const frame = document.getElementById('live-frame');
  const start = document.getElementById('live-start');
  const link = document.getElementById('live-link');
  if (!frame || !start || !link) return;

  const state = {path: 'actions/button/ranks', brand: 'GitLama', theme: 'light'};
  let view = null;

  // Widgetbook reads its settings from the fragment, as `group={field:value}`.
  const route = (preview) => {
    const query = [
      `path=${state.path}`,
      `brand={name:${state.brand}}`,
      `theme={name:${state.theme}}`,
    ];
    if (preview) query.push('preview=true');
    return `widgetbook/#/?${query.join('&')}`;
  };

  const show = () => {
    link.href = route(false);
    if (!view) return;
    // A new fragment alone does not restart the app, so replace the frame.
    const next = view.cloneNode();
    next.src = route(true);
    view.replaceWith(next);
    view = next;
  };

  start.hidden = false;
  start.addEventListener('click', () => {
    view = document.createElement('iframe');
    view.title = 'Live Meridian component preview';
    view.src = route(true);
    frame.replaceChildren(view);
    frame.append(link);
    link.className = 'live-open';
  });

  for (const button of document.querySelectorAll('.live-group button')) {
    button.addEventListener('click', () => {
      for (const other of button.parentElement.querySelectorAll('button')) {
        other.setAttribute('aria-pressed', String(other === button));
      }
      const {path, brand, theme} = button.dataset;
      if (path) state.path = path;
      if (brand) state.brand = brand;
      if (theme) state.theme = theme;
      show();
    });
  }
})();
