import 'dart:io';

class ApiConfig {
  static const String devBaseUrl = 'http://127.0.0.1:8003';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8003';

  static String get baseUrl {
    if (Platform.isAndroid) return emulatorBaseUrl;
    return devBaseUrl;
  }
}
