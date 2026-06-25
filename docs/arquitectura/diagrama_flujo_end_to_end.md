# Diagrama de Flujo End-to-End — SIP Mobile Core 360

Este documento contiene la descripción y el diagrama de secuencia del flujo obligatorio del sistema desde la solicitud hasta el desembolso y su visualización.

```mermaid
sequenceDiagram
    autonumber
    actor Cliente
    actor Asesor
    actor Supervisor
    participant API as FastAPI Core
    participant DB as PostgreSQL DB

    Note over Cliente, DB: Fase 1: Originación desde el Cliente
    Cliente->>API: POST /auth/login (DNI + Clave)
    API-->>Cliente: Retorna JWT Token & Rol CLIENTE
    Cliente->>API: POST /cliente/solicitudes (S/ 1,000, 12 meses)
    API->>DB: Registra Solicitud (estado = 'ENVIADO') y asigna Asesor A001
    API->>DB: Inserta en sync_outbox (Evento = 'NUEVA_SOLICITUD')
    API-->>Cliente: Retorna Solicitud Creada (EXP-2026-XXXXXX)

    Note over Asesor, DB: Fase 2: Evaluación en Campo (Offline-First)
    Asesor->>API: POST /auth/login (Código Empleado + Clave)
    API-->>Asesor: Retorna JWT Token & Rol ASESOR
    Asesor->>API: GET /fventas/cartera/hoy
    API->>DB: Consulta cartera asignada
    DB-->>API: Datos de Cartera
    API-->>Asesor: Lista de tareas (incluye solicitud del Cliente)
    
    Note right of Asesor: Registra Visita de campo (GPS)
    Asesor->>API: POST /fventas/visitas (id_cartera, coordenadas GPS)
    API->>DB: Registra visita e inserta en visitas_cliente
    API-->>Asesor: Visita Exitosa (cambia local_cartera a COMPLETADO)

    Note right of Asesor: Preevaluación y Buró Simulado
    Asesor->>API: POST /fventas/solicitudes/{id}/preevaluar
    API->>DB: Calcula capacidad de pago del cliente
    API-->>Asesor: Retorna APTO (Score 85, ratio <= 40%)
    Asesor->>API: POST /fventas/solicitudes/{id}/buro
    API->>DB: Consulta inhabilitados y califica por ultimo digito DNI
    API-->>Asesor: Retorna NORMAL/APROBADO en buró
    
    Note right of Asesor: Carga de Documentos y Firma Digital
    Asesor->>API: POST /fventas/solicitudes/{id}/documentos (Sustentos)
    API->>DB: Guarda archivos en uploads y metadata en DB
    Asesor->>API: POST /fventas/solicitudes/{id}/firma (Base64)
    API->>DB: Asocia firma al expediente
    Asesor->>API: POST /fventas/solicitudes/{id}/enviar-comite
    API->>DB: Cambia estado de solicitud a 'RECIBIDO_COMITE'
    API-->>Asesor: Confirmación de envío

    Note over Supervisor, DB: Fase 3: Comité, Aprobación y Desembolso
    Supervisor->>API: POST /auth/login (SUP001 + Clave)
    API-->>Supervisor: Retorna JWT Token & Rol SUPERVISOR
    Supervisor->>API: GET /comite/solicitudes
    API-->>Supervisor: Lista de expedientes en bandeja
    Supervisor->>API: POST /comite/solicitudes/{id}/aprobar (Monto = S/ 1,000)
    API->>DB: Cambia estado a 'APROBADO' y fija monto_aprobado
    Supervisor->>API: POST /comite/solicitudes/{id}/desembolsar
    
    critical Desembolso en Core Financiero
        API->>DB: Actualiza solicitud a 'DESEMBOLSADO'
        API->>DB: Actualiza saldos de cuenta_ahorro (+ S/ 1,000)
        API->>DB: Inserta registro en cr_creditos
        API->>DB: Genera cuotas en cr_cronograma_pagos (Amortización Francesa)
        API->>DB: Registra movimiento DESEMBOLSO_CREDITO en cr_movimientos
        API->>DB: Inserta notificación en notificaciones
        API->>DB: Inserta en sync_outbox (Evento = 'DESEMBOLSO_COMPLETO') y sync_log
    end
    API-->>Supervisor: Desembolso Exitoso

    Note over Cliente, DB: Fase 4: Confirmación del Cliente
    Cliente->>API: GET /cliente/creditos
    API-->>Cliente: Retorna Crédito Activo
    Cliente->>API: GET /cliente/creditos/{id}/cronograma
    API-->>Cliente: Retorna cuotas amortizadas del cronograma
    Cliente->>API: GET /cliente/movimientos
    API-->>Cliente: Muestra movimiento por S/ 1,000 (DESEMBOLSO_CREDITO)
