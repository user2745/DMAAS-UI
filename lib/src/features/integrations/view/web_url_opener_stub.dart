// Stub for non-web platforms. Never called at runtime (guarded by kIsWeb).

void openUrlInNewWindow(String url) {
  throw UnsupportedError('openUrlInNewWindow is only available on web');
}
