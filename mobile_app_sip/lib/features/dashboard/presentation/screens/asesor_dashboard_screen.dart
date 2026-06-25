import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:proyectoappsip/core/config/app_constants.dart';
import 'package:proyectoappsip/core/widgets/sip_logo.dart';
import 'package:proyectoappsip/core/network/dio_client.dart';
import 'package:proyectoappsip/core/utils/money_formatter.dart';
import 'package:proyectoappsip/core/utils/date_formatter.dart';
import 'package:proyectoappsip/core/utils/validators.dart';
import 'package:proyectoappsip/features/auth/presentation/providers/auth_provider.dart';
import 'package:proyectoappsip/features/fuerza_ventas/providers/asesor_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signature/signature.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

class AsesorDashboardScreen extends ConsumerStatefulWidget {
  const AsesorDashboardScreen({super.key});

  @override
  ConsumerState<AsesorDashboardScreen> createState() => _AsesorDashboardScreenState();
}

class _AsesorDashboardScreenState extends ConsumerState<AsesorDashboardScreen> {
  String? _activeModuleId;
  int _bottomNavIndex = 0;

  // General navigation state
  String? _selectedClientId;
  Map<String, dynamic>? _selectedClientFicha;
  String? _selectedPortfolioId;

  // Modules general state
  bool _isLoadingAction = false;

  // Visit controller variables
  final _visitObservationController = TextEditingController();
  String _visitResult = 'VISITA_EFECTIVA';

  // M2: Planificacion de Ruta State
  List<dynamic> _routeList = [];
  bool _isRouteOptimized = false;

  // M3: Ficha client active ID
  String? _m3SelectedClientId;

  // M4: Pre-evaluacion State
  final _preevalFormKey = GlobalKey<FormState>();
  final _preevalDniController = TextEditingController();
  final _preevalNameController = TextEditingController();
  double _preevalMonto = 5000;
  String _preevalNegocio = 'Comercio';
  String _preevalDestino = 'Capital de trabajo';
  Map<String, dynamic>? _preevalResult;

  // M5: Captura Solicitud (4 pasos) State
  int _currentStep = 0;
  final _m5FormKey = GlobalKey<FormState>();
  final _m5NameController = TextEditingController();
  final _m5LastNameController = TextEditingController();
  final _m5DniController = TextEditingController();
  final _m5PhoneController = TextEditingController();
  final _m5BizNameController = TextEditingController();
  final _m5BizAddressController = TextEditingController();
  final _m5BizIncomeController = TextEditingController();
  final _m5BizExpensesController = TextEditingController();
  final _m5AmountController = TextEditingController(text: '5000');
  final _m5TermController = TextEditingController(text: '12');

  String _m5CivilState = 'Soltero';
  String _m5Instruction = 'Secundaria';
  String _m5BizType = 'Comercio';
  String _m5CuotaType = 'Mensual';
  String _m5Warranty = 'Sin garantía';
  String _m5Currency = 'PEN';
  bool _m5Seguro = true;
  String? _m5CreatedId;
  String? _m5CreatedExp;

