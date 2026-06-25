-- ==========================================
-- FILE: 00_extensions.sql
-- ==========================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ==========================================
-- FILE: 01_schema_auth_roles.sql
-- ==========================================
-- Tabla de agencias
CREATE TABLE IF NOT EXISTS agencias (
    id_agencia UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    distrito VARCHAR(100),
    provincia VARCHAR(100),
    departamento VARCHAR(100),
    estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'INACTIVO')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id_usuario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    documento VARCHAR(15) UNIQUE NOT NULL,
    codigo_empleado VARCHAR(20) UNIQUE,
    correo VARCHAR(120) UNIQUE,
    password_hash TEXT NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('CLIENTE', 'ASESOR', 'SUPERVISOR', 'ADMIN')),
    estado VARCHAR(20) DEFAULT 'ACTIVO' CHECK (estado IN ('ACTIVO', 'BLOQUEADO', 'INACTIVO')),
    intentos_fallidos INTEGER DEFAULT 0,
    bloqueado_hasta TIMESTAMPTZ,
    ultimo_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 02_schema_clientes_asesores.sql
-- ==========================================
-- Tabla de clientes
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_agencia UUID REFERENCES agencias(id_agencia) ON DELETE SET NULL,
    documento VARCHAR(15) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    correo VARCHAR(120),
    direccion TEXT,
    distrito VARCHAR(100),
    provincia VARCHAR(100),
    departamento VARCHAR(100),
    fecha_nacimiento DATE,
    estado_civil VARCHAR(30),
    ocupacion VARCHAR(100),
    tipo_cliente VARCHAR(30),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de negocios de clientes
