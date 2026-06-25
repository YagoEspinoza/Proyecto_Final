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
