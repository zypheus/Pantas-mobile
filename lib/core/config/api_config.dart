class ApiConfig {
  static const String localBrowser = 'http://127.0.0.1:8000/api/mobile';
  static const String androidEmulator = 'http://127.0.0.1:8000/api/mobile';
  static const String ngrok =
      'https://cahoots-richly-output.ngrok-free.dev/api/mobile';
  static const String production = 'https://your-domain.com/api/mobile';

  static const String baseUrl =
      ngrok; // replace androidEmulator if using androind emulator
}
//server configurations