CREATE TABLE IF NOT EXISTS negocios_cliente (
    id_negocio UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    nombre_comercial VARCHAR(150),
    giro_negocio VARCHAR(100),
    antiguedad_meses INTEGER,
    ingreso_mensual NUMERIC(12,2) NOT NULL,
    gasto_mensual NUMERIC(12,2) NOT NULL,
    direccion_negocio TEXT,
    lat_negocio NUMERIC(10,7),
    lng_negocio NUMERIC(10,7),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de asesores
CREATE TABLE IF NOT EXISTS asesores (
    id_asesor UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_agencia UUID REFERENCES agencias(id_agencia) ON DELETE SET NULL,
    codigo_empleado VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    cargo VARCHAR(80),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 03_schema_productos_cuentas.sql
-- ==========================================
-- Tabla de productos de credito
CREATE TABLE IF NOT EXISTS productos_credito (
    id_producto_credito UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(30) UNIQUE NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    tipo VARCHAR(50),
    tea_con_seguro NUMERIC(5,2) NOT NULL,
    tea_sin_seguro NUMERIC(5,2) NOT NULL,
    monto_minimo NUMERIC(12,2) NOT NULL,
    monto_maximo NUMERIC(12,2) NOT NULL,
    plazo_minimo INTEGER NOT NULL,
    plazo_maximo INTEGER NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de cuentas de ahorro
CREATE TABLE IF NOT EXISTS cuentas_ahorro (
    id_cuenta UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    numero_cuenta VARCHAR(30) UNIQUE NOT NULL,
    cci VARCHAR(30) UNIQUE NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    saldo_disponible NUMERIC(12,2) DEFAULT 0.00,
    saldo_contable NUMERIC(12,2) DEFAULT 0.00,
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de tarjetas
CREATE TABLE IF NOT EXISTS tarjetas (
    id_tarjeta UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    numero_enmascarado VARCHAR(30) NOT NULL,
    tipo_tarjeta VARCHAR(30) CHECK (tipo_tarjeta IN ('DEBITO', 'CREDITO')),
    marca VARCHAR(30),
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    fecha_vencimiento DATE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 04_schema_solicitudes_credito.sql
-- ==========================================
-- Tabla de solicitudes de credito
CREATE TABLE IF NOT EXISTS solicitudes_credito (
    id_solicitud UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_expediente VARCHAR(30) UNIQUE NOT NULL,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    id_negocio UUID REFERENCES negocios_cliente(id_negocio) ON DELETE CASCADE,
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE SET NULL,
    id_producto_credito UUID REFERENCES productos_credito(id_producto_credito) ON DELETE CASCADE,
    canal_origen VARCHAR(30) NOT NULL CHECK (canal_origen IN ('CLIENTE', 'ASESOR')),
    monto_solicitado NUMERIC(12,2) NOT NULL,
    monto_aprobado NUMERIC(12,2),
    plazo_meses INTEGER NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    tea_referencial NUMERIC(5,2) NOT NULL,
    con_seguro_desgravamen BOOLEAN DEFAULT TRUE,
    garantia VARCHAR(50),
    destino_credito TEXT,
    cuota_estimada NUMERIC(12,2) NOT NULL,
    estado VARCHAR(30) DEFAULT 'BORRADOR' CHECK (estado IN (
        'BORRADOR', 'ENVIADO', 'RECIBIDO_COMITE', 'EN_EVALUACION', 
        'APROBADO', 'CONDICIONADO', 'RECHAZADO', 'DESEMBOLSADO'
    )),
    resultado_preevaluacion VARCHAR(30),
    puntaje_preevaluacion INTEGER,
    resultado_buro VARCHAR(30),
    motivo_rechazo TEXT,
    condicion_adicional TEXT,
    firma_cliente_base64 TEXT,
    lat_captura NUMERIC(10,7),
    lng_captura NUMERIC(10,7),
    pendiente_sync BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 05_schema_cartera_visitas.sql
-- ==========================================
-- Tabla de cartera diaria del asesor
CREATE TABLE IF NOT EXISTS cartera_diaria (
    id_cartera UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE SET NULL,
    fecha_asignacion DATE DEFAULT CURRENT_DATE,
    tipo_gestion VARCHAR(50) NOT NULL CHECK (tipo_gestion IN (
        'NUEVA_SOLICITUD', 'RENOVACION', 'AMPLIACION', 'SEGUIMIENTO', 'RECUPERACION_MORA', 'DESERTOR'
    )),
    prioridad VARCHAR(20) NOT NULL CHECK (prioridad IN ('ALTA', 'MEDIA', 'BAJA')),
    score_prioridad INTEGER DEFAULT 0,
    estado_visita VARCHAR(30) DEFAULT 'PENDIENTE' CHECK (estado_visita IN (
        'PENDIENTE', 'REALIZADA', 'NO_UBICADO', 'RECHAZADA'
    )),
    resultado_visita VARCHAR(50),
    observacion_visita TEXT,
    lat_visita NUMERIC(10,7),
    lng_visita NUMERIC(10,7),
    timestamp_visita TIMESTAMPTZ,
    pendiente_sync BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de visitas del cliente
CREATE TABLE IF NOT EXISTS visitas_cliente (
    id_visita UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cartera UUID REFERENCES cartera_diaria(id_cartera) ON DELETE CASCADE,
    id_asesor UUID REFERENCES asesores(id_asesor) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    resultado VARCHAR(50) NOT NULL,
    observacion TEXT,
    lat NUMERIC(10,7) NOT NULL,
    lng NUMERIC(10,7) NOT NULL,
    fecha_hora TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 06_schema_creditos_cronograma_movimientos.sql
-- ==========================================
-- Tabla de creditos vigentes (espejo del nucleo)
CREATE TABLE IF NOT EXISTS cr_creditos (
    id_credito UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    numero_credito VARCHAR(30) UNIQUE NOT NULL,
    producto VARCHAR(120) NOT NULL,
    monto_desembolsado NUMERIC(12,2) NOT NULL,
    saldo_capital NUMERIC(12,2) NOT NULL,
    plazo_meses INTEGER NOT NULL,
    tea NUMERIC(5,2) NOT NULL,
    tem NUMERIC(8,6) NOT NULL,
    cuota_mensual NUMERIC(12,2) NOT NULL,
    fecha_desembolso DATE NOT NULL,
    dia_pago INTEGER NOT NULL,
    estado VARCHAR(30) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de cronograma de pagos
CREATE TABLE IF NOT EXISTS cr_cronograma_pagos (
    id_cuota UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_credito UUID REFERENCES cr_creditos(id_credito) ON DELETE CASCADE,
    numero_cuota INTEGER NOT NULL,
    fecha_pago DATE NOT NULL,
    monto_cuota NUMERIC(12,2) NOT NULL,
    capital NUMERIC(12,2) NOT NULL,
    interes NUMERIC(12,2) NOT NULL,
    saldo NUMERIC(12,2) NOT NULL,
    estado VARCHAR(30) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'PAGADA', 'VENCIDA', 'PARCIAL')),
    fecha_pago_real DATE,
    monto_pagado NUMERIC(12,2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de movimientos historicos
CREATE TABLE IF NOT EXISTS cr_movimientos (
    id_movimiento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    id_cuenta UUID REFERENCES cuentas_ahorro(id_cuenta) ON DELETE SET NULL,
    id_credito UUID REFERENCES cr_creditos(id_credito) ON DELETE SET NULL,
    tipo_movimiento VARCHAR(50) NOT NULL CHECK (tipo_movimiento IN (
        'DESEMBOLSO_CREDITO', 'TRANSFERENCIA', 'PAGO_CUOTA', 'DEPOSITO', 'RETIRO', 'AJUSTE'
    )),
    descripcion TEXT,
    monto NUMERIC(12,2) NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    fecha_movimiento TIMESTAMPTZ DEFAULT now(),
    canal VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de operaciones de clientes
CREATE TABLE IF NOT EXISTS operaciones_cliente (
    id_operacion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    tipo_operacion VARCHAR(50) NOT NULL CHECK (tipo_operacion IN ('TRANSFERENCIA', 'PAGO_CREDITO', 'PAGO_SERVICIO')),
    cuenta_origen UUID REFERENCES cuentas_ahorro(id_cuenta) ON DELETE SET NULL,
    cuenta_destino VARCHAR(30),
    id_credito UUID REFERENCES cr_creditos(id_credito) ON DELETE SET NULL,
    monto NUMERIC(12,2) NOT NULL,
    moneda VARCHAR(3) DEFAULT 'PEN',
    descripcion TEXT,
    estado VARCHAR(30) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'PROCESADA', 'RECHAZADA')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 07_schema_sync_outbox_log.sql
-- ==========================================
-- Tabla de cola de eventos outbox para sync
CREATE TABLE IF NOT EXISTS sync_outbox (
    id_evento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_evento VARCHAR(80) NOT NULL,
    entidad VARCHAR(80) NOT NULL,
    entidad_id UUID NOT NULL,
    payload JSONB NOT NULL,
    estado VARCHAR(30) DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE', 'PROCESADO', 'ERROR')),
    intentos INTEGER DEFAULT 0,
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    procesado_at TIMESTAMPTZ
);

-- Tabla de log de sincronizacion
CREATE TABLE IF NOT EXISTS sync_log (
    id_log UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_evento UUID REFERENCES sync_outbox(id_evento) ON DELETE SET NULL,
    accion VARCHAR(100) NOT NULL,
    resultado VARCHAR(30) NOT NULL,
    detalle TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de auditoria de eventos
CREATE TABLE IF NOT EXISTS auditoria_eventos (
    id_auditoria UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE SET NULL,
    accion VARCHAR(100) NOT NULL,
    entidad VARCHAR(100) NOT NULL,
    entidad_id UUID,
    ip VARCHAR(80),
    user_agent TEXT,
    detalle JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 08_schema_notificaciones_documentos.sql
-- ==========================================
-- Tabla de lista de personas inhabilitadas
CREATE TABLE IF NOT EXISTS listas_inhabilitados (
    id_lista UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    documento VARCHAR(15) UNIQUE NOT NULL,
    motivo TEXT,
    estado VARCHAR(20) DEFAULT 'ACTIVO',
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de consultas del buro de credito
CREATE TABLE IF NOT EXISTS consultas_buro (
    id_consulta UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE CASCADE,
    id_cliente UUID REFERENCES clientes(id_cliente) ON DELETE CASCADE,
    documento VARCHAR(15) NOT NULL,
    calificacion VARCHAR(30) NOT NULL,
    entidades_deuda INTEGER DEFAULT 0,
    deuda_total NUMERIC(12,2) DEFAULT 0.00,
    mayor_mora_dias INTEGER DEFAULT 0,
    esta_inhabilitado BOOLEAN DEFAULT FALSE,
    resultado VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de documentos asociados a la solicitud
CREATE TABLE IF NOT EXISTS solicitudes_documentos (
    id_documento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_solicitud UUID REFERENCES solicitudes_credito(id_solicitud) ON DELETE CASCADE,
    tipo_documento VARCHAR(50) NOT NULL CHECK (tipo_documento IN (
        'DNI_FRENTE', 'DNI_REVERSO', 'SUSTENTO_NEGOCIO', 'FOTO_NEGOCIO', 'FOTO_VISITA', 'FIRMA_CLIENTE'
    )),
    nombre_archivo VARCHAR(200) NOT NULL,
    storage_path TEXT NOT NULL,
    url_publica TEXT,
    estado_validacion VARCHAR(30) DEFAULT 'PENDIENTE' CHECK (estado_validacion IN ('PENDIENTE', 'VALIDADO', 'RECHAZADO')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Tabla de notificaciones
CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_usuario UUID REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    titulo VARCHAR(150) NOT NULL,
    mensaje TEXT NOT NULL,
    tipo VARCHAR(50),
    leida BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);


-- ==========================================
-- FILE: 09_policies_rls.sql
-- ==========================================
-- Habilitar Row Level Security (RLS) en todas las tablas sensibles
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE negocios_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE asesores ENABLE ROW LEVEL SECURITY;
ALTER TABLE cuentas_ahorro ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarjetas ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_credito ENABLE ROW LEVEL SECURITY;
ALTER TABLE cartera_diaria ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitas_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultas_buro ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_documentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cr_creditos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cr_cronograma_pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cr_movimientos ENABLE ROW LEVEL SECURITY;
ALTER TABLE operaciones_cliente ENABLE ROW LEVEL SECURITY;
ALTER TABLE notificaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE auditoria_eventos ENABLE ROW LEVEL SECURITY;

-- Nota: Para simplificar el acceso a traves del Backend con la cadena de conexion administrativa local,
-- creamos politicas permisivas generales o especificas por rol de servicio.
-- En Supabase real, estas politicas controlan el acceso desde la API de PostgREST.

DROP POLICY IF EXISTS service_role_all ON usuarios;
CREATE POLICY service_role_all ON usuarios FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON clientes;
CREATE POLICY service_role_all ON clientes FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON negocios_cliente;
CREATE POLICY service_role_all ON negocios_cliente FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON asesores;
CREATE POLICY service_role_all ON asesores FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON cuentas_ahorro;
CREATE POLICY service_role_all ON cuentas_ahorro FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON tarjetas;
CREATE POLICY service_role_all ON tarjetas FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON solicitudes_credito;
CREATE POLICY service_role_all ON solicitudes_credito FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON cartera_diaria;
CREATE POLICY service_role_all ON cartera_diaria FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON visitas_cliente;
CREATE POLICY service_role_all ON visitas_cliente FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON consultas_buro;
CREATE POLICY service_role_all ON consultas_buro FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON solicitudes_documentos;
CREATE POLICY service_role_all ON solicitudes_documentos FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON cr_creditos;
CREATE POLICY service_role_all ON cr_creditos FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON cr_cronograma_pagos;
CREATE POLICY service_role_all ON cr_cronograma_pagos FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON cr_movimientos;
CREATE POLICY service_role_all ON cr_movimientos FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON operaciones_cliente;
CREATE POLICY service_role_all ON operaciones_cliente FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON notificaciones;
CREATE POLICY service_role_all ON notificaciones FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON sync_outbox;
CREATE POLICY service_role_all ON sync_outbox FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON sync_log;
CREATE POLICY service_role_all ON sync_log FOR ALL TO postgres USING (true);

DROP POLICY IF EXISTS service_role_all ON auditoria_eventos;
CREATE POLICY service_role_all ON auditoria_eventos FOR ALL TO postgres USING (true);


-- ==========================================
-- FILE: 10_seed_demo.sql
-- ==========================================
-- Seeding demo data for SIP Mobile Core 360
TRUNCATE TABLE sync_log, sync_outbox, auditoria_eventos, notificaciones, solicitudes_documentos, consultas_buro, visitas_cliente, cartera_diaria, cr_cronograma_pagos, cr_movimientos, cr_creditos, operaciones_cliente, tarjetas, cuentas_ahorro, negocios_cliente, clientes, asesores, usuarios, agencias, listas_inhabilitados, productos_credito CASCADE;

INSERT INTO agencias (id_agencia, codigo, nombre, direccion, distrito, provincia, departamento, estado) VALUES ('0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', 'AG001', 'Agencia Principal', 'Av. Central 123', 'San Isidro', 'Lima', 'Lima', 'ACTIVO');
INSERT INTO agencias (id_agencia, codigo, nombre, direccion, distrito, provincia, departamento, estado) VALUES ('ee0e3a01-18e7-4274-91a7-8cb9067454bb', 'AG002', 'Agencia Norte', 'Av. Central 123', 'Los Olivos', 'Lima', 'Lima', 'ACTIVO');
INSERT INTO agencias (id_agencia, codigo, nombre, direccion, distrito, provincia, departamento, estado) VALUES ('18a4137b-9985-4637-af12-1dbbfba2691f', 'AG003', 'Agencia Sur', 'Av. Central 123', 'Miraflores', 'Lima', 'Lima', 'ACTIVO');

INSERT INTO productos_credito (id_producto_credito, codigo, nombre, tipo, tea_con_seguro, tea_sin_seguro, monto_minimo, monto_maximo, plazo_minimo, plazo_maximo, moneda, estado) VALUES ('04780e00-eb2a-417c-bf59-56c0703c31f7', 'PROD001', 'Credito Microempresa Con Seguro', 'MICROEMPRESA', 40.92, 43.92, 500, 150000, 3, 60, 'PEN', 'ACTIVO');
INSERT INTO productos_credito (id_producto_credito, codigo, nombre, tipo, tea_con_seguro, tea_sin_seguro, monto_minimo, monto_maximo, plazo_minimo, plazo_maximo, moneda, estado) VALUES ('ec451add-61af-4afa-bbc0-78b2244cb8c0', 'PROD002', 'Credito Consumo Personal', 'CONSUMO', 60.0, 55.0, 1000, 25000, 12, 36, 'PEN', 'ACTIVO');
INSERT INTO productos_credito (id_producto_credito, codigo, nombre, tipo, tea_con_seguro, tea_sin_seguro, monto_minimo, monto_maximo, plazo_minimo, plazo_maximo, moneda, estado) VALUES ('b7105da4-8465-4cd2-b7ce-bb11c62a6d79', 'PROD003', 'Credito Comercial Pyme', 'COMERCIAL', 25.0, 20.0, 10000, 100000, 12, 48, 'PEN', 'ACTIVO');

INSERT INTO listas_inhabilitados (id_lista, documento, motivo, estado) VALUES ('91c8d1c2-287f-4965-acab-2347ac76ba35', '43337037', 'Antecedentes crediticios graves o lavado de activos', 'ACTIVO');
INSERT INTO listas_inhabilitados (id_lista, documento, motivo, estado) VALUES ('82976c50-070f-4418-a9a1-9da58fdf63de', '44556677', 'Antecedentes crediticios graves o lavado de activos', 'ACTIVO');
INSERT INTO listas_inhabilitados (id_lista, documento, motivo, estado) VALUES ('18712aea-efd9-4184-84db-dd805d7f6efc', '99887766', 'Antecedentes crediticios graves o lavado de activos', 'ACTIVO');
INSERT INTO listas_inhabilitados (id_lista, documento, motivo, estado) VALUES ('f7811870-2973-4df2-9bad-70c39fe9ff54', '77889900', 'Antecedentes crediticios graves o lavado de activos', 'ACTIVO');

INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('ff0b30cb-592c-47fa-bcee-4d28e62aa13d', '00000001', 'ADM001', 'admin@sip.com.pe', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'ADMIN', 'ACTIVO');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('8dd4b3bc-59f5-4ff2-aa7d-834cf642cdd0', '00000002', 'SUP001', 'supervisor@sip.com.pe', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'SUPERVISOR', 'ACTIVO');

INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('c86b3ca2-fe60-4cf2-af55-1ba48e6ad78b', '00000011', 'A001', 'asesor1@sip.com.pe', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'ASESOR', 'ACTIVO');
INSERT INTO asesores (id_asesor, id_usuario, id_agencia, codigo_empleado, nombres, apellidos, telefono, cargo, estado) VALUES ('dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'c86b3ca2-fe60-4cf2-af55-1ba48e6ad78b', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', 'A001', 'Jorge', 'Valdivia', '999111222', 'Asesor Senior', 'ACTIVO');

INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('df36b9a1-7867-451e-9157-3f2055789660', '40118120', NULL, 'anaximandro.quispe@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('3d875793-836d-4929-b555-c761efeb43b1', 'df36b9a1-7867-451e-9157-3f2055789660', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '40118120', 'Anaximandro', 'Quispe', '964110201', 'anaximandro.quispe@example.com', 'Calle Principal 101', 'El Tambo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('4d67cc1c-fd31-4607-b320-a65a7b999d03', '3d875793-836d-4929-b555-c761efeb43b1', '193-0000001-0-26', '002-193-001930000001026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('0597db38-0e46-4427-9235-347701220c30', '3d875793-836d-4929-b555-c761efeb43b1', '4557********0001', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('c5bdd2f4-4f06-4ad0-bf54-7e0f783f4a0c', '3d875793-836d-4929-b555-c761efeb43b1', 'Bodega Don Anaxi', 'Bodega', 48, 2200.00, 900.00, 'Direccion Negocio 1', -12.0581, -75.2027, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('5d4ada43-0d73-4916-9108-e26cd815699c', 'EXP-2026-1001', '3d875793-836d-4929-b555-c761efeb43b1', 'c5bdd2f4-4f06-4ad0-bf54-7e0f783f4a0c', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 1000.00, NULL, 12, 'PEN', 43.92, FALSE, 'sin garantia', 'Capital de trabajo: compra de mercaderia', 100.95, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('666bd127-6df4-467e-b2b7-7c51c62e4d7f', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '3d875793-836d-4929-b555-c761efeb43b1', '5d4ada43-0d73-4916-9108-e26cd815699c', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 94, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('d57f9b43-0d21-457f-9f44-fc5812590df8', '41223341', NULL, 'eulalia.mamani@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('6e64b00a-31b9-4496-817d-a5eb88b2cd84', 'd57f9b43-0d21-457f-9f44-fc5812590df8', '18a4137b-9985-4637-af12-1dbbfba2691f', '41223341', 'Eulalia', 'Mamani', '964110202', 'eulalia.mamani@example.com', 'Calle Principal 102', 'Chilca', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('e0c706ed-3420-4c80-9721-2c93fa446667', '6e64b00a-31b9-4496-817d-a5eb88b2cd84', '193-0000002-0-26', '002-193-001930000002026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('5bb83759-326b-417d-a716-7449aa54dcf6', '6e64b00a-31b9-4496-817d-a5eb88b2cd84', '4557********0002', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('a208ccf3-deae-4b25-bd5e-d242c3692d02', '6e64b00a-31b9-4496-817d-a5eb88b2cd84', 'Picanteria La Eulalia', 'Restaurante', 36, 3000.00, 1400.00, 'Direccion Negocio 2', -12.0921, -75.2105, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('7a2e11da-941b-4421-94de-1c1a5cbe267c', 'EXP-2026-1002', '6e64b00a-31b9-4496-817d-a5eb88b2cd84', 'a208ccf3-deae-4b25-bd5e-d242c3692d02', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 3000.00, NULL, 12, 'PEN', 40.92, TRUE, 'sin garantia', 'Compra de cocina industrial', 299.59, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('3fd3bd29-8b3c-4a36-aebe-80cc56362cee', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '6e64b00a-31b9-4496-817d-a5eb88b2cd84', '7a2e11da-941b-4421-94de-1c1a5cbe267c', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 93, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('44e8ee42-47c2-4816-a35b-ca805fa27d73', '42330336', NULL, 'teofilo.huaman@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('146e8a8d-cd8c-42b5-ba5f-4439c5225132', '44e8ee42-47c2-4816-a35b-ca805fa27d73', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '42330336', 'Teofilo', 'Huaman', '964110203', 'teofilo.huaman@example.com', 'Calle Principal 103', 'Pilcomayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('00fc4204-2c07-4f43-a2ec-318502b25769', '146e8a8d-cd8c-42b5-ba5f-4439c5225132', '193-0000003-0-26', '002-193-001930000003026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('cd369b96-645b-4b0c-92ee-8c764fd3fc7d', '146e8a8d-cd8c-42b5-ba5f-4439c5225132', '4557********0003', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('d3e4e8c3-8654-49f8-aded-b49e887f0caf', '146e8a8d-cd8c-42b5-ba5f-4439c5225132', 'Maderas Huaman', 'Carpinteria', 60, 4200.00, 1800.00, 'Direccion Negocio 3', -12.0496, -75.2486, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('3c0ad58d-8822-4ea9-b038-aeb435eb6719', 'EXP-2026-1003', '146e8a8d-cd8c-42b5-ba5f-4439c5225132', 'd3e4e8c3-8654-49f8-aded-b49e887f0caf', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 5000.00, NULL, 18, 'PEN', 43.92, FALSE, 'sin garantia', 'Maquinaria: sierra y cepillo', 366.02, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('37f636a4-920f-4e88-b003-d000d33e79aa', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '146e8a8d-cd8c-42b5-ba5f-4439c5225132', '3c0ad58d-8822-4ea9-b038-aeb435eb6719', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 92, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('5f344a1a-aa37-46f7-8240-1d4b7063a0d1', '43440349', NULL, 'casandra.flores@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('0969e905-2f1d-4120-b895-ca1afb5ce43f', '5f344a1a-aa37-46f7-8240-1d4b7063a0d1', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '43440349', 'Casandra', 'Flores', '964110204', 'casandra.flores@example.com', 'Calle Principal 104', 'Huancayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('c5b2933c-6896-4cf7-8128-4f279e5b1cf4', '0969e905-2f1d-4120-b895-ca1afb5ce43f', '193-0000004-0-26', '002-193-001930000004026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('36f1b528-1d75-4444-bb6b-de8b9d240fdc', '0969e905-2f1d-4120-b895-ca1afb5ce43f', '4557********0004', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('65481ef4-8a2f-45c0-81c4-cb26c7e61668', '0969e905-2f1d-4120-b895-ca1afb5ce43f', 'Distribuidora Casandra', 'Abarrotes', 84, 7000.00, 2600.00, 'Direccion Negocio 4', -12.0651, -75.2049, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('06942001-0b7e-41b1-a9c0-4f52cc1d9d0c', 'EXP-2026-1004', '0969e905-2f1d-4120-b895-ca1afb5ce43f', '65481ef4-8a2f-45c0-81c4-cb26c7e61668', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 8000.00, NULL, 6, 'PEN', 43.92, FALSE, 'sin garantia', 'Reposicion de stock por campana', 1480.73, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('3986a100-a055-485e-a373-838f58a14232', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '0969e905-2f1d-4120-b895-ca1afb5ce43f', '06942001-0b7e-41b1-a9c0-4f52cc1d9d0c', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 91, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('546f6b34-8a94-4b57-af13-0e05df391d53', '40556071', NULL, 'demostenes.rojas@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('b49b73d5-b724-426d-ab6b-e0c3ce8546fb', '546f6b34-8a94-4b57-af13-0e05df391d53', '18a4137b-9985-4637-af12-1dbbfba2691f', '40556071', 'Demostenes', 'Rojas', '964110205', 'demostenes.rojas@example.com', 'Calle Principal 105', 'San Agustin de Cajas', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('b8606b7c-5302-4ad6-a98a-97d52c97211f', 'b49b73d5-b724-426d-ab6b-e0c3ce8546fb', '193-0000005-0-26', '002-193-001930000005026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('78e9e05e-d643-4f11-9a7e-af4fcb9ac606', 'b49b73d5-b724-426d-ab6b-e0c3ce8546fb', '4557********0005', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('c62c516d-27c8-4071-b6f4-1769b7addc8d', 'b49b73d5-b724-426d-ab6b-e0c3ce8546fb', 'Ferreteria El Constructor', 'Ferreteria', 30, 5200.00, 2100.00, 'Direccion Negocio 5', -12.0188, -75.2271, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('991679bd-df77-44fc-a52a-0f34501a45d6', 'EXP-2026-1005', 'b49b73d5-b724-426d-ab6b-e0c3ce8546fb', 'c62c516d-27c8-4071-b6f4-1769b7addc8d', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 10000.00, NULL, 12, 'PEN', 43.92, FALSE, 'hipotecaria', 'Ampliacion de local', 1009.46, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('aa7d029a-36dd-4e27-ad2b-387e6902a0cd', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'b49b73d5-b724-426d-ab6b-e0c3ce8546fb', '991679bd-df77-44fc-a52a-0f34501a45d6', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 90, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('a494369e-2f43-4791-89b3-d45bb597c3ad', '41669066', NULL, 'hipatia.condori@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('c74eecbf-cbd5-4407-a507-522b08b29baa', 'a494369e-2f43-4791-89b3-d45bb597c3ad', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '41669066', 'Hipatia', 'Condori', '964110206', 'hipatia.condori@example.com', 'Calle Principal 106', 'El Tambo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('bcfdc8aa-694a-408d-8314-57b194426df2', 'c74eecbf-cbd5-4407-a507-522b08b29baa', '193-0000006-0-26', '002-193-001930000006026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('4b09f214-885e-4141-976c-2281eb98b35d', 'c74eecbf-cbd5-4407-a507-522b08b29baa', '4557********0006', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('005b4d0e-bf28-46f4-8f83-f1a17966bc8e', 'c74eecbf-cbd5-4407-a507-522b08b29baa', 'Confecciones Hipatia', 'Textil', 54, 6800.00, 2900.00, 'Direccion Negocio 6', -12.0612, -75.2118, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('352f2b8f-7b21-4a8a-8e49-ad48ce25b470', 'EXP-2026-1006', 'c74eecbf-cbd5-4407-a507-522b08b29baa', '005b4d0e-bf28-46f4-8f83-f1a17966bc8e', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 12000.00, NULL, 24, 'PEN', 40.92, TRUE, 'hipotecaria', 'Compra de maquinas remalladoras', 700.94, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('318b83bb-e990-47f6-bd88-1ee2f422e918', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'c74eecbf-cbd5-4407-a507-522b08b29baa', '352f2b8f-7b21-4a8a-8e49-ad48ce25b470', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 89, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('05899911-8315-4e55-82e5-2ae83594a1e7', '43773379', NULL, 'anibal.vargas@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('65207b65-c4c5-437b-a833-14fde25ebfa3', '05899911-8315-4e55-82e5-2ae83594a1e7', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '43773379', 'Anibal', 'Vargas', '964110207', 'anibal.vargas@example.com', 'Calle Principal 107', 'Concepcion', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('f30fb231-a41a-4a5b-859e-b9ace71a4d00', '65207b65-c4c5-437b-a833-14fde25ebfa3', '193-0000007-0-26', '002-193-001930000007026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('527c4383-b0f8-474e-8755-8e742511fdd7', '65207b65-c4c5-437b-a833-14fde25ebfa3', '4557********0007', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('ab3cf7d6-19c8-4977-a663-ff0b97db18be', '65207b65-c4c5-437b-a833-14fde25ebfa3', 'Transportes Anibal', 'Transporte', 42, 9500.00, 4200.00, 'Direccion Negocio 7', -11.9182, -75.3142, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('c221785e-a22d-412e-a447-8b7ccdeb13ef', 'EXP-2026-1007', '65207b65-c4c5-437b-a833-14fde25ebfa3', 'ab3cf7d6-19c8-4977-a663-ff0b97db18be', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 15000.00, NULL, 18, 'PEN', 43.92, FALSE, 'vehicular', 'Cuota inicial de vehiculo de carga', 1098.07, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('977fe215-b6a3-4879-bd88-d0d8be9d421c', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '65207b65-c4c5-437b-a833-14fde25ebfa3', 'c221785e-a22d-412e-a447-8b7ccdeb13ef', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 88, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('477af506-c511-4865-a002-bb9bac11962f', '40886086', NULL, 'penelope.apaza@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('22aac785-e6c4-42ab-a2d4-ab054d1f623e', '477af506-c511-4865-a002-bb9bac11962f', '18a4137b-9985-4637-af12-1dbbfba2691f', '40886086', 'Penelope', 'Apaza', '964110208', 'penelope.apaza@example.com', 'Calle Principal 108', 'Sapallanga', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('9de6ad98-1e33-4f77-86c4-a7298e2d5311', '22aac785-e6c4-42ab-a2d4-ab054d1f623e', '193-0000008-0-26', '002-193-001930000008026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('43391016-22eb-42c1-b031-2cde1385c4ee', '22aac785-e6c4-42ab-a2d4-ab054d1f623e', '4557********0008', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('41dc49ff-f1f9-4d3b-bc24-82d44d320518', '22aac785-e6c4-42ab-a2d4-ab054d1f623e', 'Granja Penelope', 'Avicola', 72, 8800.00, 3600.00, 'Direccion Negocio 8', -12.1581, -75.1762, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('b8885f0b-1cb0-40ec-a971-e6b9a6d78cb7', 'EXP-2026-1008', '22aac785-e6c4-42ab-a2d4-ab054d1f623e', '41dc49ff-f1f9-4d3b-bc24-82d44d320518', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 18000.00, NULL, 24, 'PEN', 43.92, FALSE, 'hipotecaria', 'Ampliacion de galpon', 1072.10, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('a1d61c69-f28b-479e-b580-5c322bddc4ed', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '22aac785-e6c4-42ab-a2d4-ab054d1f623e', 'b8885f0b-1cb0-40ec-a971-e6b9a6d78cb7', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 87, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('dbcaa661-b491-425a-93e3-d0d2e232f744', '41990091', NULL, 'heraclito.ccahua@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('5b6e0187-fa2b-44b1-bd33-1ef12e512f98', 'dbcaa661-b491-425a-93e3-d0d2e232f744', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '41990091', 'Heraclito', 'Ccahua', '964110209', 'heraclito.ccahua@example.com', 'Calle Principal 109', 'Huancayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('e39582a3-46df-4d5e-9481-3bc6e3def213', '5b6e0187-fa2b-44b1-bd33-1ef12e512f98', '193-0000009-0-26', '002-193-001930000009026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('a42aa4cd-f700-410e-a75a-0b69f0b0bb11', '5b6e0187-fa2b-44b1-bd33-1ef12e512f98', '4557********0009', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('4a711490-07cc-4b3e-88e7-f47c28a6f0c4', '5b6e0187-fa2b-44b1-bd33-1ef12e512f98', 'Importaciones Heraclito', 'Comercio', 96, 12000.00, 5000.00, 'Direccion Negocio 9', -12.0668, -75.2103, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('7c2e3330-ac17-45ca-973c-173508bfdd8a', 'EXP-2026-1009', '5b6e0187-fa2b-44b1-bd33-1ef12e512f98', '4a711490-07cc-4b3e-88e7-f47c28a6f0c4', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 20000.00, NULL, 36, 'PEN', 43.92, FALSE, 'hipotecaria', 'Capital para nueva sucursal', 927.12, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('0a6f4d50-6970-412c-94c2-f8b22fd6ad3e', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '5b6e0187-fa2b-44b1-bd33-1ef12e512f98', '7c2e3330-ac17-45ca-973c-173508bfdd8a', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 86, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('75367d86-2ec5-4bbd-a3b8-a96fd5bf3c7f', '43003039', NULL, 'cleopatra.soto@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('34c76174-4029-4354-b5f1-484b617feaad', '75367d86-2ec5-4bbd-a3b8-a96fd5bf3c7f', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '43003039', 'Cleopatra', 'Soto', '964110210', 'cleopatra.soto@example.com', 'Calle Principal 110', 'Chupaca', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('66410e09-9f6b-4d8d-a8cf-de10e07cc9d6', '34c76174-4029-4354-b5f1-484b617feaad', '193-0000010-0-26', '002-193-001930000010026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('4fd4223e-6880-41e5-b6ae-0cc0a943bbc1', '34c76174-4029-4354-b5f1-484b617feaad', '4557********0010', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('bc569d85-3d84-4e9d-ac72-d70f469a56fd', '34c76174-4029-4354-b5f1-484b617feaad', 'Botica Cleopatra', 'Farmacia', 66, 11000.00, 4400.00, 'Direccion Negocio 10', -12.056, -75.287, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('ec41e5e2-1384-44aa-a13b-9b3e91bd3fd2', 'EXP-2026-1010', '34c76174-4029-4354-b5f1-484b617feaad', 'bc569d85-3d84-4e9d-ac72-d70f469a56fd', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 25000.00, NULL, 24, 'PEN', 40.92, TRUE, 'hipotecaria', 'Equipamiento y stock farmaceutico', 1460.29, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('c3e3e1d9-54ad-4d72-9b60-fb1221b86321', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '34c76174-4029-4354-b5f1-484b617feaad', 'ec41e5e2-1384-44aa-a13b-9b3e91bd3fd2', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 85, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('82e6a994-43b2-4c32-912a-a1eee0fd2032', '40110010', NULL, 'esquilo.ramos@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('980dca8e-60d8-4c84-9a92-d130e2931580', '82e6a994-43b2-4c32-912a-a1eee0fd2032', '18a4137b-9985-4637-af12-1dbbfba2691f', '40110010', 'Esquilo', 'Ramos', '964110211', 'esquilo.ramos@example.com', 'Calle Principal 111', 'Huayucachi', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('e2b2bf15-9633-46d0-b96b-2ba23735179a', '980dca8e-60d8-4c84-9a92-d130e2931580', '193-0000011-0-26', '002-193-001930000011026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('9cf7cb9c-b2b3-4f87-9db0-997e9992f35a', '980dca8e-60d8-4c84-9a92-d130e2931580', '4557********0011', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('4540a8e7-c5a1-4578-9413-0d52535fa1b6', '980dca8e-60d8-4c84-9a92-d130e2931580', 'Minimarket Esquilo', 'Bodega', 24, 1900.00, 800.00, 'Direccion Negocio 11', -12.1339, -75.209, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('d83c060f-7c6f-445e-879e-1a8e09313a89', 'EXP-2026-1011', '980dca8e-60d8-4c84-9a92-d130e2931580', '4540a8e7-c5a1-4578-9413-0d52535fa1b6', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 2000.00, NULL, 12, 'PEN', 43.92, FALSE, 'sin garantia', 'Compra de congeladora', 201.89, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('07a3e308-4a97-4512-ae94-031d389f7dc2', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '980dca8e-60d8-4c84-9a92-d130e2931580', 'd83c060f-7c6f-445e-879e-1a8e09313a89', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 84, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('efb77112-2526-4704-b7a6-2e560a2f7c85', '41226021', NULL, 'ariadna.quispe@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('ec45754b-2018-4962-a736-7d801335e176', 'efb77112-2526-4704-b7a6-2e560a2f7c85', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '41226021', 'Ariadna', 'Quispe', '964110212', 'ariadna.quispe@example.com', 'Calle Principal 112', 'El Tambo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('79425559-6ff3-4644-8c01-1604fa6c2938', 'ec45754b-2018-4962-a736-7d801335e176', '193-0000012-0-26', '002-193-001930000012026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('d90dff8e-9e7b-46de-b06f-76ec41779935', 'ec45754b-2018-4962-a736-7d801335e176', '4557********0012', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('960ecd73-d291-4500-b7c3-65a58eec5d02', 'ec45754b-2018-4962-a736-7d801335e176', 'Estilos Ariadna', 'Peluqueria', 40, 3300.00, 1300.00, 'Direccion Negocio 12', -12.0573, -75.2161, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('891f4112-58f9-4682-abca-c27ece04e435', 'EXP-2026-1012', 'ec45754b-2018-4962-a736-7d801335e176', '960ecd73-d291-4500-b7c3-65a58eec5d02', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 4000.00, NULL, 18, 'PEN', 43.92, FALSE, 'sin garantia', 'Mobiliario y equipos de salon', 292.82, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('2601bf09-98d6-4c30-9c23-249dde9a98f0', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'ec45754b-2018-4962-a736-7d801335e176', '891f4112-58f9-4682-abca-c27ece04e435', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 83, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('79872d7f-79f4-4dd2-aadc-92708daa7c08', '43336033', NULL, 'sofocles.huanca@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('8f1d97a5-a0b6-4af6-8b90-96b26c5639e7', '79872d7f-79f4-4dd2-aadc-92708daa7c08', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '43336033', 'Sofocles', 'Huanca', '964110213', 'sofocles.huanca@example.com', 'Calle Principal 113', 'Sicaya', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('1b1794ff-f2e5-402e-94d7-84218783efe4', '8f1d97a5-a0b6-4af6-8b90-96b26c5639e7', '193-0000013-0-26', '002-193-001930000013026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('cb05ae92-da26-4e51-8ada-21c022815958', '8f1d97a5-a0b6-4af6-8b90-96b26c5639e7', '4557********0013', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('c81641ad-06ef-41dd-b5a6-4cde2999fb4c', '8f1d97a5-a0b6-4af6-8b90-96b26c5639e7', 'Panaderia Sofocles', 'Panaderia', 58, 5600.00, 2300.00, 'Direccion Negocio 13', -12.0228, -75.3134, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('bc683588-1185-4e72-b639-61c5f1319381', 'EXP-2026-1013', '8f1d97a5-a0b6-4af6-8b90-96b26c5639e7', 'c81641ad-06ef-41dd-b5a6-4cde2999fb4c', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 6000.00, NULL, 12, 'PEN', 40.92, TRUE, 'sin garantia', 'Horno rotativo', 599.17, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('35ef8307-3407-4d3e-9096-25d59d8670df', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '8f1d97a5-a0b6-4af6-8b90-96b26c5639e7', 'bc683588-1185-4e72-b639-61c5f1319381', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 82, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('2fa91f8d-2aa1-48b6-8c75-12fe32b71b68', '40550055', NULL, 'casiopea.torres@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('79fed7ea-e5ba-4bf7-9a47-fd92d2353e24', '2fa91f8d-2aa1-48b6-8c75-12fe32b71b68', '18a4137b-9985-4637-af12-1dbbfba2691f', '40550055', 'Casiopea', 'Torres', '964110214', 'casiopea.torres@example.com', 'Calle Principal 114', 'Pilcomayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('789721c8-976f-4abc-89b7-96551b50f5c4', '79fed7ea-e5ba-4bf7-9a47-fd92d2353e24', '193-0000014-0-26', '002-193-001930000014026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('3ada14fb-0aac-4905-9b5f-2b3dc677c895', '79fed7ea-e5ba-4bf7-9a47-fd92d2353e24', '4557********0014', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('391d178a-2f05-4a74-a619-d9c6ffb30b70', '79fed7ea-e5ba-4bf7-9a47-fd92d2353e24', 'Taller Casiopea', 'Mecanica', 50, 7400.00, 3000.00, 'Direccion Negocio 14', -12.0512, -75.2451, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('5eb7ec01-231c-4669-b4db-6b6012d7b2fa', 'EXP-2026-1014', '79fed7ea-e5ba-4bf7-9a47-fd92d2353e24', '391d178a-2f05-4a74-a619-d9c6ffb30b70', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 7500.00, NULL, 6, 'PEN', 43.92, FALSE, 'sin garantia', 'Herramienta neumatica', 1388.18, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('9a7bcd9d-33b4-4957-9383-b9667c794158', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '79fed7ea-e5ba-4bf7-9a47-fd92d2353e24', '5eb7ec01-231c-4669-b4db-6b6012d7b2fa', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 81, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('2def75cf-6ea9-4b7c-90d3-093b2d522423', '41669166', NULL, 'aristofanes.cruz@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('83d108d6-e712-47b6-9db1-05740afe4b79', '2def75cf-6ea9-4b7c-90d3-093b2d522423', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '41669166', 'Aristofanes', 'Cruz', '964110215', 'aristofanes.cruz@example.com', 'Calle Principal 115', 'Orcotuna', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('91cb16bc-ad53-4ae1-8a69-2064dd7e9313', '83d108d6-e712-47b6-9db1-05740afe4b79', '193-0000015-0-26', '002-193-001930000015026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('f3de3db2-94ea-447b-953d-41e566d834e6', '83d108d6-e712-47b6-9db1-05740afe4b79', '4557********0015', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('3955a0a3-edcf-4cb9-80c9-2956a9eb28b3', '83d108d6-e712-47b6-9db1-05740afe4b79', 'Insumos Aristofanes', 'Agropecuario', 78, 8200.00, 3300.00, 'Direccion Negocio 15', -11.976, -75.3361, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('b025e951-187e-4b18-94f9-c2df84996242', 'EXP-2026-1015', '83d108d6-e712-47b6-9db1-05740afe4b79', '3955a0a3-edcf-4cb9-80c9-2956a9eb28b3', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 9000.00, NULL, 24, 'PEN', 43.92, FALSE, 'hipotecaria', 'Capital para campana agricola', 536.05, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('28bb3de3-185e-4b02-82b6-3b605d860345', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '83d108d6-e712-47b6-9db1-05740afe4b79', 'b025e951-187e-4b18-94f9-c2df84996242', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 80, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('8067e3c8-85ee-4e1d-90a6-54ca4267ba9e', '43880088', NULL, 'calipso.mendoza@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('644860b7-150f-48c0-b2c9-a791d2b7763c', '8067e3c8-85ee-4e1d-90a6-54ca4267ba9e', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '43880088', 'Calipso', 'Mendoza', '964110216', 'calipso.mendoza@example.com', 'Calle Principal 116', 'Huancayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('b6612683-8d10-4f3a-9669-2870d04ba0ec', '644860b7-150f-48c0-b2c9-a791d2b7763c', '193-0000016-0-26', '002-193-001930000016026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('c8902c76-4ee5-43d6-aa45-4d454fee5e65', '644860b7-150f-48c0-b2c9-a791d2b7763c', '4557********0016', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('dc2fcdd6-d436-4f03-90fc-cd8f249f16c9', '644860b7-150f-48c0-b2c9-a791d2b7763c', 'Calzados Calipso', 'Calzado', 62, 7900.00, 3100.00, 'Direccion Negocio 16', -12.0689, -75.2055, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('9169325b-bf88-43f2-8771-1f044285509f', 'EXP-2026-1016', '644860b7-150f-48c0-b2c9-a791d2b7763c', 'dc2fcdd6-d436-4f03-90fc-cd8f249f16c9', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 11000.00, NULL, 18, 'PEN', 40.92, TRUE, 'hipotecaria', 'Compra de cuero y maquinaria', 793.03, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('1a814837-3d13-429f-82b4-c29550aa125f', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '644860b7-150f-48c0-b2c9-a791d2b7763c', '9169325b-bf88-43f2-8771-1f044285509f', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 79, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('0a838c49-4bd2-4b88-a910-0719ddc278ee', '40119019', NULL, 'demetrio.quispe@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('cda48724-8931-484e-accd-7f896e4fb893', '0a838c49-4bd2-4b88-a910-0719ddc278ee', '18a4137b-9985-4637-af12-1dbbfba2691f', '40119019', 'Demetrio', 'Quispe', '964110217', 'demetrio.quispe@example.com', 'Calle Principal 117', 'Jauja', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('a14c9c6b-0aeb-4a6e-84fd-657ed4b0f3a4', 'cda48724-8931-484e-accd-7f896e4fb893', '193-0000017-0-26', '002-193-001930000017026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('74e9ba8b-3a5b-4983-9dcd-5c20d2229109', 'cda48724-8931-484e-accd-7f896e4fb893', '4557********0017', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('8c207009-52ce-4c11-bcdf-0c7d8e4557f9', 'cda48724-8931-484e-accd-7f896e4fb893', 'Mayorista Demetrio', 'Comercio', 90, 11500.00, 4700.00, 'Direccion Negocio 17', -11.7752, -75.4995, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('074b31b9-8d7a-44f6-a1a3-11d3c15edc9c', 'EXP-2026-1017', 'cda48724-8931-484e-accd-7f896e4fb893', '8c207009-52ce-4c11-bcdf-0c7d8e4557f9', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 13500.00, NULL, 12, 'PEN', 43.92, FALSE, 'hipotecaria', 'Reposicion de inventario mayorista', 1362.77, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('90c43cd2-5985-4fca-8194-79080576bbd7', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'cda48724-8931-484e-accd-7f896e4fb893', '074b31b9-8d7a-44f6-a1a3-11d3c15edc9c', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 78, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('d80c21ee-8c2e-41ca-a9e5-5299c3c458aa', '41226126', NULL, 'antigona.flores@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('993c6cdc-e4b8-4c6e-b3fe-afc3b994cdd2', 'd80c21ee-8c2e-41ca-a9e5-5299c3c458aa', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '41226126', 'Antigona', 'Flores', '964110218', 'antigona.flores@example.com', 'Calle Principal 118', 'Concepcion', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('05ef4995-84ba-4065-ab39-b77144472b8c', '993c6cdc-e4b8-4c6e-b3fe-afc3b994cdd2', '193-0000018-0-26', '002-193-001930000018026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('5b4455f6-6280-413f-aff4-bb6db19f39d7', '993c6cdc-e4b8-4c6e-b3fe-afc3b994cdd2', '4557********0018', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('1aaf6f8f-9b92-4073-975c-0819bd2378c4', '993c6cdc-e4b8-4c6e-b3fe-afc3b994cdd2', 'Recreo Antigona', 'Restaurante', 70, 9200.00, 3900.00, 'Direccion Negocio 18', -11.9201, -75.311, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('bdaa7fd9-5301-48f7-9629-7b2017b88ee1', 'EXP-2026-1018', '993c6cdc-e4b8-4c6e-b3fe-afc3b994cdd2', '1aaf6f8f-9b92-4073-975c-0819bd2378c4', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 16000.00, NULL, 36, 'PEN', 43.92, FALSE, 'hipotecaria', 'Ampliacion y remodelacion', 741.70, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('c1b70919-1a39-4200-8da8-c82f25604dab', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '993c6cdc-e4b8-4c6e-b3fe-afc3b994cdd2', 'bdaa7fd9-5301-48f7-9629-7b2017b88ee1', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 77, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('d0573fd7-856b-48e7-9ce2-087be23ed408', '43339033', NULL, 'pitagoras.rojas@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('569449c3-320c-45e7-b888-1fb48cae631a', 'd0573fd7-856b-48e7-9ce2-087be23ed408', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '43339033', 'Pitagoras', 'Rojas', '964110219', 'pitagoras.rojas@example.com', 'Calle Principal 119', 'El Tambo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('d350c385-2193-43bd-b58e-086dd6269ddf', '569449c3-320c-45e7-b888-1fb48cae631a', '193-0000019-0-26', '002-193-001930000019026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('554e8b05-134a-4d9f-b16a-b157f780051b', '569449c3-320c-45e7-b888-1fb48cae631a', '4557********0019', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('d04943e3-d8ec-4143-afe9-db9a97ba447e', '569449c3-320c-45e7-b888-1fb48cae631a', 'Ferreteria Pitagoras', 'Ferreteria', 100, 13000.00, 5200.00, 'Direccion Negocio 19', -12.0599, -75.2143, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('69ba3799-a943-4cf3-bffd-c0b10cf19373', 'EXP-2026-1019', '569449c3-320c-45e7-b888-1fb48cae631a', 'd04943e3-d8ec-4143-afe9-db9a97ba447e', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 17000.00, NULL, 24, 'PEN', 40.92, TRUE, 'hipotecaria', 'Compra de stock estructural', 993.00, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('1b07b361-35fe-4edc-8556-8aa9d0e0888a', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '569449c3-320c-45e7-b888-1fb48cae631a', '69ba3799-a943-4cf3-bffd-c0b10cf19373', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 76, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('e2e68c62-e9b6-41f8-b344-88862db98e9d', '40556056', NULL, 'berenice.apaza@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('6bbdcd8c-4291-455e-a7cb-8e332e6443ea', 'e2e68c62-e9b6-41f8-b344-88862db98e9d', '18a4137b-9985-4637-af12-1dbbfba2691f', '40556056', 'Berenice', 'Apaza', '964110220', 'berenice.apaza@example.com', 'Calle Principal 120', 'San Jeronimo de Tunan', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('44be28ce-db36-4114-abd7-eeda659c8856', '6bbdcd8c-4291-455e-a7cb-8e332e6443ea', '193-0000020-0-26', '002-193-001930000020026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('b8f32b60-04c2-4016-8219-bbaf38b067ad', '6bbdcd8c-4291-455e-a7cb-8e332e6443ea', '4557********0020', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('1bbf400a-c5d7-4b54-9e9d-c28ef49475be', '6bbdcd8c-4291-455e-a7cb-8e332e6443ea', 'Tejidos Berenice', 'Textil', 46, 8600.00, 3500.00, 'Direccion Negocio 20', -11.9871, -75.2899, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('5174e796-ea8c-4990-b791-85618e76ca8c', 'EXP-2026-1020', '6bbdcd8c-4291-455e-a7cb-8e332e6443ea', '1bbf400a-c5d7-4b54-9e9d-c28ef49475be', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 19000.00, NULL, 18, 'PEN', 43.92, FALSE, 'hipotecaria', 'Maquinaria de tejido plano', 1390.89, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('b0687929-ae5a-449c-a4a7-9fcfa57da78b', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '6bbdcd8c-4291-455e-a7cb-8e332e6443ea', '5174e796-ea8c-4990-b791-85618e76ca8c', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 75, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('0c516a53-bd93-4f87-9e00-7e27820e0440', '43889089', NULL, 'anaxagoras.huaman@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('f4058201-216d-4046-9482-2a49ccc926cb', '0c516a53-bd93-4f87-9e00-7e27820e0440', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '43889089', 'Anaxagoras', 'Huaman', '964110221', 'anaxagoras.huaman@example.com', 'Calle Principal 121', 'Huancayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('838bc77e-5f24-4082-838f-ba0cb95d967b', 'f4058201-216d-4046-9482-2a49ccc926cb', '193-0000021-0-26', '002-193-001930000021026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('fd2a4977-33db-4bc9-9189-54e284478e6c', 'f4058201-216d-4046-9482-2a49ccc926cb', '4557********0021', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('72bacf06-02b9-4998-8c76-ebcfb1db2fa4', 'f4058201-216d-4046-9482-2a49ccc926cb', 'Carga Anaxagoras', 'Transporte', 84, 14000.00, 5800.00, 'Direccion Negocio 21', -12.0644, -75.2088, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('93c26830-b134-48fc-b7b8-2796935a53dc', 'EXP-2026-1021', 'f4058201-216d-4046-9482-2a49ccc926cb', '72bacf06-02b9-4998-8c76-ebcfb1db2fa4', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 22000.00, NULL, 36, 'PEN', 43.92, FALSE, 'vehicular', 'Cuota inicial de camion', 1019.83, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('8617601a-6207-43ca-8d18-15d4ed57c60c', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'f4058201-216d-4046-9482-2a49ccc926cb', '93c26830-b134-48fc-b7b8-2796935a53dc', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 74, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('6798b65f-6756-4a42-acef-cfdc360ae2d6', '41003001', NULL, 'climene.vargas@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('25120e90-5408-4d4d-8949-931d67949ac4', '6798b65f-6756-4a42-acef-cfdc360ae2d6', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '41003001', 'Climene', 'Vargas', '964110222', 'climene.vargas@example.com', 'Calle Principal 122', 'Sapallanga', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('9f343b30-8492-406a-92b5-cd6730e363c1', '25120e90-5408-4d4d-8949-931d67949ac4', '193-0000022-0-26', '002-193-001930000022026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('0fabf863-3136-48d1-9843-ad76a3c59ca5', '25120e90-5408-4d4d-8949-931d67949ac4', '4557********0022', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('8a6a2c08-0f1f-4b53-a192-c6e68a3f5019', '25120e90-5408-4d4d-8949-931d67949ac4', 'Avicola Climene', 'Avicola', 76, 13500.00, 5500.00, 'Direccion Negocio 22', -12.156, -75.179, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('282d5bcc-9980-4d99-8327-ee455137910c', 'EXP-2026-1022', '25120e90-5408-4d4d-8949-931d67949ac4', '8a6a2c08-0f1f-4b53-a192-c6e68a3f5019', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 24000.00, NULL, 24, 'PEN', 40.92, TRUE, 'hipotecaria', 'Equipamiento de planta', 1401.88, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('ec818cfa-d7b4-4090-9bde-3da2209827ad', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '25120e90-5408-4d4d-8949-931d67949ac4', '282d5bcc-9980-4d99-8327-ee455137910c', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 73, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('44c67a57-1b40-4b8f-8cfc-74b7968f5950', '40115011', NULL, 'epaminondas.soto@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('d543b103-6d87-4ab7-9ac0-3a6e2d3d5dac', '44c67a57-1b40-4b8f-8cfc-74b7968f5950', '18a4137b-9985-4637-af12-1dbbfba2691f', '40115011', 'Epaminondas', 'Soto', '964110223', 'epaminondas.soto@example.com', 'Calle Principal 123', 'Pucara', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('587f42a6-7d09-490f-806c-c40aab8234a2', 'd543b103-6d87-4ab7-9ac0-3a6e2d3d5dac', '193-0000023-0-26', '002-193-001930000023026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('df09afdb-439c-40f1-a5a5-68ae51684535', 'd543b103-6d87-4ab7-9ac0-3a6e2d3d5dac', '4557********0023', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('ea83598f-5cbb-42f7-9754-029689ff64d0', 'd543b103-6d87-4ab7-9ac0-3a6e2d3d5dac', 'Bodega Epaminondas', 'Bodega', 28, 2600.00, 1000.00, 'Direccion Negocio 23', -12.1701, -75.1611, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('1ba54d50-0ecc-43ec-9e6d-4f6ed502e905', 'EXP-2026-1023', 'd543b103-6d87-4ab7-9ac0-3a6e2d3d5dac', 'ea83598f-5cbb-42f7-9754-029689ff64d0', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 1500.00, NULL, 6, 'PEN', 43.92, FALSE, 'sin garantia', 'Compra de vitrinas', 277.64, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('9e26a1e4-73a8-4f3d-a20d-6e012292b621', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'd543b103-6d87-4ab7-9ac0-3a6e2d3d5dac', '1ba54d50-0ecc-43ec-9e6d-4f6ed502e905', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 72, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('0854eb44-c32e-4645-b50c-164eeb1ee35b', '41336036', NULL, 'lisistrata.ramos@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('56b33b6c-edbb-45e1-aac6-082cb3bfa535', '0854eb44-c32e-4645-b50c-164eeb1ee35b', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '41336036', 'Lisistrata', 'Ramos', '964110224', 'lisistrata.ramos@example.com', 'Calle Principal 124', 'Huancayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('c3817511-e83d-4799-9aba-3cfe97e9527c', '56b33b6c-edbb-45e1-aac6-082cb3bfa535', '193-0000024-0-26', '002-193-001930000024026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('521d11c7-04d3-4a3a-99e8-5dcaaa4bb537', '56b33b6c-edbb-45e1-aac6-082cb3bfa535', '4557********0024', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('938d62a3-3869-43f1-a578-00a33ed03daf', '56b33b6c-edbb-45e1-aac6-082cb3bfa535', 'Variedades Lisistrata', 'Comercio', 52, 4100.00, 1700.00, 'Direccion Negocio 24', -12.0633, -75.2071, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('05553aee-5ea2-4266-aa7e-67829b52cc70', 'EXP-2026-1024', '56b33b6c-edbb-45e1-aac6-082cb3bfa535', '938d62a3-3869-43f1-a578-00a33ed03daf', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 3500.00, NULL, 12, 'PEN', 43.92, FALSE, 'sin garantia', 'Capital de trabajo', 353.31, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('009325d6-a93e-42f2-869d-e8143e22f70e', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '56b33b6c-edbb-45e1-aac6-082cb3bfa535', '05553aee-5ea2-4266-aa7e-67829b52cc70', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 71, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('db655064-73ae-41ee-b09a-6279d9ea1b5b', '41552052', NULL, 'filoctetes.cruz@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('5f001cd0-b813-49d1-9ff5-1b0ff2e8d737', 'db655064-73ae-41ee-b09a-6279d9ea1b5b', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '41552052', 'Filoctetes', 'Cruz', '964110225', 'filoctetes.cruz@example.com', 'Calle Principal 125', 'Chilca', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('76342bf2-0455-455d-9d57-4ff3b6389c3b', '5f001cd0-b813-49d1-9ff5-1b0ff2e8d737', '193-0000025-0-26', '002-193-001930000025026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('83aa5249-1939-4191-a15c-22d34c080411', '5f001cd0-b813-49d1-9ff5-1b0ff2e8d737', '4557********0025', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('1c9bb5f8-9090-458d-87c4-d58c8be62039', '5f001cd0-b813-49d1-9ff5-1b0ff2e8d737', 'Cevicheria Filoctetes', 'Restaurante', 18, 3800.00, 2200.00, 'Direccion Negocio 25', -12.093, -75.209, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('a2a80292-fe6e-4313-a994-9d07b2900c2d', 'EXP-2026-1025', '5f001cd0-b813-49d1-9ff5-1b0ff2e8d737', '1c9bb5f8-9090-458d-87c4-d58c8be62039', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 11000.00, NULL, 18, 'PEN', 40.92, TRUE, 'sin garantia', 'Ampliacion de local nuevo', 793.03, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('7b29bf45-2bee-4376-96a8-f3b183c6894c', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '5f001cd0-b813-49d1-9ff5-1b0ff2e8d737', 'a2a80292-fe6e-4313-a994-9d07b2900c2d', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 70, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('0311b2e9-4505-48d6-8920-6901f02f510b', '41888088', NULL, 'calirroe.mendoza@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('2d275809-7d74-4ce8-b26d-27b3994fb2c2', '0311b2e9-4505-48d6-8920-6901f02f510b', '18a4137b-9985-4637-af12-1dbbfba2691f', '41888088', 'Calirroe', 'Mendoza', '964110226', 'calirroe.mendoza@example.com', 'Calle Principal 126', 'El Tambo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('1804dec1-9893-4bf2-9cda-efafc1898f67', '2d275809-7d74-4ce8-b26d-27b3994fb2c2', '193-0000026-0-26', '002-193-001930000026026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('e3edd655-35a1-48bc-b976-d36db8598580', '2d275809-7d74-4ce8-b26d-27b3994fb2c2', '4557********0026', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('6fe4ce72-2ab8-40ec-8046-8cf8fa9781f1', '2d275809-7d74-4ce8-b26d-27b3994fb2c2', 'Calzados Calirroe', 'Calzado', 34, 5000.00, 2600.00, 'Direccion Negocio 26', -12.0588, -75.2129, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('77416615-14be-4298-b35c-5d56d793db33', 'EXP-2026-1026', '2d275809-7d74-4ce8-b26d-27b3994fb2c2', '6fe4ce72-2ab8-40ec-8046-8cf8fa9781f1', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 16000.00, NULL, 24, 'PEN', 43.92, FALSE, 'hipotecaria', 'Maquinaria de mayor capacidad', 952.98, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('56800da9-d796-4085-bf99-8983125ecab3', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '2d275809-7d74-4ce8-b26d-27b3994fb2c2', '77416615-14be-4298-b35c-5d56d793db33', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 69, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('4c42c755-279d-4224-a3ec-1a73f6a6f4ca', '42220022', NULL, 'tucidides.quispe@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('ae4978ec-8b5a-4d94-8ab9-4f39f780af5e', '4c42c755-279d-4224-a3ec-1a73f6a6f4ca', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '42220022', 'Tucidides', 'Quispe', '964110227', 'tucidides.quispe@example.com', 'Calle Principal 127', 'Concepcion', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('a2108f38-0c2e-4bff-9938-aa1b5bbe3953', 'ae4978ec-8b5a-4d94-8ab9-4f39f780af5e', '193-0000027-0-26', '002-193-001930000027026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('65cc3212-ea9a-4a2e-a724-7055232adc0e', 'ae4978ec-8b5a-4d94-8ab9-4f39f780af5e', '4557********0027', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('4fa09de1-2bca-4834-8257-a0f148c4db4b', 'ae4978ec-8b5a-4d94-8ab9-4f39f780af5e', 'Ferreteria Tucidides', 'Ferreteria', 40, 6200.00, 2900.00, 'Direccion Negocio 27', -11.9176, -75.3155, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('eb0aa1ff-7fcf-42fe-a783-62d2b86e47ed', 'EXP-2026-1027', 'ae4978ec-8b5a-4d94-8ab9-4f39f780af5e', '4fa09de1-2bca-4834-8257-a0f148c4db4b', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 20000.00, NULL, 24, 'PEN', 40.92, TRUE, 'hipotecaria', 'Compra de stock y montacarga', 1168.23, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('feaee7c4-ade5-41ad-b7a0-b92cbaafb308', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'ae4978ec-8b5a-4d94-8ab9-4f39f780af5e', 'eb0aa1ff-7fcf-42fe-a783-62d2b86e47ed', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 68, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('d83e0e53-9279-4bc5-b90f-038121a7953c', '43337037', NULL, 'aquiles.mamani@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('aabc13db-ec07-462d-a6ce-6761ffd446b6', 'd83e0e53-9279-4bc5-b90f-038121a7953c', 'ee0e3a01-18e7-4274-91a7-8cb9067454bb', '43337037', 'Aquiles', 'Mamani', '964110228', 'aquiles.mamani@example.com', 'Calle Principal 128', 'Huancayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('5cab22a9-c32d-4029-a1a5-d5cb71fa5d21', 'aabc13db-ec07-462d-a6ce-6761ffd446b6', '193-0000028-0-26', '002-193-001930000028026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('6f81325f-5b96-445f-9d0f-251a0643333d', 'aabc13db-ec07-462d-a6ce-6761ffd446b6', '4557********0028', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('d30bba02-7902-495e-bd99-7600a7d7acbf', 'aabc13db-ec07-462d-a6ce-6761ffd446b6', 'Comercial Aquiles', 'Comercio', 60, 9000.00, 3600.00, 'Direccion Negocio 28', -12.0657, -75.2099, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('10c239f7-c03c-4d85-baab-87ce1f9951df', 'EXP-2026-1028', 'aabc13db-ec07-462d-a6ce-6761ffd446b6', 'd30bba02-7902-495e-bd99-7600a7d7acbf', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 15000.00, NULL, 24, 'PEN', 43.92, FALSE, 'hipotecaria', 'Capital de trabajo', 893.42, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('46b50919-4c43-45ee-b9dd-799f016ed407', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', 'aabc13db-ec07-462d-a6ce-6761ffd446b6', '10c239f7-c03c-4d85-baab-87ce1f9951df', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 67, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('4a30af8c-8811-4d3f-ace3-dbb1ba169137', '41884084', NULL, 'medea.apaza@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('0a0c1df7-890c-46a1-a5c9-67975af6db4a', '4a30af8c-8811-4d3f-ace3-dbb1ba169137', '18a4137b-9985-4637-af12-1dbbfba2691f', '41884084', 'Medea', 'Apaza', '964110229', 'medea.apaza@example.com', 'Calle Principal 129', 'Pilcomayo', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('3d931ab8-a63a-43c6-9cb3-f395c4fabd6c', '0a0c1df7-890c-46a1-a5c9-67975af6db4a', '193-0000029-0-26', '002-193-001930000029026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('c34132bf-1d0b-4ff2-87f8-04b68d0ba513', '0a0c1df7-890c-46a1-a5c9-67975af6db4a', '4557********0029', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('b3867aac-d343-436b-9940-f88120dcca7d', '0a0c1df7-890c-46a1-a5c9-67975af6db4a', 'Bodega Medea', 'Bodega', 22, 1800.00, 1100.00, 'Direccion Negocio 29', -12.0489, -75.247, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('4136f5f2-9574-4ec4-abe0-83172b292e1a', 'EXP-2026-1029', '0a0c1df7-890c-46a1-a5c9-67975af6db4a', 'b3867aac-d343-436b-9940-f88120dcca7d', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 14000.00, NULL, 18, 'PEN', 43.92, FALSE, 'sin garantia', 'Compra de camioneta para reparto', 1024.87, 'ENVIADO', 'REVISAR', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('c7ff6c86-1110-4c81-a12a-7f7ea1480829', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '0a0c1df7-890c-46a1-a5c9-67975af6db4a', '4136f5f2-9574-4ec4-abe0-83172b292e1a', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 66, 'PENDIENTE');
INSERT INTO usuarios (id_usuario, documento, codigo_empleado, correo, password_hash, rol, estado) VALUES ('4f89e37a-aed2-40fe-8e89-22057ab07ee3', '43334034', NULL, 'esquines.rojas@example.com', '$2b$12$Qw9PXVlpzQriDEHqgKloDuEWOzRXsnn75iw0VEDW6ZRJQTfyY.97G', 'CLIENTE', 'ACTIVO');
INSERT INTO clientes (id_cliente, id_usuario, id_agencia, documento, nombres, apellidos, telefono, correo, direccion, distrito, provincia, departamento, fecha_nacimiento, estado_civil, ocupacion, tipo_cliente, estado) VALUES ('20b4b925-3567-4ce9-ad0d-9cd8985bcd4a', '4f89e37a-aed2-40fe-8e89-22057ab07ee3', '0e9beb76-5f1b-42c3-8c6a-1f7a6b992265', '43334034', 'Esquines', 'Rojas', '964110230', 'esquines.rojas@example.com', 'Calle Principal 130', 'Jauja', 'Huancayo', 'Junin', '1985-05-12', 'SOLTERO', 'Microempresario', 'NUEVO', 'ACTIVO');
INSERT INTO cuentas_ahorro (id_cuenta, id_cliente, numero_cuenta, cci, moneda, saldo_disponible, saldo_contable, estado) VALUES ('84246024-a358-4094-b4b8-5db2e2db8c1e', '20b4b925-3567-4ce9-ad0d-9cd8985bcd4a', '193-0000030-0-26', '002-193-001930000030026', 'PEN', 2500.00, 2500.00, 'ACTIVO');
INSERT INTO tarjetas (id_tarjeta, id_cliente, numero_enmascarado, tipo_tarjeta, marca, estado, fecha_vencimiento) VALUES ('ba535ec1-6fb5-477a-bab4-ed82dd1d7108', '20b4b925-3567-4ce9-ad0d-9cd8985bcd4a', '4557********0030', 'DEBITO', 'VISA', 'ACTIVO', '2028-12-31');
INSERT INTO negocios_cliente (id_negocio, id_cliente, nombre_comercial, giro_negocio, antiguedad_meses, ingreso_mensual, gasto_mensual, direccion_negocio, lat_negocio, lng_negocio, estado) VALUES ('86084a4b-53de-4d95-bca5-31b66762b1bd', '20b4b925-3567-4ce9-ad0d-9cd8985bcd4a', 'Fletes Esquines', 'Transporte', 30, 7000.00, 3200.00, 'Direccion Negocio 30', -11.774, -75.501, 'ACTIVO');
INSERT INTO solicitudes_credito (id_solicitud, numero_expediente, id_cliente, id_negocio, id_asesor, id_producto_credito, canal_origen, monto_solicitado, monto_aprobado, plazo_meses, moneda, tea_referencial, con_seguro_desgravamen, garantia, destino_credito, cuota_estimada, estado, resultado_preevaluacion, puntaje_preevaluacion, resultado_buro, created_at, updated_at) VALUES ('7d3c67b4-f5cb-40c4-beee-1cec2ea42f8b', 'EXP-2026-1030', '20b4b925-3567-4ce9-ad0d-9cd8985bcd4a', '86084a4b-53de-4d95-bca5-31b66762b1bd', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '04780e00-eb2a-417c-bf59-56c0703c31f7', 'CLIENTE', 30000.00, NULL, 24, 'PEN', 43.92, FALSE, 'vehicular', 'Compra de unidad de transporte', 1786.83, 'ENVIADO', 'APTO', 85, 'NORMAL', now(), now());
INSERT INTO cartera_diaria (id_cartera, id_asesor, id_cliente, id_solicitud, fecha_asignacion, tipo_gestion, prioridad, score_prioridad, estado_visita) VALUES ('c2860c9f-3f82-48db-98bc-a711d1cadd8b', 'dde4e1ae-9d9f-4acd-b522-143f6f59f68e', '20b4b925-3567-4ce9-ad0d-9cd8985bcd4a', '7d3c67b4-f5cb-40c4-beee-1cec2ea42f8b', CURRENT_DATE, 'NUEVA_SOLICITUD', 'ALTA', 65, 'PENDIENTE');

-- ==========================================
-- FILE: 11_views_dashboard.sql
-- ==========================================
-- Vista resumen de solicitudes de credito para el Supervisor
CREATE OR REPLACE VIEW v_resumen_solicitudes AS
SELECT 
    estado,
    COUNT(*) as total_solicitudes,
    SUM(monto_solicitado) as monto_total_solicitado,
    SUM(COALESCE(monto_aprobado, 0)) as monto_total_aprobado
FROM solicitudes_credito
GROUP BY estado;

-- Vista cartera de asesores para monitoreo de ruta y visitas
CREATE OR REPLACE VIEW v_cartera_asesor AS
SELECT 
    c.id_cartera,
    c.id_asesor,
    a.nombres AS asesor_nombres,
    a.apellidos AS asesor_apellidos,
    c.id_cliente,
    cli.nombres AS cliente_nombres,
    cli.apellidos AS cliente_apellidos,
    c.tipo_gestion,
    c.prioridad,
    c.estado_visita,
    c.timestamp_visita
FROM cartera_diaria c
JOIN asesores a ON c.id_asesor = a.id_asesor
JOIN clientes cli ON c.id_cliente = cli.id_cliente;

-- Vista de creditos y saldos de clientes
CREATE OR REPLACE VIEW v_creditos_vigentes AS
SELECT 
    cr.id_credito,
    cr.numero_credito,
    cr.producto,
    cr.monto_desembolsado,
    cr.saldo_capital,
    cr.plazo_meses,
    cr.fecha_desembolso,
    cr.estado AS estado_credito,
    cli.id_cliente,
    cli.documento,
    cli.nombres AS cliente_nombres,
    cli.apellidos AS cliente_apellidos
FROM cr_creditos cr
JOIN clientes cli ON cr.id_cliente = cli.id_cliente;


