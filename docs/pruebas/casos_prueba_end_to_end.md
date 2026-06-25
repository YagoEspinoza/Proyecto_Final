# Casos de Prueba End-to-End — SIP Mobile Core 360

Este plan de pruebas describe los escenarios y pasos exactos para verificar la integración end-to-end del sistema.

## Caso de Prueba 1: Originación de Crédito por el Cliente
### Precondiciones:
- El cliente DNI `40118120` cuenta con un usuario activo en el sistema.
- El cliente no registra préstamos activos.
- El servidor FastAPI y PostgreSQL se encuentran en línea.

### Pasos:
1. Iniciar la aplicación móvil en el emulador o dispositivo físico.
2. Iniciar sesión ingresando el DNI `40118120` y la clave `123456` en la pestaña de Cliente.
3. Confirmar que se carga la pantalla de Homebanking y se muestran los saldos de la cuenta de ahorros.
4. Navegar a la pestaña "Créditos" y pulsar "Nueva Solicitud".
5. Rellenar los campos: Monto `1000` soles, Plazo `12` meses, Destino `Capital de trabajo` y presionar "ENVIAR SOLICITUD".
6. Confirmar la alerta de éxito en pantalla.

---

## Caso de Prueba 2: Visita, Evaluación y Firma por el Asesor
### Precondiciones:
- El Asesor `A001` cuenta con un usuario y clave activa.
- La solicitud creada en el Caso 1 se encuentra registrada y asignada en el sistema.

### Pasos:
1. Iniciar sesión en la app con el código `A001` y clave `123456` en la pestaña Colaborador.
2. Ir a la pestaña "Cartera" y verificar que la solicitud del cliente aparece en la lista diaria.
3. Seleccionar el cliente para abrir su Ficha.
4. Rellenar el registro de visita con la observación "Negocio en crecimiento" y pulsar "REGISTRAR VISITA (GPS)".
5. Navegar a la sección "Nueva Solicitud" (Stepper).
6. En la Fase 1, ingresar Monto `1000`, Plazo `12` y pulsar Continuar.
7. En la Fase 2 (Preevaluación), pulsar Continuar y verificar que el preevaluador local calcula el score como `APTO`.
8. En la Fase 3 (Buró), verificar que califica como `NORMAL/APROBADO`.
9. En la Fase 4 (Documentos), verificar los sustentos cargados.
10. En la Fase 5 (Firma), dibujar la firma sobre la pantalla táctil y pulsar "ENVIAR AL COMITÉ".

---

## Caso de Prueba 3: Aprobación y Desembolso por el Supervisor
### Precondiciones:
- El Supervisor `SUP001` está registrado.
- La solicitud completada por el Asesor en el Caso 2 se encuentra en estado `RECIBIDO_COMITE`.

### Pasos:
1. Iniciar sesión en la app con el código `SUP001` y clave `123456`.
2. Ir a la bandeja del comité y seleccionar la solicitud en estado `RECIBIDO_COMITE`.
3. Pulsar "RECIBIR EN COMITÉ", luego "EVALUAR EXPEDIENTE".
4. Dejar el monto aprobado vacío (para tomar los 1000 solicitados) y pulsar "APROBAR".
5. Pulsar "DESEMBOLSAR CRÉDITO".
6. Confirmar el mensaje de éxito en pantalla.

---

## Caso de Prueba 4: Verificación Final del Cliente
### Pasos:
1. Iniciar sesión nuevamente como Cliente (`40118120` / `123456`).
2. Entrar a la pestaña "Cuentas" y validar que el saldo se ha incrementado por S/ 1,000.
3. Confirmar que en los movimientos figura un registro con tipo `DESEMBOLSO_CREDITO`.
4. Navegar a la sección "Créditos" y confirmar que el préstamo figura como activo.
5. Presionar "VER CRONOGRAMA" y validar las 12 cuotas amortizadas mediante fórmula francesa.
