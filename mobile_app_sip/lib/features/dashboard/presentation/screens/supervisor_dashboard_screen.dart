import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/widgets/sip_logo.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SupervisorDashboardScreen extends ConsumerStatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  ConsumerState<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends ConsumerState<SupervisorDashboardScreen> {
  List<dynamic> _solicitudes = [];
  bool _isLoading = false;

  // Selected details
  Map<String, dynamic>? _selectedSolicitud;
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCommitteeRequests();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadCommitteeRequests() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final res = await DioClient().get('/comite/solicitudes');
      setState(() {
        _solicitudes = res.data as List<dynamic>;
      });
    } catch (_) {}
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _actionRecibir(String id) async {
    try {
      await DioClient().post('/comite/solicitudes/$id/recibir');
      _loadCommitteeRequests();
      setState(() {
        _selectedSolicitud = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud recibida en el Comité.'), backgroundColor: Colors.green),
      );
    } catch (_) {}
  }

  Future<void> _actionEvaluar(String id) async {
    try {
      await DioClient().post('/comite/solicitudes/$id/evaluar');
      _loadCommitteeRequests();
      setState(() {
        _selectedSolicitud = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud puesta en Evaluación.'), backgroundColor: Colors.green),
      );
    } catch (_) {}
  }

  Future<void> _actionAprobar(String id) async {
    final double? approved = double.tryParse(_amountController.text.trim());
    try {
      await DioClient().post('/comite/solicitudes/$id/aprobar', data: {
        'monto_aprobado': approved
      });
      _amountController.clear();
      _loadCommitteeRequests();
      setState(() {
        _selectedSolicitud = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud APROBADA correctamente.'), backgroundColor: Colors.green),
      );
    } catch (_) {}
  }

  Future<void> _actionCondicionar(String id) async {
    final condition = _reasonController.text.trim();
    if (condition.isEmpty) return;
    try {
      await DioClient().post('/comite/solicitudes/$id/condicionar', data: {
        'condicion_adicional': condition
      });
      _reasonController.clear();
      _loadCommitteeRequests();
      setState(() {
        _selectedSolicitud = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud CONDICIONADA correctamente.'), backgroundColor: Colors.green),
      );
    } catch (_) {}
  }

  Future<void> _actionRechazar(String id) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;
    try {
      await DioClient().post('/comite/solicitudes/$id/rechazar', data: {
        'motivo_rechazo': reason
      });
      _reasonController.clear();
      _loadCommitteeRequests();
      setState(() {
        _selectedSolicitud = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud RECHAZADA correctamente.'), backgroundColor: Colors.red),
      );
    } catch (_) {}
  }

  Future<void> _actionDesembolsar(String id) async {
    try {
      await DioClient().post('/comite/solicitudes/$id/desembolsar');
      _loadCommitteeRequests();
      setState(() {
        _selectedSolicitud = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crédito DESEMBOLSADO correctamente en la cuenta del cliente.'), backgroundColor: Colors.teal),
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
                'Bandeja del Comité',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCommitteeRequests,
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
          : _selectedSolicitud != null 
              ? _buildSolicitudDetail()
              : _buildSolicitudList(),
    );
  }

  // Solicitudes list view
  Widget _buildSolicitudList() {
    if (_solicitudes.isEmpty) {
      return const Center(child: Text('No hay expedientes pendientes en comité.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _solicitudes.length,
      itemBuilder: (context, index) {
        final sol = _solicitudes[index];
        final numExp = sol['numero_expediente'];
        final double req = double.tryParse(sol['monto_solicitado'].toString()) ?? 0.0;
        final double? apr = sol['monto_aprobado'] != null ? double.tryParse(sol['monto_aprobado'].toString()) : null;
        final String state = sol['estado'];

        return Card(
          child: ListTile(
            title: Text('Expediente: $numExp'),
            subtitle: Text('Solicitado: ${MoneyFormatter.format(req)}${apr != null ? "\nAprobado: ${MoneyFormatter.format(apr)}" : ""}\nPlazo: ${sol['plazo_meses']} meses'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStateColor(state).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state,
                style: TextStyle(
                  color: _getStateColor(state),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedSolicitud = sol;
              });
            },
          ),
        );
      },
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'ENVIADO':
        return Colors.blue;
      case 'RECIBIDO_COMITE':
        return Colors.indigo;
      case 'EN_EVALUACION':
        return Colors.orange;
      case 'APROBADO':
        return Colors.green;
      case 'CONDICIONADO':
        return Colors.deepOrange;
      case 'RECHAZADO':
        return Colors.red;
      case 'DESEMBOLSADO':
        return Colors.teal;
      default:
        return Colors.black;
    }
  }

  // Solicitud details and action buttons
  Widget _buildSolicitudDetail() {
    final sol = _selectedSolicitud!;
    final id = sol['id_solicitud'];
    final state = sol['estado'];
    final numExp = sol['numero_expediente'];
    final double req = double.tryParse(sol['monto_solicitado'].toString()) ?? 0.0;
    final double? apr = sol['monto_aprobado'] != null ? double.tryParse(sol['monto_aprobado'].toString()) : null;
    final String dest = sol['destino_credito'] ?? 'No especificado';
    final String? preeval = sol['resultado_preevaluacion'];
    final String? buro = sol['resultado_buro'];
    final String? cond = sol['condicion_adicional'];
    final String? rech = sol['motivo_rechazo'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedSolicitud = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Expediente: $numExp', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DATOS DE LA SOLICITUD', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Monto Solicitado: ${MoneyFormatter.format(req)}'),
                  if (apr != null) ...[
                    const SizedBox(height: 8),
                    Text('Monto Aprobado: ${MoneyFormatter.format(apr)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                  const SizedBox(height: 8),
                  Text('Plazo: ${sol['plazo_meses']} meses'),
                  const SizedBox(height: 8),
                  Text('Destino: $dest'),
                  const SizedBox(height: 8),
                  Text('Tasa Referencial: ${sol['tea_referencial']}% TEA'),
                  const SizedBox(height: 8),
                  Text('Seguro Desgravamen: ${sol['con_seguro_desgravamen'] ? "SÍ" : "NO"}'),
                  const SizedBox(height: 8),
                  Text('Estado Actual: $state'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pre-eval & Buro outcomes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EVALUACIÓN AUTOMÁTICA', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Resultado Preevaluación: ${preeval ?? "Pendiente"}'),
                  const SizedBox(height: 8),
                  Text('Calificación Buró: ${buro ?? "Pendiente"}'),
                  if (cond != null) ...[
                    const SizedBox(height: 8),
                    Text('Condición: $cond', style: const TextStyle(color: Colors.orange)),
                  ],
                  if (rech != null) ...[
                    const SizedBox(height: 8),
                    Text('Motivo Rechazo: $rech', style: const TextStyle(color: Colors.red)),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Actions layout based on status
          const Text('ACCIONES DISPONIBLES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (state == 'ENVIADO') ...[
            ElevatedButton(
              onPressed: () => _actionRecibir(id),
              child: const Text('RECIBIR EN COMITÉ'),
            ),
          ] else if (state == 'RECIBIDO_COMITE') ...[
            ElevatedButton(
              onPressed: () => _actionEvaluar(id),
              child: const Text('EVALUAR EXPEDIENTE'),
            ),
          ] else if (state == 'EN_EVALUACION') ...[
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto Aprobado (Opcional, vacío toma solicitado)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _actionAprobar(id),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('APROBAR'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Comentarios / Motivo / Condición',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _actionCondicionar(id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('CONDICIONAR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _actionRechazar(id),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('RECHAZAR'),
                  ),
                ),
              ],
            ),
          ] else if (state == 'APROBADO' || state == 'CONDICIONADO') ...[
            ElevatedButton(
              onPressed: () => _actionDesembolsar(id),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('DESEMBOLSAR CRÉDITO'),
            ),
          ] else ...[
            const Text('No hay acciones disponibles para este estado.', style: TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
