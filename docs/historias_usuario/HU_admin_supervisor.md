# Historia de Usuario: Supervisor y Administrador — SIP Mobile Core 360

## Detalle de la Historia de Usuario

**COMO** Supervisor de Créditos / Administrador del Ecosistema SIP
**QUIERO** Evaluar solicitudes en el comité, aprobar o rechazar expedientes, ejecutar desembolsos automáticos y dar mantenimiento a los usuarios y productos del sistema.
**PARA** Velar por el cumplimiento de las políticas de riesgo de la institución y supervisar la sincronización del núcleo.

---

## Criterios de Aceptación

### Escenario 1: Bandeja del Comité
- **Dado** que el supervisor inicia sesión (ej. `SUP001` / `123456`).
- **Cuando** accede a la sección de comité.
- **Entonces** visualiza todos los expedientes en estados transicionales (`ENVIADO`, `RECIBIDO_COMITE`, `EN_EVALUACION`).

### Escenario 2: Aprobación y Condicionamiento de Solicitudes
- **Dado** que el supervisor evalúa una solicitud y revisa el expediente (incluyendo la firma del cliente, la preevaluación y la consulta de buró).
- **Cuando** pulsa "APROBAR", puede ingresar opcionalmente un monto aprobado (por defecto el monto solicitado) y el estado de la solicitud cambia a `APROBADO`.
- **Cuando** pulsa "CONDICIONAR", ingresa una condición en texto y el estado de la solicitud cambia a `CONDICIONADO`.

### Escenario 3: Desembolso Automático y Generación de Cronogramas
- **Dado** que una solicitud de crédito se encuentra en estado `APROBADO` o `CONDICIONADO`.
- **Cuando** el supervisor pulsa "DESEMBOLSAR CRÉDITO".
- **Entonces** FastAPI realiza una transacción ACID que:
  1. Cambia el estado de la solicitud a `DESEMBOLSADO`.
  2. Credita el monto aprobado al saldo disponible de la cuenta de ahorros del cliente.
  3. Crea un registro en `cr_creditos` con su número de crédito único.
  4. Genera el calendario de pagos (`cr_cronograma_pagos`) utilizando la fórmula francesa, asegurando que la última cuota ajuste el saldo restante a cero.
  5. Inserta un movimiento transaccional `DESEMBOLSO_CREDITO` en `cr_movimientos`.
  6. Encola el evento en `sync_outbox` y escribe el log de ejecución exitosa en `sync_log`.

### Escenario 4: Auditoría y Mantenimiento (Administrador)
- **Dado** que el administrador del sistema se encuentra autenticado (ej. `ADM001`).
- **Cuando** accede a "Usuarios" o "Productos", puede crear, actualizar o dar de baja cuentas de personal/clientes y productos crediticios.
- **Cuando** accede a "Sync Logs", puede auditar todos los eventos que se han procesado de la outbox hacia el núcleo financiero.
