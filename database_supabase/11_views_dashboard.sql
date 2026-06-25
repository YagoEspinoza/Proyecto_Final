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
