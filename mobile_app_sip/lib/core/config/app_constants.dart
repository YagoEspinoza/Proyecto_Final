import 'package:flutter/material.dart';

class AppConstants {
  // App Branding Colors — Banco de la Nación del Perú
  static const Color colorPrimary = Color(0xFFC8102E); // Rojo corporativo
  static const Color colorAccent = Color(0xFFA30D25); // Rojo oscuro
  static const Color colorWhite = Color(0xFFFFFFFF);
  static const Color colorBackground = Color(0xFFF5F5F5);
  static const Color colorTextPrimary = Color(0xFF1A1A1A);
  static const Color colorError = Color(0xFFC8102E);
  static const Color colorSuccess = Color(0xFF2E7D32);
  static const Color colorWarning = Color(0xFFF9A825);

  // User Roles
  static const String roleCliente = 'CLIENTE';
  static const String roleAsesor = 'ASESOR';
  static const String roleSupervisor = 'SUPERVISOR';
  static const String roleAdmin = 'ADMIN';

  // Storage Keys
  static const String keyJwtToken = 'jwt_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserData = 'user_data';
  static const String keyLoginAttempts = 'login_attempts';
  static const String keyBlockedUntil = 'blocked_until';
}
