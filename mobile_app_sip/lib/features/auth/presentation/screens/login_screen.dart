import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../../../../core/widgets/sip_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _clientFormKey = GlobalKey<FormState>();
  final _staffFormKey = GlobalKey<FormState>();

  final _dniController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Clear password controller on tab change
    _tabController.addListener(() {
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dniController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final isClientTab = _tabController.index == 0;
    final formKey = isClientTab ? _clientFormKey : _staffFormKey;

    if (formKey.currentState?.validate() ?? false) {
      if (isClientTab) {
        ref.read(authProvider.notifier).login(
          documento: _dniController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        ref.read(authProvider.notifier).login(
          codigoEmpleado: _codeController.text.trim(),
          password: _passwordController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        final role = next.userData?['rol'] as String?;
        switch (role) {
          case 'CLIENTE':
            context.go('/cliente/dashboard');
            break;
          case 'ASESOR':
            context.go('/asesor/dashboard');
            break;
          case 'SUPERVISOR':
            context.go('/supervisor/dashboard');
            break;
          case 'ADMIN':
            context.go('/admin/dashboard');
            break;
        }
      } else if (next.status == AuthStatus.error || next.status == AuthStatus.locked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Error al iniciar sesión'),
            backgroundColor: AppConstants.colorError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppConstants.colorBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top branding banner
            Container(
              width: double.infinity,
              height: 240,
              decoration: const BoxDecoration(
                color: AppConstants.colorPrimary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SipLogo(size: 70, inverted: true, showText: false),
                  const SizedBox(height: 12),
                  const Text(
                    'Banco de la Nación',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'El banco de todos los peruanos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Login panel card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tab Bar for roles selection
                      TabBar(
                        controller: _tabController,
                        labelColor: AppConstants.colorPrimary,
                        unselectedLabelColor: AppConstants.colorTextPrimary.withOpacity(0.6),
                        indicatorColor: AppConstants.colorAccent,
                        tabs: const [
                          Tab(text: 'CLIENTE', icon: Icon(Icons.person)),
                          Tab(text: 'COLABORADOR', icon: Icon(Icons.badge)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Form contents
                      SizedBox(
                        height: 100,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Client tab input
                            Form(
                              key: _clientFormKey,
                              child: TextFormField(
                                controller: _dniController,
                                keyboardType: TextInputType.number,
                                maxLength: 8,
                                decoration: const InputDecoration(
                                  labelText: 'Número DNI',
                                  prefixIcon: Icon(Icons.credit_card),
                                  counterText: '',
                                ),
                                validator: Validators.validateDni,
                                enabled: !isLoading,
                              ),
                            ),
                            // Employee tab input
                            Form(
                              key: _staffFormKey,
                              child: TextFormField(
                                controller: _codeController,
                                decoration: const InputDecoration(
                                  labelText: 'Código de Empleado',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: Validators.validateEmployeeCode,
                                enabled: !isLoading,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Password input field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Clave de Acceso',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: Validators.validatePassword,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 24),
                      // Submit button
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _handleLogin,
                              child: const Text('INGRESAR'),
                            ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