  // Signature controller for M5 & M7
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: AppConstants.colorPrimary,
    exportBackgroundColor: Colors.white,
  );

  // M6: Documentos State
  Map<String, String> _documentStates = {
    'dni_anverso': 'PENDIENTE',
    'dni_reverso': 'PENDIENTE',
    'foto_negocio': 'PENDIENTE',
    'foto_cliente_asesor': 'PENDIENTE',
  };
  Map<String, String> _documentQuality = {};

  // M7: Buro State
  bool _m7ConsentChecked = false;
  Map<String, dynamic>? _m7BuroResult;

  // M8: Transmision State
  int _m8TransmissionStep = -1; // -1 = not started, 0 = validando, 1 = subiendo, 2 = registrando, 3 = expediente, 4 = exito
  String? _m8ExpedienteNumber;

  // M9: Estado de Solicitudes State
  String _m9ActiveTab = 'ENVIADAS'; // ENVIADAS, COMITE, APROBADAS, DESEMBOLSADAS, RECHAZADAS
  final _m9NoteController = TextEditingController();
  List<dynamic> _m9SolicitudesList = [];

  // M10: Cartera Vencida State
  final _m10CobranzaObservationController = TextEditingController();
  final _m10CobranzaMontoController = TextEditingController();
  String _m10CobranzaAction = 'Visita';
  String _m10CobranzaResult = 'Compromiso de pago';
  DateTime? _m10CobranzaDate;
  Map<String, dynamic>? _m10SelectedMora;

  static const List<Map<String, dynamic>> testCases30 = [
    {
      'num': 1,
      'name': 'Anaximandro Quispe',
      'doc': '40118120',
      'phone': '964110201',
      'biz_name': 'Bodega Don Anaxi',
      'biz_giro': 'Bodega',
      'biz_dist': 'El Tambo',
      'biz_ant': 48,
      'income': 2200.0,
      'expenses': 900.0,
      'amount': 1000.0,
      'term': 12,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Capital de trabajo: compra de mercaderia',
      'lat': -12.0581,
      'lng': -75.2027,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 1000.0,
    },
    {
      'num': 2,
      'name': 'Eulalia Mamani',
      'doc': '41223341',
      'phone': '964110202',
      'biz_name': 'Picanteria La Eulalia',
      'biz_giro': 'Restaurante',
      'biz_dist': 'Chilca',
      'biz_ant': 36,
      'income': 3000.0,
      'expenses': 1400.0,
      'amount': 3000.0,
      'term': 12,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'sin garantia',
      'dest': 'Compra de cocina industrial',
      'lat': -12.0921,
      'lng': -75.2105,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 3000.0,
    },
    {
      'num': 3,
      'name': 'Teofilo Huaman',
      'doc': '42330336',
      'phone': '964110203',
      'biz_name': 'Maderas Huaman',
      'biz_giro': 'Carpinteria',
      'biz_dist': 'Pilcomayo',
      'biz_ant': 60,
      'income': 4200.0,
      'expenses': 1800.0,
      'amount': 5000.0,
      'term': 18,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Maquinaria: sierra y cepillo',
      'lat': -12.0496,
      'lng': -75.2486,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 5000.0,
    },
    {
      'num': 4,
      'name': 'Casandra Flores',
      'doc': '43440349',
      'phone': '964110204',
      'biz_name': 'Distribuidora Casandra',
      'biz_giro': 'Abarrotes',
      'biz_dist': 'Huancayo',
      'biz_ant': 84,
      'income': 7000.0,
      'expenses': 2600.0,
      'amount': 8000.0,
      'term': 6,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Reposicion de stock por campana',
      'lat': -12.0651,
      'lng': -75.2049,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 8000.0,
    },
    {
      'num': 5,
      'name': 'Demostenes Rojas',
      'doc': '40556071',
      'phone': '964110205',
      'biz_name': 'Ferreteria El Constructor',
      'biz_giro': 'Ferreteria',
      'biz_dist': 'San Agustin de Cajas',
      'biz_ant': 30,
      'income': 5200.0,
      'expenses': 2100.0,
      'amount': 10000.0,
      'term': 12,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Ampliacion de local',
      'lat': -12.0188,
      'lng': -75.2271,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 10000.0,
    },
    {
      'num': 6,
      'name': 'Hipatia Condori',
      'doc': '41669066',
      'phone': '964110206',
      'biz_name': 'Confecciones Hipatia',
      'biz_giro': 'Textil',
      'biz_dist': 'El Tambo',
      'biz_ant': 54,
      'income': 6800.0,
      'expenses': 2900.0,
      'amount': 12000.0,
      'term': 24,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'hipotecaria',
      'dest': 'Compra de maquinas remalladoras',
      'lat': -12.0612,
      'lng': -75.2118,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 12000.0,
    },
    {
      'num': 7,
      'name': 'Anibal Vargas',
      'doc': '43773379',
      'phone': '964110207',
      'biz_name': 'Transportes Anibal',
      'biz_giro': 'Transporte',
      'biz_dist': 'Concepcion',
      'biz_ant': 42,
      'income': 9500.0,
      'expenses': 4200.0,
      'amount': 15000.0,
      'term': 18,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'vehicular',
      'dest': 'Cuota inicial de vehiculo de carga',
      'lat': -11.9182,
      'lng': -75.3142,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 15000.0,
    },
    {
      'num': 8,
      'name': 'Penelope Apaza',
      'doc': '40886086',
      'phone': '964110208',
      'biz_name': 'Granja Penelope',
      'biz_giro': 'Avicola',
      'biz_dist': 'Sapallanga',
      'biz_ant': 72,
      'income': 8800.0,
      'expenses': 3600.0,
      'amount': 18000.0,
      'term': 24,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Ampliacion de galpon',
      'lat': -12.1581,
      'lng': -75.1762,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 18000.0,
    },
    {
      'num': 9,
      'name': 'Heraclito Ccahua',
      'doc': '41990091',
      'phone': '964110209',
      'biz_name': 'Importaciones Heraclito',
      'biz_giro': 'Comercio',
      'biz_dist': 'Huancayo',
      'biz_ant': 96,
      'income': 12000.0,
      'expenses': 5000.0,
      'amount': 20000.0,
      'term': 36,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Capital para nueva sucursal',
      'lat': -12.0668,
      'lng': -75.2103,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 20000.0,
    },
    {
      'num': 10,
      'name': 'Cleopatra Soto',
      'doc': '43003039',
      'phone': '964110210',
      'biz_name': 'Botica Cleopatra',
      'biz_giro': 'Farmacia',
      'biz_dist': 'Chupaca',
      'biz_ant': 66,
      'income': 11000.0,
      'expenses': 4400.0,
      'amount': 25000.0,
      'term': 24,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'hipotecaria',
      'dest': 'Equipamiento y stock farmaceutico',
      'lat': -12.056,
      'lng': -75.287,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 25000.0,
    },
    {
      'num': 11,
      'name': 'Esquilo Ramos',
      'doc': '40110010',
      'phone': '964110211',
      'biz_name': 'Minimarket Esquilo',
      'biz_giro': 'Bodega',
      'biz_dist': 'Huayucachi',
      'biz_ant': 24,
      'income': 1900.0,
      'expenses': 800.0,
      'amount': 2000.0,
      'term': 12,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Compra de congeladora',
      'lat': -12.1339,
      'lng': -75.209,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 2000.0,
    },
    {
      'num': 12,
      'name': 'Ariadna Quispe',
      'doc': '41226021',
      'phone': '964110212',
      'biz_name': 'Estilos Ariadna',
      'biz_giro': 'Peluqueria',
      'biz_dist': 'El Tambo',
      'biz_ant': 40,
      'income': 3300.0,
      'expenses': 1300.0,
      'amount': 4000.0,
      'term': 18,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Mobiliario y equipos de salon',
      'lat': -12.0573,
      'lng': -75.2161,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 4000.0,
    },
    {
      'num': 13,
      'name': 'Sofocles Huanca',
      'doc': '43336033',
      'phone': '964110213',
      'biz_name': 'Panaderia Sofocles',
      'biz_giro': 'Panaderia',
      'biz_dist': 'Sicaya',
      'biz_ant': 58,
      'income': 5600.0,
      'expenses': 2300.0,
      'amount': 6000.0,
      'term': 12,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'sin garantia',
      'dest': 'Horno rotativo',
      'lat': -12.0228,
      'lng': -75.3134,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 0,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 6000.0,
    },
    {
      'num': 14,
      'name': 'Casiopea Torres',
      'doc': '40550055',
      'phone': '964110214',
      'biz_name': 'Taller Casiopea',
      'biz_giro': 'Mecanica',
      'biz_dist': 'Pilcomayo',
      'biz_ant': 50,
      'income': 7400.0,
      'expenses': 3000.0,
      'amount': 7500.0,
      'term': 6,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Herramienta neumatica',
      'lat': -12.0512,
      'lng': -75.2451,
      'preeval_res': 'APTO',
      'buro_res': 'DEFICIENTE',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 45,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 7500.0,
    },
    {
      'num': 15,
      'name': 'Aristofanes Cruz',
      'doc': '41669166',
      'phone': '964110215',
      'biz_name': 'Insumos Aristofanes',
      'biz_giro': 'Agropecuario',
      'biz_dist': 'Orcotuna',
      'biz_ant': 78,
      'income': 8200.0,
      'expenses': 3300.0,
      'amount': 9000.0,
      'term': 24,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Capital para campana agricola',
      'lat': -11.976,
      'lng': -75.3361,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 9000.0,
    },
    {
      'num': 16,
      'name': 'Calipso Mendoza',
      'doc': '43880088',
      'phone': '964110216',
      'biz_name': 'Calzados Calipso',
      'biz_giro': 'Calzado',
      'biz_dist': 'Huancayo',
      'biz_ant': 62,
      'income': 7900.0,
      'expenses': 3100.0,
      'amount': 11000.0,
      'term': 18,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'hipotecaria',
      'dest': 'Compra de cuero y maquinaria',
      'lat': -12.0689,
      'lng': -75.2055,
      'preeval_res': 'APTO',
      'buro_res': 'CPP',
      'deuda_ent': 1,
      'deuda_tot': 9000.0,
      'mora_dias': 20,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 11000.0,
    },
    {
      'num': 17,
      'name': 'Demetrio Quispe',
      'doc': '40119019',
      'phone': '964110217',
      'biz_name': 'Mayorista Demetrio',
      'biz_giro': 'Comercio',
      'biz_dist': 'Jauja',
      'biz_ant': 90,
      'income': 11500.0,
      'expenses': 4700.0,
      'amount': 13500.0,
      'term': 12,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Reposicion de inventario mayorista',
      'lat': -11.7752,
      'lng': -75.4995,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 13500.0,
    },
    {
      'num': 18,
      'name': 'Antigona Flores',
      'doc': '41226126',
      'phone': '964110218',
      'biz_name': 'Recreo Antigona',
      'biz_giro': 'Restaurante',
      'biz_dist': 'Concepcion',
      'biz_ant': 70,
      'income': 9200.0,
      'expenses': 3900.0,
      'amount': 16000.0,
      'term': 36,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Ampliacion y remodelacion',
      'lat': -11.9201,
      'lng': -75.311,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 16000.0,
    },
    {
      'num': 19,
      'name': 'Pitagoras Rojas',
      'doc': '43339033',
      'phone': '964110219',
      'biz_name': 'Ferreteria Pitagoras',
      'biz_giro': 'Ferreteria',
      'biz_dist': 'El Tambo',
      'biz_ant': 100,
      'income': 13000.0,
      'expenses': 5200.0,
      'amount': 17000.0,
      'term': 24,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'hipotecaria',
      'dest': 'Compra de stock estructural',
      'lat': -12.0599,
      'lng': -75.2143,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 0,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 17000.0,
    },
    {
      'num': 20,
      'name': 'Berenice Apaza',
      'doc': '40556056',
      'phone': '964110220',
      'biz_name': 'Tejidos Berenice',
      'biz_giro': 'Textil',
      'biz_dist': 'San Jeronimo de Tunan',
      'biz_ant': 46,
      'income': 8600.0,
      'expenses': 3500.0,
      'amount': 19000.0,
      'term': 18,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Maquinaria de tejido plano',
      'lat': -11.9871,
      'lng': -75.2899,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 19000.0,
    },
    {
      'num': 21,
      'name': 'Anaxagoras Huaman',
      'doc': '43889089',
      'phone': '964110221',
      'biz_name': 'Carga Anaxagoras',
      'biz_giro': 'Transporte',
      'biz_dist': 'Huancayo',
      'biz_ant': 84,
      'income': 14000.0,
      'expenses': 5800.0,
      'amount': 22000.0,
      'term': 36,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'vehicular',
      'dest': 'Cuota inicial de camion',
      'lat': -12.0644,
      'lng': -75.2088,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 22000.0,
    },
    {
      'num': 22,
      'name': 'Climene Vargas',
      'doc': '41003001',
      'phone': '964110222',
      'biz_name': 'Avicola Climene',
      'biz_giro': 'Avicola',
      'biz_dist': 'Sapallanga',
      'biz_ant': 76,
      'income': 13500.0,
      'expenses': 5500.0,
      'amount': 24000.0,
      'term': 24,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'hipotecaria',
      'dest': 'Equipamiento de planta',
      'lat': -12.156,
      'lng': -75.179,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 24000.0,
    },
    {
      'num': 23,
      'name': 'Epaminondas Soto',
      'doc': '40115011',
      'phone': '964110223',
      'biz_name': 'Bodega Epaminondas',
      'biz_giro': 'Bodega',
      'biz_dist': 'Pucara',
      'biz_ant': 28,
      'income': 2600.0,
      'expenses': 1000.0,
      'amount': 1500.0,
      'term': 6,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Compra de vitrinas',
      'lat': -12.1701,
      'lng': -75.1611,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 2,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 1500.0,
    },
    {
      'num': 24,
      'name': 'Lisistrata Ramos',
      'doc': '41336036',
      'phone': '964110224',
      'biz_name': 'Variedades Lisistrata',
      'biz_giro': 'Comercio',
      'biz_dist': 'Huancayo',
      'biz_ant': 52,
      'income': 4100.0,
      'expenses': 1700.0,
      'amount': 3500.0,
      'term': 12,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Capital de trabajo',
      'lat': -12.0633,
      'lng': -75.2071,
      'preeval_res': 'APTO',
      'buro_res': 'NORMAL',
      'deuda_ent': 1,
      'deuda_tot': 1000.0,
      'mora_dias': 0,
      'inhabilitado': false,
      'decision': 'APROBADO',
      'aprobado_monto': 3500.0,
    },
    {
      'num': 25,
      'name': 'Filoctetes Cruz',
      'doc': '41552052',
      'phone': '964110225',
      'biz_name': 'Cevicheria Filoctetes',
      'biz_giro': 'Restaurante',
      'biz_dist': 'Chilca',
      'biz_ant': 18,
      'income': 3800.0,
      'expenses': 2200.0,
      'amount': 11000.0,
      'term': 18,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'sin garantia',
      'dest': 'Ampliacion de local nuevo',
      'lat': -12.093,
      'lng': -75.209,
      'preeval_res': 'APTO',
      'buro_res': 'CPP',
      'deuda_ent': 2,
      'deuda_tot': 18000.0,
      'mora_dias': 15,
      'inhabilitado': false,
      'decision': 'CONDICIONADO',
      'aprobado_monto': 7000.0,
    },
    {
      'num': 26,
      'name': 'Calirroe Mendoza',
      'doc': '41888088',
      'phone': '964110226',
      'biz_name': 'Calzados Calirroe',
      'biz_giro': 'Calzado',
      'biz_dist': 'El Tambo',
      'biz_ant': 34,
      'income': 5000.0,
      'expenses': 2600.0,
      'amount': 16000.0,
      'term': 24,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Maquinaria de mayor capacidad',
      'lat': -12.0588,
      'lng': -75.2129,
      'preeval_res': 'APTO',
      'buro_res': 'CPP',
      'deuda_ent': 1,
      'deuda_tot': 9000.0,
      'mora_dias': 20,
      'inhabilitado': false,
      'decision': 'CONDICIONADO',
      'aprobado_monto': 10000.0,
    },
    {
      'num': 27,
      'name': 'Tucidides Quispe',
      'doc': '42220022',
      'phone': '964110227',
      'biz_name': 'Ferreteria Tucidides',
      'biz_giro': 'Ferreteria',
      'biz_dist': 'Concepcion',
      'biz_ant': 40,
      'income': 6200.0,
      'expenses': 2900.0,
      'amount': 20000.0,
      'term': 24,
      'tea': 40.92,
      'seguro': true,
      'warranty': 'hipotecaria',
      'dest': 'Compra de stock y montacarga',
      'lat': -11.9176,
      'lng': -75.3155,
      'preeval_res': 'APTO',
      'buro_res': 'CPP',
      'deuda_ent': 2,
      'deuda_tot': 18000.0,
      'mora_dias': 15,
      'inhabilitado': false,
      'decision': 'CONDICIONADO',
      'aprobado_monto': 14000.0,
    },
    {
      'num': 28,
      'name': 'Aquiles Mamani',
      'doc': '43337037',
      'phone': '964110228',
      'biz_name': 'Comercial Aquiles',
      'biz_giro': 'Comercio',
      'biz_dist': 'Huancayo',
      'biz_ant': 60,
      'income': 9000.0,
      'expenses': 3600.0,
      'amount': 15000.0,
      'term': 24,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'hipotecaria',
      'dest': 'Capital de trabajo',
      'lat': -12.0657,
      'lng': -75.2099,
      'preeval_res': 'APTO',
      'buro_res': 'PERDIDA',
      'deuda_ent': 4,
      'deuda_tot': 40000.0,
      'mora_dias': 210,
      'inhabilitado': true,
      'decision': 'RECHAZADO',
      'aprobado_monto': 15000.0,
    },
    {
      'num': 29,
      'name': 'Medea Apaza',
      'doc': '41884084',
      'phone': '964110229',
      'biz_name': 'Bodega Medea',
      'biz_giro': 'Bodega',
      'biz_dist': 'Pilcomayo',
      'biz_ant': 22,
      'income': 1800.0,
      'expenses': 1100.0,
      'amount': 14000.0,
      'term': 18,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'sin garantia',
      'dest': 'Compra de camioneta para reparto',
      'lat': -12.0489,
      'lng': -75.247,
      'preeval_res': 'REVISAR',
      'buro_res': 'DUDOSO',
      'deuda_ent': 3,
      'deuda_tot': 1000.0,
      'mora_dias': 95,
      'inhabilitado': false,
      'decision': 'RECHAZADO',
      'aprobado_monto': 14000.0,
    },
    {
      'num': 30,
      'name': 'Esquines Rojas',
      'doc': '43334034',
      'phone': '964110230',
      'biz_name': 'Fletes Esquines',
      'biz_giro': 'Transporte',
      'biz_dist': 'Jauja',
      'biz_ant': 30,
      'income': 7000.0,
      'expenses': 3200.0,
      'amount': 30000.0,
      'term': 24,
      'tea': 43.92,
      'seguro': false,
      'warranty': 'vehicular',
      'dest': 'Compra de unidad de transporte',
      'lat': -11.774,
      'lng': -75.501,
      'preeval_res': 'APTO',
      'buro_res': 'DUDOSO',
      'deuda_ent': 3,
      'deuda_tot': 1000.0,
      'mora_dias': 95,
      'inhabilitado': true,
      'decision': 'RECHAZADO',
      'aprobado_monto': 30000.0,
    },
  ];

  // ==========================================
  // --- 30 CASOS DE PRUEBA DRAWER & ACTIONS ---
  // ==========================================

  Widget _buildCasesDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            color: AppConstants.colorPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                const Text(
                  '30 Casos de Prueba',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seleccione un caso para auto-completar el flujo',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: testCases30.length,
              itemBuilder: (context, index) {
                final c = testCases30[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: AppConstants.colorPrimary.withOpacity(0.1),
                    child: Text(c['num'].toString(), style: const TextStyle(color: AppConstants.colorPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: Text('DNI: ${c['doc']} | S/ ${c['amount']}', style: const TextStyle(fontSize: 10)),
                  trailing: const Icon(Icons.chevron_right, size: 14),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    _showCaseDetailsDialog(c, this.context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCaseDetailsDialog(Map<String, dynamic> c, BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppConstants.colorPrimary,
              child: Text(c['num'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Caso ${c['num']}: ${c['name']}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCaseDetailRow('DNI / Doc', c['doc']),
              _buildCaseDetailRow('Teléfono', c['phone']),
              _buildCaseDetailRow('Negocio', '${c['biz_name']} (${c['biz_giro']})'),
              _buildCaseDetailRow('Distrito', c['biz_dist']),
              _buildCaseDetailRow('Antigüedad', '${c['biz_ant']} meses'),
              _buildCaseDetailRow('Ingresos', 'S/ ${c['income']}'),
              _buildCaseDetailRow('Gastos', 'S/ ${c['expenses']}'),
              const Divider(),
              _buildCaseDetailRow('Monto Sol.', 'S/ ${c['amount']}'),
              _buildCaseDetailRow('Plazo', '${c['term']} meses'),
              _buildCaseDetailRow('TEA', '${c['tea']}%'),
              _buildCaseDetailRow('Seguro', c['seguro'] ? 'Con seguro' : 'Sin seguro'),
              _buildCaseDetailRow('Garantía', c['warranty']),
              _buildCaseDetailRow('Destino', c['dest']),
              const Divider(),
              const Text('Resultados Esperados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.colorPrimary)),
              const SizedBox(height: 4),
              _buildCaseDetailRow('Pre-evaluación', c['preeval_res']),
              _buildCaseDetailRow('Buró SBS', c['buro_res']),
              _buildCaseDetailRow('Comité', c['decision']),
              _buildCaseDetailRow('Aprobado', 'S/ ${c['aprobado_monto']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CERRAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.colorPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              _loadTestCase(c, context);
            },
            child: const Text('CARGAR CASO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 11)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _loadTestCase(Map<String, dynamic> c, BuildContext context) {
    setState(() {
      // 1. M4 Pre-evaluacion auto-fill
      _preevalDniController.text = c['doc'];
      _preevalNameController.text = c['name'];
      
      // Convert amount to double safely
      _preevalMonto = (c['amount'] is num) ? (c['amount'] as num).toDouble() : (double.tryParse(c['amount'].toString()) ?? 5000.0);
      _preevalDestino = c['dest'] ?? 'Capital de trabajo';

      // Normalize biz_giro to preevalNegocio and m5BizType dropdown values: ['Comercio', 'Servicios', 'Producción']
      final giro = (c['biz_giro'] as String? ?? 'Comercio').toLowerCase();
      if (giro == 'restaurante' || giro == 'transporte' || giro == 'peluqueria' || giro == 'mecanica' || giro == 'servicios') {
        _preevalNegocio = 'Servicios';
        _m5BizType = 'Servicios';
      } else if (giro == 'carpinteria' || giro == 'textil' || giro == 'panaderia' || giro == 'calzado' || giro == 'producción' || giro == 'produccion') {
        _preevalNegocio = 'Producción';
        _m5BizType = 'Producción';
      } else {
        _preevalNegocio = 'Comercio';
        _m5BizType = 'Comercio';
      }

      // 2. M5 Capturar Solicitud auto-fill
      final nameParts = c['name'].split(' ');
      _m5NameController.text = nameParts.length > 0 ? nameParts[0] : '';
      _m5LastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _m5DniController.text = c['doc'];
      _m5PhoneController.text = c['phone'];
      _m5BizNameController.text = c['biz_name'];
      _m5BizAddressController.text = 'Av. Principal ' + c['num'].toString();
      _m5BizIncomeController.text = c['income'].toString();
      _m5BizExpensesController.text = c['expenses'].toString();
      _m5AmountController.text = c['amount'].toString();
      _m5TermController.text = c['term'].toString();
      _m5CivilState = 'Soltero';
      _m5CuotaType = 'Mensual';

      // Normalize warranty to dropdown values: ['Sin garantía', 'Aval garante', 'Hipotecaria', 'Vehicular']
      String rawWarranty = (c['warranty'] as String? ?? 'sin garantia').toLowerCase();
      if (rawWarranty.contains('hipoteca')) {
        _m5Warranty = 'Hipotecaria';
      } else if (rawWarranty.contains('aval') || rawWarranty.contains('garante')) {
        _m5Warranty = 'Aval garante';
      } else if (rawWarranty.contains('vehic') || rawWarranty.contains('auto') || rawWarranty.contains('mobiliaria')) {
        _m5Warranty = 'Vehicular';
      } else {
        _m5Warranty = 'Sin garantía';
      }

      _m5Seguro = c['seguro'] ?? true;

      // 3. M7 Buro Consent & Signatures
      _m7ConsentChecked = true;
      
      // Auto transition to the module
      _activeModuleId = 'M5'; // Direct to capturing request
      _currentStep = 0; // Reset steps in request capture
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Caso ' + c['num'].toString() + ' pre-cargado. Redirigido a M5: Capturar Solicitud.'),
        backgroundColor: AppConstants.colorPrimary,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(asesorProvider.notifier).loadPortfolio();
      _loadM9Solicitudes();
    });
  }

  @override
  void dispose() {
    _preevalDniController.dispose();
    _preevalNameController.dispose();
    _m5NameController.dispose();
    _m5LastNameController.dispose();
    _m5DniController.dispose();
    _m5PhoneController.dispose();
    _m5BizNameController.dispose();
    _m5BizAddressController.dispose();
    _m5BizIncomeController.dispose();
    _m5BizExpensesController.dispose();
    _m5AmountController.dispose();
    _m5TermController.dispose();
    _signatureController.dispose();
    _m9NoteController.dispose();
    _m10CobranzaObservationController.dispose();
    _m10CobranzaMontoController.dispose();
    _visitObservationController.dispose();
    super.dispose();
  }

  Future<void> _loadM9Solicitudes() async {
    try {
      final res = await DioClient().get('/fventas/solicitudes');
      setState(() {
        _m9SolicitudesList = res.data as List<dynamic>;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(asesorProvider);
    final userData = ref.watch(authProvider).userData;
    final String userName = userData != null ? (userData['nombre'] ?? 'Asesor de Negocios') : 'Asesor de Negocios';
    final String userCode = userData != null ? (userData['codigo_empleado'] ?? 'A001') : 'A001';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _buildCasesDrawer(context),
      appBar: AppBar(
        backgroundColor: AppConstants.colorPrimary,
        elevation: 0,
        title: Row(
          children: [
            const SipLogo(size: 28, inverted: true, showText: false),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _activeModuleId == null ? 'Fuerza de Ventas BN' : _getModuleTitle(_activeModuleId!),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.playlist_add_check_rounded, color: Colors.white, size: 28),
              tooltip: '30 Casos de Prueba',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(asesorProvider.notifier).loadPortfolio();
              _loadM9Solicitudes();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos actualizados'), backgroundColor: AppConstants.colorPrimary),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: _isLoadingAction
          ? const Center(child: CircularProgressIndicator(color: AppConstants.colorPrimary))
          : _bottomNavIndex == 1
              ? _buildProfileTab(userName, userCode, state)
              : _activeModuleId != null
                  ? _buildModuleView(state)
                  : _buildDashboard(userName, userCode, state),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        selectedItemColor: AppConstants.colorPrimary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
            if (index == 0) {
              _activeModuleId = null;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Mi Perfil'),
        ],
      ),
    );
  }

  String _getModuleTitle(String modId) {
    switch (modId) {
      case 'M1':
        return 'M1: Cartera Diaria';
      case 'M2':
        return 'M2: Planificación de Ruta';
      case 'M3':
        return 'M3: Ficha del Cliente';
      case 'M4':
        return 'M4: Pre-evaluación y Prospección';
      case 'M5':
        return 'M5: Captura de Solicitud';
      case 'M6':
        return 'M6: Captura de Documentos';
      case 'M7':
        return 'M7: Consulta de Buró y Listas';
      case 'M8':
        return 'M8: Transmisión Electrónica';
      case 'M9':
        return 'M9: Estado de Solicitudes';
      case 'M10':
        return 'M10: Cartera Vencida';
      case 'M11':
        return 'M11: Reportes y Supervisión';
      default:
        return 'Módulo';
    }
  }

  // --- DASHBOARD PRINCIPAL ---
  Widget _buildDashboard(String userName, String userCode, AsesorState state) {
    // Calculos rápidos para indicadores
    final totalVisits = state.portfolio.length;
    final completedVisits = state.portfolio.where((x) => x['estado_visita'] == 'REALIZADA' || x['estado_visita'] == 'COMPLETADO').length;
    final progress = totalVisits > 0 ? completedVisits / totalVisits : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Asesor Info Card
          Container(
            padding: const EdgeInsets.all(20),
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
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, $userName!',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: $userCode | Agencia BN Principal',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: state.isOnline ? Colors.green[400] : Colors.red[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(state.isOnline ? Icons.wifi : Icons.wifi_off, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            state.isOnline ? 'Online' : 'Offline',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildQuickStat('Avance Visitas', '$completedVisits/$totalVisits', Icons.assignment_turned_in),
                    _buildQuickStat('Sincronizaciones', '${state.syncQueue.length} pend.', Icons.sync),
                    _buildQuickStat('Expedientes', '${_m9SolicitudesList.length}', Icons.folder_open),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 11 modules grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: [
              _buildModuleCard('M1', 'Cartera Diaria', Icons.assignment, '${state.portfolio.length} asignaciones', Colors.blue),
              _buildModuleCard('M2', 'Planificación Ruta', Icons.map, _isRouteOptimized ? 'Ruta óptima lista' : 'Pendiente', Colors.indigo),
              _buildModuleCard('M3', 'Ficha Cliente', Icons.contact_page, 'Posición y SBS', Colors.green),
              _buildModuleCard('M4', 'Pre-evaluación', Icons.person_search, 'Capacidad y Campañas', Colors.orange),
              _buildModuleCard('M5', 'Capturar Solicitud', Icons.app_registration, 'Simulación Francesa', Colors.teal),
              _buildModuleCard('M6', 'Carga Documentos', Icons.camera_alt, 'Nitidez y Compresión', Colors.cyan),
              _buildModuleCard('M7', 'Buró & Listas', Icons.verified_user, 'Centrales y Firma', Colors.purple),
              _buildModuleCard('M8', 'Transmisión', Icons.cloud_upload, 'Envío al Comité', Colors.deepOrange),
              _buildModuleCard('M9', 'Estado Solicitudes', Icons.timeline, 'Historial y Kanban', Colors.amber),
              _buildModuleCard('M10', 'Cartera Vencida', Icons.assignment_late, 'Gestión de Mora', Colors.red),
              _buildModuleCard('M11', 'Reportes', Icons.bar_chart, 'Rendimiento y KPIs', Colors.blueGrey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildModuleCard(String id, String title, IconData icon, String subtitle, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          setState(() {
            _activeModuleId = id;
            if (id == 'M2' && _routeList.isEmpty) {
              _routeList = List.from(ref.read(asesorProvider).portfolio);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.colorPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppConstants.colorPrimary, size: 24),
                  ),
                  Text(
                    id,
                    style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- NAV PERFIL TAB ---
  Widget _buildProfileTab(String userName, String userCode, AsesorState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppConstants.colorPrimary.withOpacity(0.1),
            child: const Icon(Icons.person, size: 60, color: AppConstants.colorPrimary),
          ),
          const SizedBox(height: 16),
          Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text('Asesor de Microfinanzas', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.badge, color: AppConstants.colorPrimary),
            title: const Text('Código de Empleado'),
            trailing: Text(userCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          ListTile(
            leading: const Icon(Icons.home_work, color: AppConstants.colorPrimary),
            title: const Text('Agencia'),
            trailing: const Text('BN Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          ListTile(
            leading: const Icon(Icons.verified, color: AppConstants.colorPrimary),
            title: const Text('Rol de Sistema'),
            trailing: const Text('ASESOR / OPERADOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          ListTile(
            leading: const Icon(Icons.wifi, color: AppConstants.colorPrimary),
            title: const Text('Estado de Red'),
            trailing: Text(
              state.isOnline ? 'CONECTADO AL CORE' : 'MODO LOCAL OFFLINE',
              style: TextStyle(color: state.isOnline ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('CERRAR SESIÓN'),
          ),
          const SizedBox(height: 10),
          const Text('Banco de la Nación v2.5.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // --- MULTI-VISTA DE MODULOS ---
  Widget _buildModuleView(AsesorState state) {
    Widget content;
    switch (_activeModuleId) {
      case 'M1':
        content = _buildM1Cartera(state);
        break;
      case 'M2':
        content = _buildM2Ruta(state);
        break;
      case 'M3':
        content = _buildM3Ficha(state);
        break;
      case 'M4':
        content = _buildM4Preeval(state);
        break;
      case 'M5':
        content = _buildM5Solicitud(state);
        break;
      case 'M6':
        content = _buildM6Documentos(state);
        break;
      case 'M7':
        content = _buildM7Buro(state);
        break;
      case 'M8':
        content = _buildM8Transmision(state);
        break;
      case 'M9':
        content = _buildM9Estados(state);
        break;
      case 'M10':
        content = _buildM10Mora(state);
        break;
      case 'M11':
        content = _buildM11Reportes(state);
        break;
      default:
        content = const Center(child: Text('Módulo no implementado'));
    }

    return Column(
      children: [
        // Top return panel
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _activeModuleId = null;
                    _selectedClientId = null;
                    _selectedClientFicha = null;
                    _selectedPortfolioId = null;
                  });
                },
                icon: const Icon(Icons.arrow_back, color: AppConstants.colorPrimary),
                label: const Text('VOLVER AL DASHBOARD', style: TextStyle(color: AppConstants.colorPrimary, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: content),
      ],
    );
  }

  // ==========================================
  // --- M1: CARTERA DIARIA ---
  // ==========================================
  String _m1SearchQuery = '';
  String _m1Filter = 'Todos'; // Todos, Renovaciones, Nuevas, Visitados

  Widget _buildM1Cartera(AsesorState state) {
    if (state.portfolio.isEmpty) {
      return const Center(child: Text('No tiene gestiones programadas en su cartera diaria.'));
    }

    // Filtrado y orden por prioridad (0-100)
    var items = List.from(state.portfolio);
    
    // Sort logic (Priority Score descending, or completed at bottom)
    items.sort((a, b) {
      final isCompA = a['estado_visita'] == 'REALIZADA' || a['estado_visita'] == 'COMPLETADO';
      final isCompB = b['estado_visita'] == 'REALIZADA' || b['estado_visita'] == 'COMPLETADO';
      if (isCompA && !isCompB) return 1;
      if (!isCompA && isCompB) return -1;
      
      final int scoreA = a['score_prioridad'] ?? 0;
      final int scoreB = b['score_prioridad'] ?? 0;
      return scoreB.compareTo(scoreA); // Max score first
    });

    if (_m1SearchQuery.isNotEmpty) {
      items = items.where((x) {
        final gType = (x['tipo_gestion'] ?? '').toString().toLowerCase();
        final cId = (x['id_cliente'] ?? '').toString().toLowerCase();
        return gType.contains(_m1SearchQuery.toLowerCase()) || cId.contains(_m1SearchQuery.toLowerCase());
      }).toList();
    }

    if (_m1Filter == 'Renovaciones') {
      items = items.where((x) => x['tipo_gestion'] == 'RENOVACION' || x['tipo_gestion'] == 'AMPLIACION').toList();
    } else if (_m1Filter == 'Nuevas') {
      items = items.where((x) => x['tipo_gestion'] == 'NUEVA SOLICITUD').toList();
    } else if (_m1Filter == 'Visitados') {
      items = items.where((x) => x['estado_visita'] == 'REALIZADA' || x['estado_visita'] == 'COMPLETADO').toList();
    }

    return Column(
      children: [
        // Search & Filter Panel
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por tipo o código de cliente...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (val) => setState(() => _m1SearchQuery = val),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Todos', 'Renovaciones', 'Nuevas', 'Visitados'].map((f) {
                  final isSel = _m1Filter == f;
                  return ChoiceChip(
                    label: Text(f, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                    selected: isSel,
                    selectedColor: AppConstants.colorPrimary,
                    backgroundColor: Colors.grey[200],
                    onSelected: (val) {
                      if (val) setState(() => _m1Filter = f);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _selectedClientId != null
              ? _buildM1VisitaPanel(state)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final String priority = item['prioridad'] ?? 'NORMAL';
                    final String gestType = item['tipo_gestion'] ?? 'RENOVACION';
                    final String vState = item['estado_visita'] ?? 'PENDIENTE';
                    final int score = item['score_prioridad'] ?? 50;

                    final isCompleted = vState == 'REALIZADA' || vState == 'COMPLETADO';
                    Color pColor = Colors.grey;
                    if (!isCompleted) {
                      if (priority == 'ALTA') pColor = Colors.red;
                      if (priority == 'MEDIA') pColor = Colors.orange;
                      if (priority == 'BAJA' || priority == 'NORMAL') pColor = Colors.green;
                    }

                    return Card(
                      color: isCompleted ? Colors.grey[100] : Colors.white,
                      elevation: isCompleted ? 0 : 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: pColor.withOpacity(0.1),
                          child: Text(
                            isCompleted ? '✓' : priority[0],
                            style: TextStyle(color: pColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'Gestión: ${_formatGestionType(gestType)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          "Cliente: ***${item['id_cliente'].toString().substring(max(0, item['id_cliente'].toString().length - 6))}\nPrioridad: ${_formatPriority(priority)} ($score/100)",
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () async {
                          setState(() => _isLoadingAction = true);
                          final cFicha = await ref.read(asesorProvider.notifier).getFichaCliente(item['id_cliente']);
                          setState(() {
                            _selectedClientId = item['id_cliente'];
                            _selectedPortfolioId = item['id_cartera'];
                            _selectedClientFicha = cFicha;
                            _isLoadingAction = false;
                          });
                        },
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildM1VisitaPanel(AsesorState state) {
    if (_selectedClientFicha == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final client = _selectedClientFicha!['cliente'];
    final name = '${client['nombres']} ${client['apellidos']}';
    final doc = client['documento'] ?? '---';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectedClientId = null;
                      _selectedPortfolioId = null;
                    }),
                  ),
                  const Text('Registrar Gestión de Visita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text('Cliente: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('Documento: $doc'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visitResult,
                decoration: const InputDecoration(labelText: 'Resultado de Gestión', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'VISITA_EFECTIVA', child: Text('Visita Efectiva')),
                  DropdownMenuItem(value: 'CLIENTE_AUSENTE', child: Text('Cliente Ausente')),
                  DropdownMenuItem(value: 'DIRECCION_INCORRECTA', child: Text('Dirección Incorrecta')),
                  DropdownMenuItem(value: 'NEGOCIO_CERRADO', child: Text('Negocio Cerrado')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _visitResult = val);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _visitObservationController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Observación de Campo',
                  hintText: 'Detalle de la visita...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.colorPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  setState(() => _isLoadingAction = true);
                  // Geolocator coordinates fallback to center
                  double lat = -12.046374;
                  double lng = -77.042793;
                  try {
                    final pos = await Geolocator.getCurrentPosition(timeLimit: const Duration(seconds: 4));
                    lat = pos.latitude;
                    lng = pos.longitude;
                  } catch (_) {}

                  final ok = await ref.read(asesorProvider.notifier).registerVisit(
                        portfolioId: _selectedPortfolioId!,
                        result: _visitResult,
                        observation: _visitObservationController.text.trim(),
                        lat: lat,
                        lng: lng,
                      );

                  setState(() => _isLoadingAction = false);

                  if (ok) {
                    _visitObservationController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Visita guardada exitosamente'), backgroundColor: Colors.green),
                    );
                    setState(() {
                      _selectedClientId = null;
                      _selectedPortfolioId = null;
                    });
                  }
                },
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text('GUARDAR VISITA (GPS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- M2: PLANIFICACIÓN DE RUTA ---
  // ==========================================
  Widget _buildM2Ruta(AsesorState state) {
    if (!_isRouteOptimized && state.portfolio.isNotEmpty) {
      _routeList = List.from(state.portfolio);
    }
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Optimización de Ruta Diaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      _isRouteOptimized ? 'Ruta optimizada por cercanía' : 'Ruta en orden de asignación',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    )
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.colorPrimary),
                onPressed: () {
                  setState(() {
                    _isLoadingAction = true;
                  });
                  // Nearest Neighbor optimization simulation based on simulated coordinates
                  Future.delayed(const Duration(milliseconds: 800), () {
                    setState(() {
                      _routeList.sort((a, b) {
                        final latA = a['lat_visita'] ?? -12.04;
                        final latB = b['lat_visita'] ?? -12.04;
                        return latA.compareTo(latB);
                      });
                      _isRouteOptimized = true;
                      _isLoadingAction = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Algoritmo del vecino más cercano aplicado'), backgroundColor: Colors.green),
                    );
                  });
                },
                icon: const Icon(Icons.directions, color: Colors.white),
                label: const Text('OPTIMIZAR', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
        // Visual path canvas mock representing route nodes
        Container(
          height: 180,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: RouteMapPainter(_routeList.length, isOptimized: _isRouteOptimized),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _routeList.length,
            itemBuilder: (context, index) {
              final item = _routeList[index];
              final String priority = item['prioridad'] ?? 'NORMAL';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  title: Text(
                    'Visita #${index + 1}: Cliente ${item['id_cliente'] != null ? (item['id_cliente'].toString().length >= 8 ? item['id_cliente'].toString().substring(0, 8) : item['id_cliente'].toString()) : '---'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Prioridad: ${_formatPriority(priority)} | Estado: ${_formatVisitaEstado(item['estado_visita'])}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.navigation, color: AppConstants.colorPrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lanzando navegación externa (Waze/Google Maps) a cliente ${item['id_cliente']}'),
                          backgroundColor: AppConstants.colorPrimary,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // ==========================================
  // --- M3: FICHA DEL CLIENTE ---
  // ==========================================
  Widget _buildM3Ficha(AsesorState state) {
    final clients = state.portfolio.map((x) => x['id_cliente']?.toString() ?? '').where((x) => x.isNotEmpty).toSet().toList();

    if (clients.isEmpty) {
      return const Center(child: Text('Cargue su cartera primero.'));
    }

    if (_m3SelectedClientId == null || !clients.contains(_m3SelectedClientId)) {
      _m3SelectedClientId = clients.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFichaForM3(_m3SelectedClientId!);
      });
    }

    final hasFicha = _selectedClientFicha != null && _selectedClientFicha!['cliente'] != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            value: _m3SelectedClientId,
            decoration: const InputDecoration(labelText: 'Seleccionar Cliente de Cartera', border: OutlineInputBorder()),
            items: clients.map((c) {
              return DropdownMenuItem(value: c, child: Text('Cliente: ***${c.substring(max(0, c.length - 6))}'));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _m3SelectedClientId = val;
                  _selectedClientFicha = null;
                });
                _loadFichaForM3(val);
              }
            },
          ),
          const SizedBox(height: 16),
          if (!hasFicha)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Financial Status & personal Info Card
            _buildFichaClientCard(),
            const SizedBox(height: 16),
            // Behavior 12 Months bar chart
            _buildBehaviorChartSection(),
          ]
        ],
      ),
    );
  }

  Future<void> _loadFichaForM3(String cid) async {
    final data = await ref.read(asesorProvider.notifier).getFichaCliente(cid);
    setState(() {
      _selectedClientFicha = data;
    });
  }

  Widget _buildFichaClientCard() {
    final client = _selectedClientFicha!['cliente'];
    final name = '${client['nombres']} ${client['apellidos']}';
    final doc = client['documento'] ?? '---';
    final sbsRating = client['calificacion_sbs'] ?? 'NORMAL';

    // Semáforo color mappings
    Color semColor = Colors.green;
    if (sbsRating == 'CPP') semColor = Colors.yellow[700]!;
    if (sbsRating == 'DEFICIENTE') semColor = Colors.orange;
    if (sbsRating == 'DUDOSO') semColor = Colors.red;
    if (sbsRating == 'PERDIDA') semColor = Colors.grey[800]!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DATOS DEL CLIENTE', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: semColor, borderRadius: BorderRadius.circular(6)),
                  child: Text('SBS: $sbsRating', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text('Nombres: $name', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Documento: $doc'),
            Text('Dirección: ${client['direccion'] ?? '---'}'),
            Text('Negocio: ${client['tipo_negocio'] ?? 'Comercio'} | Antigüedad: ${client['antiguedad_negocio_meses'] ?? 12} meses'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[200]!)),
              child: const Row(
                children: [
                  Icon(Icons.stars, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('OFERTA PRE-APROBADA SCORING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green)),
                        Text('Línea Máx: S/ 15,000 | Tasa TEA: 32.5%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lanzando llamada telefónica...')),
                      );
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('LLAMAR'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorChartSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('COMPORTAMIENTO DE PAGOS (12 Meses)', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 3,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getBottomTitlesWidget),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _generateBarGroups(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Puntual', Colors.green),
                _buildLegendItem('Mora', Colors.red),
                _buildLegendItem('Sin Cuota', Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pagos puntuales: 83.3%'),
                Text('Mora Promedio: 4.2 días'),
              ],
            )
          ],
        ),
      ),
    );
  }

  static Widget _getBottomTitlesWidget(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Jul'; break;
      case 1: text = 'Ago'; break;
      case 2: text = 'Set'; break;
      case 3: text = 'Oct'; break;
      case 4: text = 'Nov'; break;
      case 5: text = 'Dic'; break;
      case 6: text = 'Ene'; break;
      case 7: text = 'Feb'; break;
      case 8: text = 'Mar'; break;
      case 9: text = 'Abr'; break;
      case 10: text = 'May'; break;
      case 11: text = 'Jun'; break;
      default: text = ''; break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }

  List<BarChartGroupData> _generateBarGroups() {
    // 12 months simulated states: 2=Puntual (Green), 1=Mora (Red), 0=Sin Cuota (Grey)
    final states = [2, 2, 1, 2, 2, 0, 2, 2, 1, 2, 2, 2];
    return List.generate(12, (index) {
      final st = states[index];
      Color bColor = Colors.green;
      if (st == 1) bColor = Colors.red;
      if (st == 0) bColor = Colors.grey;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: st == 0 ? 0.8 : st.toDouble(),
            color: bColor,
            width: 10,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    });
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ==========================================
  // --- M4: PRE-EVALUACIÓN Y PROSPECCIÓN ---
  // ==========================================
  Widget _buildM4Preeval(AsesorState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pre-eval form
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _preevalFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pre-evaluación Rápida de Prospectos', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _preevalDniController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'DNI / RUC del Prospecto', border: OutlineInputBorder()),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Ingrese DNI';
                        if (val.trim().length != 8) return 'DNI debe tener 8 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _preevalNameController,
                      decoration: const InputDecoration(labelText: 'Nombres y Apellidos completos', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese nombres' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _preevalNegocio,
                      decoration: const InputDecoration(labelText: 'Tipo de Negocio', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Comercio', child: Text('Comercio')),
                        DropdownMenuItem(value: 'Servicios', child: Text('Servicios')),
                        DropdownMenuItem(value: 'Producción', child: Text('Producción')),
                      ],
                      onChanged: (val) => setState(() => _preevalNegocio = val!),
                    ),
                    const SizedBox(height: 16),
                    Text('Monto Solicitado: S/ ${_preevalMonto.toInt()}'),
                    Slider(
                      value: _preevalMonto,
                      min: 500,
                      max: 50000,
                      divisions: 99,
                      activeColor: AppConstants.colorPrimary,
                      onChanged: (val) => setState(() => _preevalMonto = val),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.colorPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_preevalFormKey.currentState?.validate() ?? false) {
                          setState(() {
                            _isLoadingAction = true;
                          });
                          // Simulated check
                          Future.delayed(const Duration(milliseconds: 1000), () {
                            setState(() {
                              _isLoadingAction = false;
                              // Simple custom heuristic
                              if (_preevalDniController.text.startsWith('9')) {
                                _preevalResult = {
                                  'resultado': 'NO PROCEDE',
                                  'motivo': 'Cliente cuenta con castigos activos en Centrales de Riesgo SBS.',
                                  'color': Colors.red
                                };
                              } else if (_preevalDniController.text.startsWith('8') || _preevalMonto > 35000) {
                                _preevalResult = {
                                  'resultado': 'REVISAR',
                                  'motivo': 'Endeudamiento global elevado. Requiere sustento de garante.',
                                  'color': Colors.orange
                                };
                              } else {
                                _preevalResult = {
                                  'resultado': 'APTO',
                                  'motivo': 'Evaluación preliminar favorable. Puede proceder a solicitud formal.',
                                  'color': Colors.green
                                };
                              }
                            });
                          });
                        }
                      },
                      child: const Text('PRE-EVALUAR EN CAMPO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            ),
          ),
          if (_preevalResult != null) ...[
            const SizedBox(height: 16),
            Card(
              color: (_preevalResult!['color'] as Color).withOpacity(0.08),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: _preevalResult!['color'] as Color, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: _preevalResult!['color'] as Color),
                        const SizedBox(width: 8),
                        Text(
                          'RESULTADO: ${_preevalResult!['resultado']}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _preevalResult!['color'] as Color),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_preevalResult!['motivo']),
                    if (_preevalResult!['resultado'] == 'APTO') ...[
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () {
                          // Prefill M5 Form fields
                          _m5NameController.text = _preevalNameController.text;
                          _m5DniController.text = _preevalDniController.text;
                          _m5AmountController.text = _preevalMonto.toInt().toString();
                          setState(() {
                            _activeModuleId = 'M5';
                            _currentStep = 0;
                          });
                        },
                        child: const Text('INICIAR SOLICITUD FORMAL', style: TextStyle(color: Colors.white)),
                      )
                    ]
                  ],
                ),
              ),
            )
          ],
          const SizedBox(height: 24),
          const Text('Campañas Activas del Periodo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Campaign list item cards
          _buildCampaignCard('RENOVACIÓN PYME', 'Cliente: María Elena Rojas', 'Monto Ofrecido: S/ 12,000', 'Expira en 5 días'),
          _buildCampaignCard('PARALELO CONSUMO', 'Cliente: Jorge Bustamante', 'Monto Ofrecido: S/ 5,000', 'Expira en 12 días'),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(String type, String clientName, String amt, String exp) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.campaign, color: AppConstants.colorPrimary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.colorPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$clientName\n$amt\n$exp',
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.colorPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
              onPressed: () {
                _m5NameController.text = clientName;
                _m5AmountController.text = amt.replaceAll(RegExp(r'[^0-9]'), '');
                setState(() {
                  _activeModuleId = 'M5';
                  _currentStep = 0;
                });
              },
              child: const Text('Gestionar', style: TextStyle(fontSize: 11, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // --- M5: CAPTURA DE SOLICITUD ---
  // ==========================================
  Widget _buildM5Solicitud(AsesorState state) {
    return Form(
      key: _m5FormKey,
      child: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () async {
          if (_currentStep == 0) {
            if (_m5FormKey.currentState?.validate() ?? false) {
              setState(() => _currentStep = 1);
            }
          } else if (_currentStep == 1) {
            if (_m5FormKey.currentState?.validate() ?? false) {
              setState(() => _currentStep = 2);
            }
          } else if (_currentStep == 2) {
            setState(() => _currentStep = 3);
          } else if (_currentStep == 3) {
            // Confirm & submit request locally/online
            setState(() => _isLoadingAction = true);

            final amt = double.tryParse(_m5AmountController.text) ?? 5000;
            final term = int.tryParse(_m5TermController.text) ?? 12;

            final payload = {
              'id_producto_credito': '04780e00-eb2a-417c-bf59-56c0703c31f7', // seed credit product
              'monto_solicitado': amt,
              'plazo_meses': term,
              'con_seguro_desgravamen': _m5Seguro,
              'garantia': _m5Warranty,
              'destino_credito': 'Capital de trabajo',
              'lat_captura': -12.0463,
              'lng_captura': -77.0427,
              'documento_cliente': _m5DniController.text,
            };

            final res = await ref.read(asesorProvider.notifier).submitLoanRequest(payload);
            setState(() => _isLoadingAction = false);

            if (res != null) {
              setState(() {
                _m5CreatedId = res['id_solicitud'];
                _m5CreatedExp = res['numero_expediente'];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Borrador de solicitud creado exitosamente'), backgroundColor: Colors.green),
              );
              // Auto-jump to document step
              setState(() {
                _activeModuleId = 'M6';
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error al registrar solicitud')),
              );
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          // Step 1: Datos Personales
          Step(
            title: const Text('Paso 1: Datos del Solicitante'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextFormField(
                  controller: _m5NameController,
                  decoration: const InputDecoration(labelText: 'Nombres completo'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _m5LastNameController,
                  decoration: const InputDecoration(labelText: 'Apellidos completo'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _m5DniController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Número Documento (DNI/RUC)'),
                  validator: (val) => val == null || val.length < 8 ? 'Mínimo 8 dígitos' : null,
                ),
                TextFormField(
                  controller: _m5PhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono Celular'),
                  validator: (val) => val == null || val.length != 9 ? '9 dígitos' : null,
                ),
                DropdownButtonFormField<String>(
                  value: _m5CivilState,
                  decoration: const InputDecoration(labelText: 'Estado Civil'),
                  items: ['Soltero', 'Casado', 'Conviviente', 'Divorciado'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _m5CivilState = val!),
                ),
              ],
            ),
          ),
          // Step 2: Negocio
          Step(
            title: const Text('Paso 2: Datos de Negocio'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _m5BizType,
                  decoration: const InputDecoration(labelText: 'Tipo de Negocio'),
                  items: ['Comercio', 'Servicios', 'Producción'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _m5BizType = val!),
                ),
                TextFormField(
                  controller: _m5BizNameController,
                  decoration: const InputDecoration(labelText: 'Nombre Comercial / Razón Social'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _m5BizAddressController,
                  decoration: const InputDecoration(labelText: 'Dirección del Local'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                TextFormField(
                  controller: _m5BizIncomeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Ingresos Mensuales Estimados (S/)'),
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
              ],
            ),
          ),
          // Step 3: Condiciones (Real Amortization French simulation)
          Step(
            title: const Text('Paso 3: Condiciones de Crédito'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                TextFormField(
                  controller: _m5AmountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto Solicitado (S/)'),
                  onChanged: (val) => setState(() {}),
                ),
                TextFormField(
                  controller: _m5TermController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Plazo (Meses)'),
                  onChanged: (val) => setState(() {}),
                ),
                DropdownButtonFormField<String>(
                  value: _m5Warranty,
                  decoration: const InputDecoration(labelText: 'Tipo de Garantía'),
                  items: ['Sin garantía', 'Aval garante', 'Hipotecaria', 'Vehicular'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _m5Warranty = val!),
                ),
                SwitchListTile(
                  title: const Text('¿Incluye seguro de desgravamen?'),
                  value: _m5Seguro,
                  activeColor: AppConstants.colorPrimary,
                  onChanged: (val) => setState(() => _m5Seguro = val),
                ),
                const SizedBox(height: 12),
                // Real-time French calculation widget
                _buildRealtimeSimulationCard(),
              ],
            ),
          ),
          // Step 4: Resumen
          Step(
            title: const Text('Paso 4: Confirmación y Envío'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.editing,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RESUMEN DE SOLICITUD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(),
                Text('Cliente: ${_m5NameController.text} ${_m5LastNameController.text}'),
                Text('DNI: ${_m5DniController.text}'),
                Text('Monto solicitado: S/ ${_m5AmountController.text}'),
                Text('Plazo: ${_m5TermController.text} meses'),
                Text('Garantía: $_m5Warranty'),
                const SizedBox(height: 12),
                const Text('Presione continuar para registrar el borrador del expediente en el núcleo local.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeSimulationCard() {
    final double amt = double.tryParse(_m5AmountController.text) ?? 0;
    final int term = int.tryParse(_m5TermController.text) ?? 0;

    double cuota = 0;
    double tea = 32.5; // TEA estándar
    double totalPayable = 0;

    if (amt > 0 && term > 0) {
      double rate = pow(1 + (tea / 100), 1 / 12) - 1; // Tasa mensual equivalente
      cuota = amt * rate / (1 - pow(1 + rate, -term));
      totalPayable = cuota * term;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SIMULACIÓN DE CUOTA (SISTEMA FRANCÉS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 11)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cuota Mensual:'),
              Text('S/ ${cuota.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total a pagar:'),
              Text('S/ ${totalPayable.toStringAsFixed(2)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tasa referencial TEA:'),
              Text('${tea.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // --- M6: CAPTURA DE DOCUMENTOS ---
  // ==========================================
  Widget _buildM6Documentos(AsesorState state) {
    final list = _documentStates.keys.toList();
    final allListo = _documentStates.values.every((v) => v == 'LISTO');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Checklist de Documentos de Sustento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            _m5CreatedExp != null ? 'Expediente Relacionado: $_m5CreatedExp' : 'Ingrese desde el Módulo de Solicitud (M5)',
            style: const TextStyle(color: AppConstants.colorPrimary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final key = list[index];
                final val = _documentStates[key]!;
                final qText = _documentQuality[key] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          val == 'LISTO' ? Icons.check_circle : Icons.radio_button_off,
                          color: val == 'LISTO' ? Colors.green : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                key.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              val == 'LISTO'
                                  ? Text(
                                      'Estado: $val\n$qText',
                                      style: const TextStyle(color: Colors.green, fontSize: 11),
                                    )
                                  : const Text(
                                      'Estado: PENDIENTE',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.colorPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                          ),
                          onPressed: () {
                            setState(() {
                              _isLoadingAction = true;
                            });
                            // Simulate Camera, Laplacian nitidez filter, and compression of file
                            Future.delayed(const Duration(milliseconds: 1000), () {
                              setState(() {
                                _isLoadingAction = false;
                                _documentStates[key] = 'LISTO';
                                _documentQuality[key] = 'Nitidez Laplacian: 81.4% OK | Comprimido a 680 KB';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${key.replaceAll('_', ' ').toUpperCase()} capturado y validado'), backgroundColor: Colors.green),
                              );
                            });
                          },
                          child: const Text('Tomar Foto', style: TextStyle(fontSize: 11, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: allListo ? Colors.green : Colors.grey,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: allListo
                ? () {
                    // Navigate to Consent/Buro check M7
                    setState(() {
                      _activeModuleId = 'M7';
                    });
                  }
                : null,
            child: const Text('PROCEDER A FIRMA Y BURÓ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // --- M7: CONSULTA DE BURÓ Y LISTAS ---
  // ==========================================
  Widget _buildM7Buro(AsesorState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consentimiento Ley de Protección Datos (L29733)', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'El cliente abajo firmante autoriza expresamente al Banco de la Nación a consultar su reporte crediticio consolidado en las centrales de riesgo del Perú (SBS, Equifax, Experian) y realizar la búsqueda en listas internas de prevención de lavado de activos y listas negras.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _m7ConsentChecked,
                activeColor: AppConstants.colorPrimary,
                title: const Text('El cliente autoriza y declara de conformidad', style: TextStyle(fontSize: 12)),
                onChanged: (val) => setState(() => _m7ConsentChecked = val ?? false),
              ),
              const SizedBox(height: 12),
              const Text('Firma Digital del Cliente:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 150,
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.grey[50]!,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => _signatureController.clear(), child: const Text('LIMPIAR')),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _m7ConsentChecked ? AppConstants.colorPrimary : Colors.grey,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _m7ConsentChecked
                    ? () async {
                        final sigBytes = await _signatureController.toPngBytes();
                        if (sigBytes == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Debe registrar la firma táctil del cliente.')),
                          );
                          return;
                        }

                        setState(() => _isLoadingAction = true);

                        // Simulated Equifax check
                        Future.delayed(const Duration(milliseconds: 1200), () {
                          setState(() {
                            _isLoadingAction = false;
                            _m7BuroResult = {
                              'sbs': 'NORMAL',
                              'cuentas': 2,
                              'deuda_total': 12400.0,
                              'dias_mora_max': 0,
                              'lista_negra': false
                            };
                          });
                        });
                      }
                    : null,
                child: const Text('CONSULTAR BURÓ Y LISTAS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (_m7BuroResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[200]!)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('CENTRAL DE RIESGOS: LIMPIO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Calificación SBS: ' + _m7BuroResult!['sbs']),
                      Text('Deuda Consolidada: S/ ' + _m7BuroResult!['deuda_total'].toString()),
                      Text('Mayor mora registrada: ' + _m7BuroResult!['dias_mora_max'].toString() + ' días'),
                      const Text('Reporte guardado en expediente digital.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size(double.infinity, 50)),
                  onPressed: () {
                    // Navigate to transmission M8
                    setState(() {
                      _activeModuleId = 'M8';
                      _m8TransmissionStep = -1;
                    });
                  },
                  child: const Text('PROCEDER A TRANSMISIÓN AL COMITÉ', style: TextStyle(color: Colors.white)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- M8: TRANSMISIÓN ELECTRÓNICA ---
  // ==========================================
  Widget _buildM8Transmision(AsesorState state) {
    final steps = [
      'Validando consistencia de datos de solicitud...',
      'Subiendo documentos de sustento comprimidos (4/4)...',
      'Registrando expediente en Banco de la Nación...',
      'Asignando analista de Comité de Créditos...',
      'Envío exitoso de solicitud de crédito.',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transmisión de Expediente al Comité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Este paso realiza la subida atómica de los datos del cliente, expediente, documentos fotográficos y firma digital para su aprobación en agencia.',
            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 24),
          if (_m8TransmissionStep == -1) ...[
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.colorPrimary, minimumSize: const Size(200, 50)),
                onPressed: () {
                  setState(() {
                    _m8TransmissionStep = 0;
                  });
                  _runM8Sequence();
                },
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('ENVIAR AHORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ] else ...[
            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final isActive = _m8TransmissionStep == index;
                  final isDone = _m8TransmissionStep > index;

                  Color sColor = Colors.grey;
                  if (isActive) sColor = AppConstants.colorPrimary;
                  if (isDone) sColor = Colors.green;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        if (isActive)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.colorPrimary))
                        else
                          Icon(isDone ? Icons.check_circle : Icons.radio_button_off, color: sColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            steps[index],
                            style: TextStyle(
                              fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.normal,
                              color: isActive ? AppConstants.colorPrimary : (isDone ? Colors.green : Colors.grey),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_m8TransmissionStep >= 5) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('EXPEDIENTE ENVIADO AL COMITÉ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 6),
                    Text('Expediente ID: EXP-${DateTime.now().year}-${1000 + Random().nextInt(9000)}'),
                    const Text('Estado: EN COMITÉ (Aprobación estimada en 2 horas)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.colorPrimary, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  // Reset states and return to dashboard
                  setState(() {
                    _activeModuleId = null;
                    _m5NameController.clear();
                    _m5DniController.clear();
                    _signatureController.clear();
                    _documentStates = {
                      'dni_anverso': 'PENDIENTE',
                      'dni_reverso': 'PENDIENTE',
                      'foto_negocio': 'PENDIENTE',
                      'foto_cliente_asesor': 'PENDIENTE',
                    };
                    _m7BuroResult = null;
                    _m7ConsentChecked = false;
                  });
                  ref.read(asesorProvider.notifier).loadPortfolio();
                  _loadM9Solicitudes();
                },
                child: const Text('VOLVER A INICIO', style: TextStyle(color: Colors.white)),
              )
            ]
          ]
        ],
      ),
    );
  }

  void _runM8Sequence() {
    if (_m8TransmissionStep >= 5) return;
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _m8TransmissionStep += 1;
        });
        _runM8Sequence();
      }
    });
  }

  // ==========================================
  // --- M9: ESTADO DE SOLICITUDES ---
  // ==========================================
  Widget _buildM9Estados(AsesorState state) {
    final filtered = _m9SolicitudesList.where((sol) {
      final status = sol['estado']?.toString().toUpperCase() ?? 'ENVIADO';
      if (_m9ActiveTab == 'ENVIADAS') return status == 'BORRADOR' || status == 'ENVIADO';
      if (_m9ActiveTab == 'COMITE') return status == 'EN_COMITE' || status == 'ENVIADO';
      if (_m9ActiveTab == 'APROBADAS') return status == 'APROBADO';
      if (_m9ActiveTab == 'DESEMBOLSADAS') return status == 'DESEMBOLSADO';
      if (_m9ActiveTab == 'RECHAZADAS') return status == 'RECHAZADO';
      return false;
    }).toList();

    return Column(
      children: [
        // Tab row filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ENVIADAS', 'COMITE', 'APROBADAS', 'DESEMBOLSADAS', 'RECHAZADAS'].map((tab) {
              final isSel = _m9ActiveTab == tab;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: ChoiceChip(
                  label: Text(tab, style: TextStyle(fontSize: 10, color: isSel ? Colors.white : Colors.black87)),
                  selected: isSel,
                  selectedColor: AppConstants.colorPrimary,
                  backgroundColor: Colors.grey[200],
                  onSelected: (val) {
                    if (val) setState(() => _m9ActiveTab = tab);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No hay solicitudes en este estado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final numExp = item['numero_expediente'] ?? 'EXP-1010';
                    final amt = item['monto_solicitado'] ?? 0.0;
                    final date = item['created_at'] != null ? DateFormatter.formatDateString(item['created_at']) : '---';

                    return Card(
                      child: ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Expediente: ' + numExp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            _buildStatusBadge(item['estado'] ?? 'ENVIADO'),
                          ],
                        ),
                        subtitle: Text('Monto: S/ ' + amt.toString() + ' | F. Reg: ' + date, style: const TextStyle(fontSize: 11)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ID Solicitud: ' + item['id_solicitud'].toString()),
                                Text('Garantía: ' + (item['garantia'] ?? 'Sin garantía').toString()),
                                Text('Plazo solicitado: ' + item['plazo_meses'].toString() + ' meses'),
                                const SizedBox(height: 12),
                                const Text('Notas internas del Asesor:', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextFormField(
                                  controller: _m9NoteController,
                                  decoration: const InputDecoration(hintText: 'Añadir nota interna para comité/supervisor...', border: UnderlineInputBorder()),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.colorPrimary),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Nota guardada localmente')),
                                        );
                                      },
                                      child: const Text('Guardar Nota', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Generando y compartiendo PDF de estado...')),
                                        );
                                      },
                                      icon: const Icon(Icons.share, size: 16),
                                      label: const Text('Compartir Estado (PDF)', style: TextStyle(fontSize: 11)),
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  // ==========================================
  // --- M10: CARTERA VENCIDA (MORA) ---
  // ==========================================
  Widget _buildM10Mora(AsesorState state) {
    // Simulated late payments list
    final moras = [
      {'cliente': 'Humberto Candela Rojas', 'documento': '10884729', 'dias_mora': 12, 'monto_vencido': 340.0, 'sbs': 'CPP'},
      {'cliente': 'Martha Patricia Beltrán', 'documento': '42903728', 'dias_mora': 34, 'monto_vencido': 720.0, 'sbs': 'DEFICIENTE'},
      {'cliente': 'Guillermo Enrique Peña', 'documento': '08947294', 'dias_mora': 65, 'monto_vencido': 1480.0, 'sbs': 'DUDOSO'},
    ];

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Clientes en Mora Reciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(6)),
                child: const Text('Total Vencido: S/ 2,540.0', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
              )
            ],
          ),
        ),
        Expanded(
          child: _m10SelectedMora != null
              ? _buildM10CobranzaForm()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: moras.length,
                  itemBuilder: (context, index) {
                    final item = moras[index];
                    final int dias = item['dias_mora'] as int;

                    Color badgeColor = Colors.yellow[800]!;
                    if (dias > 30 && dias <= 60) badgeColor = Colors.orange;
                    if (dias > 60) badgeColor = Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: badgeColor.withOpacity(0.1),
                              child: Text(
                                '${dias}d',
                                style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['cliente'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'DNI: ${item['documento']} | Vencido: S/ ${item['monto_vencido']}',
                                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.colorPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () {
                                setState(() {
                                  _m10SelectedMora = item;
                                });
                              },
                              child: const Text('Gestionar', style: TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  Widget _buildM10CobranzaForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(onPressed: () => setState(() => _m10SelectedMora = null), icon: const Icon(Icons.close)),
                  const Text('Registrar Gestión de Cobranza', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(),
              Text('Cliente: ' + _m10SelectedMora!['cliente'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Días Mora: ' + _m10SelectedMora!['dias_mora'].toString() + ' días | Vencido: S/ ' + _m10SelectedMora!['monto_vencido'].toString()),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _m10CobranzaAction,
                decoration: const InputDecoration(labelText: 'Tipo de Acción', border: OutlineInputBorder()),
                items: ['Visita', 'Llamada', 'Mensaje'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _m10CobranzaAction = val!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _m10CobranzaResult,
                decoration: const InputDecoration(labelText: 'Resultado de Gestión', border: OutlineInputBorder()),
                items: ['Compromiso de pago', 'Pago parcial', 'Sin contacto', 'Negación a pagar']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _m10CobranzaResult = val!),
              ),
              if (_m10CobranzaResult == 'Compromiso de pago' || _m10CobranzaResult == 'Pago parcial') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _m10CobranzaMontoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Monto Comprometido / Pagado (S/)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(_m10CobranzaDate == null
                      ? 'Seleccionar Fecha Compromiso'
                      : 'Fecha: ' + DateFormatter.formatDateString(_m10CobranzaDate!.toIso8601String())),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) {
                      setState(() {
                        _m10CobranzaDate = date;
                      });
                    }
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _m10CobranzaObservationController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Observaciones de Cobranza', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.colorPrimary, minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  setState(() => _isLoadingAction = true);
                  Future.delayed(const Duration(milliseconds: 800), () {
                    setState(() {
                      _isLoadingAction = false;
                      _m10SelectedMora = null;
                      _m10CobranzaObservationController.clear();
                      _m10CobranzaMontoController.clear();
                      _m10CobranzaDate = null;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gestión de Cobranza registrada con GPS'), backgroundColor: Colors.green),
                    );
                  });
                },
                icon: const Icon(Icons.gps_fixed, color: Colors.white),
                label: const Text('REGISTRAR ACCIÓN Y GPS', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // --- M11: REPORTES Y SUPERVISIÓN ---
  // ==========================================
  Widget _buildM11Reportes(AsesorState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rendimiento de Gestión (Mes Actual)', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildReportRow('Clientes Asignados', '35'),
                  _buildReportRow('Visitas Efectivas', '26'),
                  _buildReportRow('Visitas Pendientes', '9'),
                  _buildReportRow('Tasa Cobertura', '74.2%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productividad de Colocación (Agencia)', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.colorPrimary)),
                  const Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 15,
                        titlesData: const FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, getTitlesWidget: _getM11BottomTitlesWidget),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _m11BarGroup(0, 12, 10), // Asesor A001
                          _m11BarGroup(1, 8, 5),   // Asesor A002
                          _m11BarGroup(2, 14, 11), // Asesor A003
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('Enviadas', Colors.blue),
                      const SizedBox(width: 16),
                      _buildLegendItem('Aprobadas', Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  static Widget _getM11BottomTitlesWidget(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Asesor A001'; break;
      case 1: text = 'Asesor A002'; break;
      case 2: text = 'Asesor A003'; break;
      default: text = ''; break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }

  BarChartGroupData _m11BarGroup(int x, double val1, double val2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: val1, color: Colors.blue, width: 8),
        BarChartRodData(toY: val2, color: Colors.green, width: 8),
      ],
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatGestionType(String type) {
    switch (type.toUpperCase()) {
      case 'RENOVACION':
      case 'RENOVACIÓN':
        return 'Renovación';
      case 'AMPLIACION':
      case 'AMPLIACIÓN':
        return 'Ampliación';
      case 'NUEVA SOLICITUD':
      case 'NUEVA_SOLICITUD':
        return 'Nueva Solicitud';
      default:
        return type;
    }
  }

  String _formatPriority(String? priority) {
    if (priority == null) return 'Normal';
    switch (priority.toUpperCase()) {
      case 'ALTA':
        return 'Alta';
      case 'MEDIA':
        return 'Media';
      case 'BAJA':
        return 'Baja';
      case 'NORMAL':
        return 'Normal';
      default:
        return priority;
    }
  }

  String _formatVisitaEstado(String? estado) {
    if (estado == null) return 'Pendiente';
    switch (estado.toUpperCase()) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'REALIZADA':
        return 'Realizada';
      case 'COMPLETADO':
        return 'Completado';
      default:
        return estado;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    String label = status;
    switch (status.toUpperCase()) {
      case 'BORRADOR':
        color = Colors.blueGrey;
        label = 'Borrador';
        break;
      case 'ENVIADO':
        color = Colors.blue;
        label = 'Enviado';
        break;
      case 'EN_COMITE':
      case 'ENVIADO_A_COMITE':
        color = Colors.purple;
        label = 'En Comité';
        break;
      case 'APROBADO':
        color = Colors.green;
        label = 'Aprobado';
        break;
      case 'DESEMBOLSADO':
        color = Colors.teal;
        label = 'Desembolsado';
        break;
      case 'RECHAZADO':
        color = Colors.red;
        label = 'Rechazado';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Custom Painter to mock route path layout in M2
class RouteMapPainter extends CustomPainter {
  final int nodeCount;
  final bool isOptimized;
  RouteMapPainter(this.nodeCount, {this.isOptimized = false});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Map Background
    final bgPaint = Paint()..color = const Color(0xFFF4F6F8);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Draw Parks (Green Zones)
    final parkPaint = Paint()
      ..color = const Color(0xFFE2EFE0)
      ..style = PaintingStyle.fill;
    
    // Draw some stylized parks
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 15, 60, 40), const Radius.circular(8)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(180, 20, 70, 50), const Radius.circular(12)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(40, 120, 100, 35), const Radius.circular(8)), parkPaint);

    // 3. Draw River (Water Body)
    final riverPaint = Paint()
      ..color = const Color(0xFFFDE8EC)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path();
    riverPath.moveTo(0, size.height * 0.4);
    riverPath.quadraticBezierTo(
      size.width * 0.3, size.height * 0.2,
      size.width * 0.6, size.height * 0.7,
    );
    riverPath.quadraticBezierTo(
      size.width * 0.8, size.height * 0.9,
      size.width, size.height * 0.8,
    );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Draw Streets Grid (White Roads)
    final streetPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final streetBorderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final roadPaths = <Path>[];

    // Horizontal roads
    for (double y in [size.height * 0.2, size.height * 0.5, size.height * 0.8]) {
      final p = Path()..moveTo(0, y)..lineTo(size.width, y);
      roadPaths.add(p);
    }
    // Vertical roads
    for (double x in [size.width * 0.25, size.width * 0.55, size.width * 0.85]) {
      final p = Path()..moveTo(x, 0)..lineTo(x, size.height);
      roadPaths.add(p);
    }

    // Draw borders
    for (var rp in roadPaths) {
      canvas.drawPath(rp, streetBorderPaint);
    }
    // Draw white fill
    for (var rp in roadPaths) {
      canvas.drawPath(rp, streetPaint);
    }

    // 5. Draw Compass / Scale indicator in corner
    final compassPaint = Paint()
      ..color = Colors.grey.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final compassCenter = Offset(size.width - 25, size.height - 25);
    canvas.drawCircle(compassCenter, 12, compassPaint);
    canvas.drawLine(compassCenter - const Offset(0, 10), compassCenter + const Offset(0, 10), compassPaint);
    canvas.drawLine(compassCenter - const Offset(10, 0), compassCenter + const Offset(10, 0), compassPaint);

    final compassFill = Paint()
      ..color = const Color(0xFFC8102E)
      ..style = PaintingStyle.fill;
    final northPath = Path()
      ..moveTo(compassCenter.dx, compassCenter.dy - 10)
      ..lineTo(compassCenter.dx - 3, compassCenter.dy)
      ..lineTo(compassCenter.dx + 3, compassCenter.dy)
      ..close();
    canvas.drawPath(northPath, compassFill);

    // Scale line
    canvas.drawLine(Offset(15, size.height - 15), Offset(55, size.height - 15), compassPaint);
    final scaleTextPainter = TextPainter(
      text: const TextSpan(
        text: '500 m',
        style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scaleTextPainter.paint(canvas, Offset(15, size.height - 27));

    // 6. Generate Fixed Client Locations for consistency
    final random = Random(42);
    final points = <Offset>[];
    final actualNodeCount = max(3, nodeCount);

    for (int i = 0; i < actualNodeCount; i++) {
      final x = 30.0 + random.nextDouble() * (size.width - 60.0);
      final y = 25.0 + random.nextDouble() * (size.height - 50.0);
      points.add(Offset(x, y));
    }

    // 7. Draw Route Path Line
    final pathPaint = Paint()
      ..color = isOptimized ? const Color(0xFF10B981) : const Color(0xFF6366F1) // Emerald green if optimized, indigo if not
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final routePath = Path();
    if (points.isNotEmpty) {
      routePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        routePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(routePath, pathPaint);
    }

    // 8. Draw Pins
    for (int i = 0; i < points.length; i++) {
      final isStart = i == 0;
      final pinColor = isStart
          ? const Color(0xFFC8102E)
          : (isOptimized ? const Color(0xFF10B981) : const Color(0xFF6366F1));

      // Draw shadow
      canvas.drawCircle(points[i] + const Offset(0, 2), 7, Paint()..color = Colors.black26);

      // Draw Outer pin circle
      canvas.drawCircle(points[i], 7, Paint()..color = pinColor);
      canvas.drawCircle(points[i], 5, Paint()..color = Colors.white);
      canvas.drawCircle(points[i], 3.5, Paint()..color = pinColor);

      // Label (Start or number)
      final textSpan = TextSpan(
        text: isStart ? 'INICIO' : 'C$i',
        style: TextStyle(
          color: Colors.white,
          backgroundColor: pinColor.withOpacity(0.85),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
      textPainter.paint(canvas, points[i] - Offset(textPainter.width / 2, 17));
    }
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) =>
      oldDelegate.nodeCount != nodeCount || oldDelegate.isOptimized != isOptimized;
}
