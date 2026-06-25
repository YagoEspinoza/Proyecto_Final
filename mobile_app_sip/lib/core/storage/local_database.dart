import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocalDatabase {
  static Database? _database;
  static final Map<String, List<Map<String, dynamic>>> _webDb = {};

  static Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on Web. Use web APIs.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sip_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table 1: local_cartera
        await db.execute('''
          CREATE TABLE local_cartera (
            id_cartera TEXT PRIMARY KEY,
            id_asesor TEXT,
            id_cliente TEXT,
            id_solicitud TEXT,
            fecha_asignacion TEXT,
            tipo_gestion TEXT,
            prioridad TEXT,
            score_prioridad INTEGER,
            estado_visita TEXT,
            resultado_visita TEXT,
            observacion_visita TEXT,
            lat_visita REAL,
            lng_visita REAL,
            timestamp_visita TEXT
          )
        ''');

        // Table 2: local_clientes
        await db.execute('''
          CREATE TABLE local_clientes (
            id_cliente TEXT PRIMARY KEY,
            documento TEXT,
            nombres TEXT,
            apellidos TEXT,
            telefono TEXT,
            correo TEXT,
            direccion TEXT,
            distrito TEXT,
            provincia TEXT,
            departamento TEXT,
            fecha_nacimiento TEXT,
            estado_civil TEXT,
            ocupacion TEXT,
            tipo_cliente TEXT,
            estado TEXT
          )
        ''');

        // Table 3: local_solicitudes_pendientes (creadas offline)
        await db.execute('''
          CREATE TABLE local_solicitudes_pendientes (
            id_solicitud TEXT PRIMARY KEY,
            id_producto_credito TEXT,
            monto_solicitado REAL,
            plazo_meses INTEGER,
            con_seguro_desgravamen INTEGER, -- 0=false, 1=true
            garantia TEXT,
            destino_credito TEXT,
            lat_captura REAL,
            lng_captura REAL,
            created_at TEXT
          )
        ''');

        // Table 4: local_visitas_pendientes (registradas offline)
        await db.execute('''
          CREATE TABLE local_visitas_pendientes (
            id_visita TEXT PRIMARY KEY,
            id_cartera TEXT,
            resultado TEXT,
            observacion TEXT,
            lat REAL,
            lng REAL,
            fecha_hora TEXT
          )
        ''');

        // Table 5: local_documentos_pendientes (documentos offline)
        await db.execute('''
          CREATE TABLE local_documentos_pendientes (
            id_documento TEXT PRIMARY KEY,
            id_solicitud TEXT,
            tipo_documento TEXT,
            nombre_archivo TEXT,
            file_path TEXT
          )
        ''');

        // Table 6: local_sync_queue (cola de envio general)
        await db.execute('''
          CREATE TABLE local_sync_queue (
            id_sync TEXT PRIMARY KEY,
            tipo TEXT, -- VISITA, SOLICITUD, FIRMA, DOCUMENTO
            entidad_id TEXT,
            payload TEXT, -- JSON
            created_at TEXT
          )
        ''');
      },
    );
  }

  // General helpers for inserting/querying/deleting
  static Future<void> insert(String table, Map<String, dynamic> data) async {
    if (kIsWeb) {
      _webDb[table] ??= [];
      // Find primary key to replace on conflict
      String primaryKeyField = 'id_sync';
      if (table == 'local_cartera') primaryKeyField = 'id_cartera';
      if (table == 'local_clientes') primaryKeyField = 'id_cliente';
      if (table == 'local_solicitudes_pendientes') primaryKeyField = 'id_solicitud';
      if (table == 'local_visitas_pendientes') primaryKeyField = 'id_visita';
      if (table == 'local_documentos_pendientes') primaryKeyField = 'id_documento';

      // Remove existing item if matches primary key
      if (data.containsKey(primaryKeyField)) {
        _webDb[table]!.removeWhere((item) => item[primaryKeyField] == data[primaryKeyField]);
      }
      // Store mutable map copy
      _webDb[table]!.add(Map<String, dynamic>.from(data));
      return;
    }

    final db = await database;
    await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) async {
    if (kIsWeb) {
      final list = _webDb[table] ?? [];
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        final field = where.split('=').first.trim();
        return list.where((item) => item[field]?.toString() == whereArgs.first?.toString()).toList();
      }
      return list;
    }

    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  static Future<void> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    if (kIsWeb) {
      if (where == null) {
        _webDb[table]?.clear();
        return;
      }
      if (whereArgs != null && whereArgs.isNotEmpty) {
        final field = where.split('=').first.trim();
        _webDb[table]?.removeWhere((item) => item[field]?.toString() == whereArgs.first?.toString());
      }
      return;
    }

    final db = await database;
    await db.delete(table, where: where, whereArgs: whereArgs);
  }

  static Future<void> clearTable(String table) async {
    if (kIsWeb) {
      _webDb[table]?.clear();
      return;
    }
    final db = await database;
    await db.delete(table);
  }

  static Future<void> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    if (kIsWeb) {
      final list = _webDb[table] ?? [];
      final field = where.split('=').first.trim();
      for (var item in list) {
        if (item[field]?.toString() == whereArgs.first?.toString()) {
          values.forEach((k, v) {
            item[k] = v;
          });
        }
      }
      return;
    }
    final db = await database;
    await db.update(table, values, where: where, whereArgs: whereArgs);
  }
}
