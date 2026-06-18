// Web-only: opens a URL in a new browser window.
// This file is conditionally imported only on web.

import 'dart:js_interop';

@JS('window.open')
external JSAny? _windowOpen(JSString url, JSString target, JSString features);

/// Opens [url] in a centered popup window.
void openUrlInNewWindow(String url) {
  _windowOpen(
    url.toJS,
    '_blank'.toJS,
    'width=600,height=700,scrollbars=yes'.toJS,
  );
}
