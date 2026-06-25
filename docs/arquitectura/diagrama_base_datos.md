# Diagrama de Base de Datos — SIP Mobile Core 360

Este documento describe la estructura relacional de la base de datos `sip_db` implementada en PostgreSQL.

## Estructura Relacional (Mermaid ERD)

```mermaid
erDiagram
    usuarios ||--o| clientes : "id_usuario"
    usuarios ||--o| asesores : "id_usuario"
    agencias ||--o{ clientes : "id_agencia"
    agencias ||--o{ asesores : "id_agencia"
    
    clientes ||--o{ negocios_cliente : "id_cliente"
    clientes ||--o{ cuentas_ahorro : "id_cliente"
    clientes ||--o{ tarjetas : "id_cliente"
    
    clientes ||--o{ solicitudes_credito : "id_cliente"
    negocios_cliente ||--o{ solicitudes_credito : "id_negocio"
    asesores ||--o{ solicitudes_credito : "id_asesor"
    productos_credito ||--o{ solicitudes_credito : "id_producto_credito"
    
    solicitudes_credito ||--o{ consultas_buro : "id_solicitud"
    solicitudes_credito ||--o{ solicitudes_documentos : "id_solicitud"
    solicitudes_credito ||--o| cr_creditos : "id_solicitud"
    
    cr_creditos ||--o{ cr_cronograma_pagos : "id_credito"
    cr_creditos ||--o{ cr_movimientos : "id_credito"
    cuentas_ahorro ||--o{ cr_movimientos : "id_cuenta"
    
    asesores ||--o{ cartera_diaria : "id_asesor"
    clientes ||--o{ cartera_diaria : "id_cliente"
    solicitudes_credito ||--o{ cartera_diaria : "id_solicitud"
    cartera_diaria ||--o{ visitas_cliente : "id_cartera"

    usuarios {
        uuid id_usuario PK
        varchar documento UNIQUE
        varchar codigo_empleado UNIQUE
        varchar correo
        text password_hash
        varchar rol
        varchar estado
        integer intentos_fallidos
        timestamptz bloqueado_hasta
        timestamptz ultimo_login
    }

    clientes {
        uuid id_cliente PK
        uuid id_usuario FK
        uuid id_agencia FK
        varchar documento UNIQUE
        varchar nombres
        varchar apellidos
        varchar telefono
        varchar correo
        text direccion
        varchar distrito
        varchar provincia
        varchar departamento
        date fecha_nacimiento
        varchar estado_civil
        varchar ocupacion
        varchar tipo_cliente
        varchar estado
    }

    solicitudes_credito {
        uuid id_solicitud PK
        varchar numero_expediente UNIQUE
        uuid id_cliente FK
        uuid id_negocio FK
        uuid id_asesor FK
        uuid id_producto_credito FK
        varchar canal_origen
        numeric monto_solicitado
        numeric monto_aprobado
        integer plazo_meses
        varchar moneda
        numeric tea_referencial
        boolean con_seguro_desgravamen
        varchar garantia
        text destino_credito
        numeric cuota_estimada
        varchar estado
        varchar resultado_preevaluacion
        integer puntaje_preevaluacion
        varchar resultado_buro
        text motivo_rechazo
        text condicion_adicional
        text firma_cliente_base64
        numeric lat_captura
        numeric lng_captura
        boolean pendiente_sync
    }

    cr_creditos {
        uuid id_credito PK
        uuid id_solicitud FK
        uuid id_cliente FK
        varchar numero_credito UNIQUE
        varchar producto
        numeric monto_desembolsado
        numeric saldo_capital
        integer plazo_meses
        numeric tea
        numeric tem
        numeric cuota_mensual
        date fecha_desembolso
        integer dia_pago
        varchar estado
    }

    cr_cronograma_pagos {
        uuid id_cuota PK
        uuid id_credito FK
        integer numero_cuota
        date fecha_pago
        numeric monto_cuota
        numeric capital
        numeric interes
        numeric saldo
        varchar estado
        date fecha_pago_real
        numeric monto_pagado
    }
```

## Características Técnicas de la DB
1. **Claves Primarias y Foráneas:** Todos los IDs clave son identificadores únicos universales (UUIDv4) autogenerados con la función `gen_random_uuid()` para facilitar la sincronización bidireccional y evitar colisiones de base de datos distribuidas.
2. **Políticas de RLS (Row Level Security):** RLS está activo a nivel de tabla en Supabase para asegurar que los usuarios con rol de cliente solo puedan acceder a su información y que los asesores solo modifiquen sus carteras y solicitudes asociadas.
3. **Cálculos Decimales:** Montos, saldos, intereses, capitales y tasas se manejan con tipos numéricos exactos de punto fijo (ej. `NUMERIC(12,2)` y `NUMERIC(5,2)`) para evitar los errores de redondeo de punto flotante de IEEE 754.
