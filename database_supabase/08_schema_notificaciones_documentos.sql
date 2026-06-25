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
