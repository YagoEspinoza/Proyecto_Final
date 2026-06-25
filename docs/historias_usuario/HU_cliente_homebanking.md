# Historia de Usuario: Cliente Homebanking — SIP Mobile Core 360

## Detalle de la Historia de Usuario

**COMO** Cliente Bancario de SIP
**QUIERO** Acceder a mi aplicación móvil para consultar mis saldos, movimientos, tarjetas, créditos activos y solicitar nuevos financiamientos.
**PARA** Gestionar de manera autónoma mis finanzas personales y empresariales.

---

## Criterios de Aceptación

### Escenario 1: Autenticación Exitosa
- **Dado** que el cliente ingresa a la aplicación móvil.
- **Cuando** escribe su DNI `40118120`, su clave secreta `123456` en la pestaña de cliente y pulsa "INGRESAR".
- **Entonces** el sistema valida el DNI y la firma JWT en FastAPI, le otorga acceso y carga el Dashboard de Cliente de manera segura.

### Escenario 2: Bloqueo de Cuenta por Intentos Fallidos
- **Dado** que el cliente ingresa a la app e introduce repetidamente claves incorrectas.
- **Cuando** alcanza el quinto (5) intento fallido.
- **Entonces** la app bloquea localmente e impide nuevas solicitudes de login durante 30 minutos, guardando la hora del bloqueo en `flutter_secure_storage`. El backend también retorna un bloqueo por intentos fallidos.

### Escenario 3: Consulta de Saldos, Tarjetas y Movimientos
- **Dado** que el cliente se encuentra autenticado en su dashboard.
- **Cuando** carga la pestaña "Cuentas".
- **Entonces** visualiza su saldo disponible en soles formateado (ej. `S/ 1,500.00`), su tarjeta de débito enmascarada y el historial cronológico de los últimos 5 movimientos transaccionales de abono y cargo.

### Escenario 4: Simulación y Solicitud de Crédito
- **Dado** que el cliente se encuentra en la sección "Créditos" y no tiene un préstamo activo.
- **Cuando** pulsa "Solicitar un Crédito", ingresa el monto (ej. `S/ 1,000`), el plazo (ej. `12 meses`), el destino de crédito y envía el formulario.
- **Entonces** el sistema registra el expediente en estado `ENVIADO` en FastAPI, asocia la gestión a la cartera de un asesor activo de la misma agencia y muestra la solicitud en la lista del cliente como pendiente de evaluación.
