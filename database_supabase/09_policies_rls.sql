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
