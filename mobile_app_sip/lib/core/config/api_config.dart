import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // URL de tu backend ya desplegado en Render
  static const String prodBaseUrl = 'https://banco-backend-56el.onrender.com';

  static const String devBaseUrl = 'http://127.0.0.1:8003';
  static const String emulatorBaseUrl = 'http://10.0.2.2:8003';

  static String get baseUrl {
    if (kIsWeb) return prodBaseUrl;
    if (Platform.isAndroid) return emulatorBaseUrl;
    return devBaseUrl;
  }
}