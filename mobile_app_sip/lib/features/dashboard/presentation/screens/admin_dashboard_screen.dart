import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/widgets/sip_logo.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Data lists
  List<dynamic> _users = [];
  List<dynamic> _products = [];
  List<dynamic> _syncLogs = [];

  // Form parameters
  final _userFormKey = GlobalKey<FormState>();
  final _documentController = TextEditingController();
  final _empCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'CLIENTE';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllAdminData();
    _tabController.addListener(() {
      _loadAllAdminData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _documentController.dispose();
    _empCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_tabController.index == 0) {
        final res = await DioClient().get('/admin/usuarios');
        setState(() {
          _users = res.data as List<dynamic>;
        });
      } else if (_tabController.index == 1) {
        final res = await DioClient().get('/admin/productos-creditos');
        setState(() {
          _products = res.data as List<dynamic>;
        });
      } else {
        final res = await DioClient().get('/sync/log');
        setState(() {
          _syncLogs = res.data as List<dynamic>;
        });
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createNewUser() async {
    if (_userFormKey.currentState?.validate() ?? false) {
      final payload = {
        'documento': _documentController.text.trim(),
        'codigo_empleado': _empCodeController.text.trim().isEmpty ? null : _empCodeController.text.trim(),
        'correo': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'password': _passwordController.text,
        'rol': _selectedRole,
        'estado': 'ACTIVO',
      };

      try {
        await DioClient().post('/admin/usuarios', data: payload);
        _documentController.clear();
        _empCodeController.clear();
        _emailController.clear();
        _passwordController.clear();
        
        Navigator.pop(context);
        _loadAllAdminData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado correctamente.'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear usuario. Verifique los datos.')),
        );
      }
    }
  }

  Future<void> _deleteUser(String id) async {
    try {
      await DioClient().delete('/admin/usuarios/$id');
      _loadAllAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado.'), backgroundColor: Colors.red),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            SipLogo(size: 28, inverted: true, showText: false),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Administrador BN',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppConstants.colorAccent,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Productos'),
            Tab(icon: Icon(Icons.sync_alt), text: 'Sync Logs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildProductsTab(),
                _buildSyncLogsTab(),
              ],
            ),
    );
  }

  // TAB 1: USER CRUD
  Widget _buildUsersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _showCreateUserDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('CREAR NUEVO USUARIO'),
          ),
        ),
        Expanded(
          child: _users.isEmpty
              ? const Center(child: Text('No hay usuarios registrados.'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final u = _users[index];
                    final String doc = u['documento'];
                    final String role = u['rol'];
                    final String state = u['estado'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Doc: $doc - $role'),
                        subtitle: Text('Estado: $state\nCódigo Empleado: ${u['codigo_empleado'] ?? "-"}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteUser(u['id_usuario']),
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Usuario'),
        content: SingleChildScrollView(
          child: Form(
            key: _userFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _documentController,
                  decoration: const InputDecoration(labelText: 'Documento (DNI/RUC)'),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _empCodeController,
                  decoration: const InputDecoration(labelText: 'Código Empleado (Opcional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo Electrónico (Opcional)'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'CLIENTE', child: Text('Cliente')),
                    DropdownMenuItem(value: 'ASESOR', child: Text('Asesor')),
                    DropdownMenuItem(value: 'SUPERVISOR', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRole = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: _createNewUser,
            child: const Text('CREAR'),
          )
        ],
      ),
    );
  }

  // TAB 2: CREDIT PRODUCTS
  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return const Center(child: Text('No hay productos de crédito.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        final double minAmt = double.tryParse(p['monto_minimo'].toString()) ?? 0.0;
        final double maxAmt = double.tryParse(p['monto_maximo'].toString()) ?? 0.0;
        final double teaCon = double.tryParse(p['tea_con_seguro'].toString()) ?? 0.0;
        final String moneda = p['moneda'] ?? 'PEN';

        return Card(
          child: ListTile(
            title: Text(p['nombre']),
            subtitle: Text('Código: ${p['codigo']} | Tipo: ${p['tipo']}\nLímites: $moneda ${minAmt.toStringAsFixed(0)} - ${maxAmt.toStringAsFixed(0)}\nTEA Con Seguro: ${teaCon.toStringAsFixed(1)}%'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: p['estado'] == 'ACTIVO' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p['estado'],
                style: TextStyle(
                  color: p['estado'] == 'ACTIVO' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // TAB 3: SYNC LOGS
  Widget _buildSyncLogsTab() {
    if (_syncLogs.isEmpty) {
      return const Center(child: Text('No hay logs de sincronización registrados.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _syncLogs.length,
      itemBuilder: (context, index) {
        final log = _syncLogs[index];
        final String action = log['accion'];
        final String result = log['resultado'];
        final String detail = log['detalle'] ?? '';
        final String dateStr = DateFormatter.formatDateTime(DateTime.tryParse(log['created_at']));

        return Card(
          child: ListTile(
            leading: Icon(
              result == 'EXITOSO' ? Icons.check_circle : Icons.error,
              color: result == 'EXITOSO' ? Colors.green : Colors.red,
            ),
            title: Text('$action - $result'),
            subtitle: Text('Detalle: $detail\nFecha: $dateStr'),
          ),
        );
      },
    );
  }
}
