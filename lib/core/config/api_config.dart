class ApiConfig {
  static const String localBrowser = 'http://10.0.2.2:8000/api/mobile';
  static const String androidEmulator = 'http://10.0.2.2:8000/api/mobile';
  static const String ngrok =
      'https://cahoots-richly-output.ngrok-free.dev/api/mobile';
  static const String production = 'https://your-domain.com/api/mobile';

  static const String baseUrl =
      ngrok; // replace androidEmulator if using androind emulator
}
//server configurations