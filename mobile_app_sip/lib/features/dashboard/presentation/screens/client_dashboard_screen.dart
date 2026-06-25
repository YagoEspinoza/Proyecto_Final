import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proyectoappsip/core/config/app_constants.dart';
import 'package:proyectoappsip/core/widgets/sip_logo.dart';
import 'package:proyectoappsip/core/utils/money_formatter.dart';
import 'package:proyectoappsip/core/utils/date_formatter.dart';
import 'package:proyectoappsip/core/utils/validators.dart';
import 'package:proyectoappsip/features/auth/presentation/providers/auth_provider.dart';
import 'package:proyectoappsip/features/cliente_homebanking/providers/accounts_provider.dart';
import 'package:proyectoappsip/features/cliente_homebanking/providers/credits_provider.dart';
import 'package:proyectoappsip/features/cliente_homebanking/providers/solicitudes_provider.dart';
import 'package:proyectoappsip/features/cliente_homebanking/providers/notifications_provider.dart';
import 'package:go_router/go_router.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  int _currentIndex = 0;
  bool _viewingSolicitudForm = false;
  bool _viewingCronograma = false;
  String? _selectedCreditId;
  String? _selectedCreditNumber;

  // New Solicitud Form fields
  final _solicitudFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _termController = TextEditingController();
  String _selectedProductId = '04780e00-eb2a-417c-bf59-56c0703c31f7'; // default seed product
  bool _withInsurance = true;
  String _warranty = 'Sola firma';
  String _purpose = 'Capital de trabajo';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountsProvider.notifier).loadHomebankingData();
      ref.read(creditsProvider.notifier).loadCredits();
      ref.read(solicitudesProvider.notifier).loadSolicitudes();
      ref.read(notificationsProvider.notifier).loadNotifications();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _termController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userData = ref.watch(authProvider).userData;
    final String clientName = userData?['nombre'] ?? 'Cliente';

    final accountsState = ref.watch(accountsProvider);
    final creditsState = ref.watch(creditsProvider);
    final solicitudesState = ref.watch(solicitudesProvider);
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SipLogo(size: 28, inverted: true, showText: false),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getAppBarTitle(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(accountsProvider.notifier).loadHomebankingData();
              ref.read(creditsProvider.notifier).loadCredits();
              ref.read(solicitudesProvider.notifier).loadSolicitudes();
              ref.read(notificationsProvider.notifier).loadNotifications();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: _buildBody(accountsState, creditsState, solicitudesState, notificationsState, clientName),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppConstants.colorPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _viewingSolicitudForm = false;
            _viewingCronograma = false;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            label: 'Créditos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Mi Perfil',
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'BN Móvil';
      case 1:
        return _viewingSolicitudForm 
            ? 'Solicitud de Crédito' 
            : (_viewingCronograma ? 'Cronograma de Pagos' : 'Mis Créditos');
      case 2:
        return 'Notificaciones';
      case 3:
        return 'Mi Perfil';
      default:
        return 'Banco de la Nación';
    }
  }

  Widget _buildBody(
    AccountsState accountsState, 
    CreditsState creditsState, 
    SolicitudesState solicitudesState, 
    NotificationsState notificationsState,
    String name
  ) {
    if (accountsState.isLoading || creditsState.isLoading || solicitudesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentIndex) {
      case 0:
        return _buildAccountsTab(accountsState, name);
      case 1:
        if (_viewingSolicitudForm) {
          return _buildSolicitudFormTab(solicitudesState);
        } else if (_viewingCronograma) {
          return _buildCronogramaTab(creditsState, accountsState);
        } else {
          return _buildCreditsTab(creditsState, solicitudesState);
        }
      case 2:
        return _buildNotificationsTab(notificationsState);
      case 3:
        return _buildProfileTab(name);
      default:
        return const Center(child: Text('Banco de la Nación'));
    }
  }

  // TAB 1: CUENTAS
  Widget _buildAccountsTab(AccountsState state, String name) {
    final account = state.accounts.isNotEmpty ? state.accounts.first : null;
    final double balance = account != null ? double.tryParse(account['saldo_disponible'].toString()) ?? 0.0 : 0.0;
    final String ccy = account != null ? account['moneda'] : 'PEN';
    final String accountNum = account != null ? account['numero_cuenta'] : '---';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Hola, $name!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.colorTextPrimary),
          ),
          const SizedBox(height: 16),
          // Gradient balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppConstants.colorPrimary, Color(0xFFA30D25)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.colorPrimary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Disponible', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  MoneyFormatter.format(balance, currency: ccy),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cuenta: $accountNum', style: const TextStyle(color: Colors.white70)),
                    const Icon(Icons.wallet, color: Colors.white70),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Tarjetas Section
          const Text('Mis Tarjetas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (state.cards.isEmpty)
            const Text('No registra tarjetas activas.')
          else
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.cards.length,
                itemBuilder: (context, index) {
                  final card = state.cards[index];
                  return Card(
                    color: card['tipo_tarjeta'] == 'DEBITO' ? Colors.teal : Colors.blueGrey,
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(card['tipo_tarjeta'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(card['numero_enmascarado'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                          Text(card['marca'] ?? 'VISA', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          // Latest movements Section
          const Text('Últimos Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (state.movements.isEmpty)
            const Text('No registra movimientos en esta cuenta.')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.movements.length > 5 ? 5 : state.movements.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final mov = state.movements[index];
                final double amt = double.tryParse(mov['monto'].toString()) ?? 0.0;
                final isNegative = amt < 0;

                return ListTile(
                  leading: Icon(
                    isNegative ? Icons.arrow_outward : Icons.arrow_downward,
                    color: isNegative ? Colors.red : Colors.green,
                  ),
                  title: Text(mov['descripcion'] ?? 'Movimiento'),
                  subtitle: Text(DateFormatter.formatDateString(mov['fecha_movimiento'])),
                  trailing: Text(
                    MoneyFormatter.format(amt, currency: mov['moneda']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isNegative ? Colors.red : Colors.green,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // TAB 2: CREDITOS
  Widget _buildCreditsTab(CreditsState state, SolicitudesState solicitudesState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mi Crédito Activo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _viewingSolicitudForm = true;
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Nueva Solicitud'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.credits.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                    const SizedBox(height: 12),
                    const Text('No registra ningún crédito activo en este momento.', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _viewingSolicitudForm = true;
                        });
                      },
                      child: const Text('Solicitar un Crédito'),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.credits.map((credito) {
              final double disp = double.tryParse(credito['monto_desembolsado'].toString()) ?? 0.0;
              final double cap = double.tryParse(credito['saldo_capital'].toString()) ?? 0.0;
              final String numCred = credito['numero_credito'];
              final String prod = credito['producto'];
              final int plazo = credito['plazo_meses'];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(prod, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.colorSuccess.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('ACTIVO', style: TextStyle(color: AppConstants.colorSuccess, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text('Nº Crédito: $numCred'),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Desembolsado', style: TextStyle(color: Colors.grey)),
                              Text(MoneyFormatter.format(disp)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Saldo Capital', style: TextStyle(color: Colors.grey)),
                              Text(MoneyFormatter.format(cap)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Plazo', style: TextStyle(color: Colors.grey)),
                              Text('$plazo meses'),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(creditsProvider.notifier).loadCronograma(credito['id_credito']);
                          setState(() {
                            _selectedCreditId = credito['id_credito'];
                            _selectedCreditNumber = numCred;
                            _viewingCronograma = true;
                          });
                        },
                        child: const Text('VER CRONOGRAMA / PAGAR'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          const Text('Mis Solicitudes Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (solicitudesState.solicitudes.isEmpty)
            const Text('No registra solicitudes recientes.')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: solicitudesState.solicitudes.length,
              itemBuilder: (context, index) {
                final sol = solicitudesState.solicitudes[index];
                final double req = double.tryParse(sol['monto_solicitado'].toString()) ?? 0.0;
                final String stateName = sol['estado'];

                return Card(
                  child: ListTile(
                    title: Text('Expediente: ${sol['numero_expediente']}'),
                    subtitle: Text('Monto: ${MoneyFormatter.format(req)} - Plazo: ${sol['plazo_meses']} meses'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStateColor(stateName).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        stateName,
                        style: TextStyle(
                          color: _getStateColor(stateName),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Color _getStateColor(String? state) {
    switch (state?.toUpperCase()) {
      case 'BORRADOR':
        return Colors.grey;
      case 'ENVIADO':
      case 'RECIBIDO_COMITE':
      case 'EN_EVALUACION':
        return Colors.blue;
      case 'APROBADO':
        return Colors.green;
      case 'CONDICIONADO':
        return Colors.orange;
      case 'RECHAZADO':
        return Colors.red;
      case 'DESEMBOLSADO':
        return Colors.teal;
      default:
        return Colors.black;
    }
  }

  // CRONOGRAMA TAB (SUB-VIEW OF CREDITS)
  Widget _buildCronogramaTab(CreditsState state, AccountsState accountsState) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _viewingCronograma = false;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cronograma: $_selectedCreditNumber',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.selectedCronograma.isEmpty
              ? const Center(child: Text('No hay cuotas registradas.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.selectedCronograma.length,
                  itemBuilder: (context, index) {
                    final cuota = state.selectedCronograma[index];
                    final double cuotaAmt = double.tryParse(cuota['monto_cuota'].toString()) ?? 0.0;
                    final double paidAmt = double.tryParse(cuota['monto_pagado'].toString()) ?? 0.0;
                    final int numCuota = cuota['numero_cuota'];
                    final String cState = cuota['estado'];
                    final String dueDate = DateFormatter.formatDateString(cuota['fecha_pago']);

                    final isPaid = cState == 'PAGADA';

                    return Card(
                      child: ListTile(
                        title: Text('Cuota $numCuota - $cState'),
                        subtitle: Text('Vence: $dueDate\nMonto: ${MoneyFormatter.format(cuotaAmt)} (Pagado: ${MoneyFormatter.format(paidAmt)})'),
                        trailing: isPaid
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : ElevatedButton(
                                onPressed: () => _showPaymentDialog(cuota, accountsState),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('PAGAR'),
                              ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  void _showPaymentDialog(Map<String, dynamic> cuota, AccountsState accountsState) {
    if (accountsState.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tiene cuentas activas para realizar el pago.')),
      );
      return;
    }

    final account = accountsState.accounts.first;
    final String accountId = account['id_cuenta'];
    final String accountNum = account['numero_cuenta'];
    final double balance = double.tryParse(account['saldo_disponible'].toString()) ?? 0.0;
    final double cuotaAmt = double.tryParse(cuota['monto_cuota'].toString()) ?? 0.0;
    final double paidAmt = double.tryParse(cuota['monto_pagado'].toString()) ?? 0.0;
    final double pendingAmt = cuotaAmt - paidAmt;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pagar Cuota ${cuota['numero_cuota']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuenta de Débito: $accountNum'),
            const SizedBox(height: 8),
            Text('Saldo Disponible: ${MoneyFormatter.format(balance)}'),
            const SizedBox(height: 16),
            Text('Monto a Pagar: ${MoneyFormatter.format(pendingAmt)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (balance < pendingAmt) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saldo insuficiente en la cuenta de ahorros.')),
                );
                return;
              }
              final success = await ref.read(creditsProvider.notifier).payInstallment(
                accountId: accountId,
                creditId: _selectedCreditId!,
                cuotaId: cuota['id_cuota'],
                amount: pendingAmt,
              );
              if (success) {
                // Reload homebanking balances
                ref.read(accountsProvider.notifier).loadHomebankingData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pago procesado correctamente.'), backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error al procesar el pago.')),
                );
              }
            },
            child: const Text('PROCESAR PAGO'),
          ),
        ],
      ),
    );
  }

  // SOLICITUD FORM TAB (SUB-VIEW OF CREDITS)
  Widget _buildSolicitudFormTab(SolicitudesState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _solicitudFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _viewingSolicitudForm = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('Nuevo Crédito Pyme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto Solicitado (S/)',
                hintText: 'Ej. 1000',
              ),
              validator: (val) => Validators.validateAmount(val, 500, 50000),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _termController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Plazo (Meses)',
                hintText: 'Ej. 12',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'El plazo es obligatorio';
                final term = int.tryParse(val);
                if (term == null || term < 3 || term > 36) {
                  return 'El plazo debe estar entre 3 y 36 meses';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _purpose,
              decoration: const InputDecoration(labelText: 'Destino del Crédito'),
              items: const [
                DropdownMenuItem(value: 'Capital de trabajo', child: Text('Capital de trabajo')),
                DropdownMenuItem(value: 'Activo fijo', child: Text('Activo fijo')),
                DropdownMenuItem(value: 'Consumo personal', child: Text('Consumo personal')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _purpose = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _warranty,
              decoration: const InputDecoration(labelText: 'Garantía Ofrecida'),
              items: const [
                DropdownMenuItem(value: 'Sola firma', child: Text('Sola firma')),
                DropdownMenuItem(value: 'Aval personal', child: Text('Aval personal')),
                DropdownMenuItem(value: 'Hipoteca', child: Text('Hipoteca')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _warranty = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Con Seguro de Desgravamen'),
              subtitle: const Text('Protege tu deuda ante cualquier imprevisto'),
              value: _withInsurance,
              onChanged: (val) {
                setState(() {
                  _withInsurance = val;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_solicitudFormKey.currentState?.validate() ?? false) {
                  final amt = double.parse(_amountController.text.trim());
                  final term = int.parse(_termController.text.trim());

                  final success = await ref.read(solicitudesProvider.notifier).createSolicitud(
                    productId: _selectedProductId,
                    amount: amt,
                    termMonths: term,
                    withInsurance: _withInsurance,
                    warranty: _warranty,
                    purpose: _purpose,
                  );

                  if (success) {
                    setState(() {
                      _viewingSolicitudForm = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitud registrada correctamente.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al registrar la solicitud.')),
                    );
                  }
                }
              },
              child: const Text('ENVIAR SOLICITUD'),
            )
          ],
        ),
      ),
    );
  }

  // TAB 3: NOTIFICACIONES
  Widget _buildNotificationsTab(NotificationsState state) {
    if (state.list.isEmpty) {
      return const Center(child: Text('No tiene notificaciones.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.list.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final notif = state.list[index];
        return ListTile(
          leading: const Icon(Icons.notifications, color: AppConstants.colorAccent),
          title: Text(notif['titulo'] ?? 'Alerta'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notif['mensaje'] ?? ''),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatDateString(notif['created_at']),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 4: PROFILE
  Widget _buildProfileTab(String name) {
    final userData = ref.read(authProvider).userData;
    final dni = userData?['documento'] ?? '---';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppConstants.colorPrimary,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text('Nombre completo: $name', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          Text('Documento DNI: $dni', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          const Text('Tipo de Cuenta: Ahorros Pyme', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          const Text('Canal de Banca: App Móvil Banco de la Nación', style: TextStyle(fontSize: 16)),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.colorError),
            child: const Text('CERRAR SESIÓN'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
