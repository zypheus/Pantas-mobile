class ApiConfig {
  // Use this when running Flutter in Chrome/Windows desktop.
  static const String localBrowser = 'http://127.0.0.1:8000/api/mobile';

  // Use this when running on the Android emulator.
  static const String androidEmulator = 'http://127.0.0.1:8000/api/mobile';

  // Use this when testing against an ngrok tunnel.
  static const String ngrok = 'http://127.0.0.1:8000/api/mobile';

  // Replace this with the deployed API URL for release builds.
  static const String production = 'https://your-domain.com/api/mobile';

  static const String baseUrl = ngrok;
}
