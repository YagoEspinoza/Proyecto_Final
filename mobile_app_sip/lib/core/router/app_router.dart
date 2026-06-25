import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/secure_storage_service.dart';

// Import screens (which we will create soon)
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/client_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/asesor_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/supervisor_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final token = await SecureStorageService.getToken();
      final role = await SecureStorageService.getRole();
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/';

      if (token == null) {
        if (!isGoingToLogin && !isGoingToSplash) {
          return '/login';
        }
        return null;
      }

      // Logged in redirection based on role
      if (isGoingToLogin || isGoingToSplash) {
        switch (role) {
          case 'CLIENTE':
            return '/cliente/dashboard';
          case 'ASESOR':
            return '/asesor/dashboard';
          case 'SUPERVISOR':
            return '/supervisor/dashboard';
          case 'ADMIN':
            return '/admin/dashboard';
          default:
            return '/login';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/cliente/dashboard',
        builder: (context, state) => const ClientDashboardScreen(),
      ),
      GoRoute(
        path: '/asesor/dashboard',
        builder: (context, state) => const AsesorDashboardScreen(),
      ),
      GoRoute(
        path: '/supervisor/dashboard',
        builder: (context, state) => const SupervisorDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}
