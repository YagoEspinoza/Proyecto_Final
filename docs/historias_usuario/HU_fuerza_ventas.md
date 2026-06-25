# Historia de Usuario: Fuerza de Ventas — SIP Mobile Core 360

## Detalle de la Historia de Usuario

**COMO** Asesor de Negocios de SIP
**QUIERO** Visualizar mi cartera asignada de hoy, geolocalizar mis visitas en campo, realizar preevaluaciones locales, consultar burós y digitalizar expedientes con firmas de clientes.
**PARA** Agilizar la recopilación de datos y originación de créditos en zonas con baja conectividad.

---

## Criterios de Aceptación

### Escenario 1: Navegación de Cartera
- **Dado** que el asesor inicia sesión con su código de empleado (ej. `A001`).
- **Cuando** entra al menú "Cartera".
- **Entonces** el sistema carga sus gestiones asignadas ordenadas por nivel de prioridad (`ALTA`, `MEDIA`, `BAJA`) y estado de la visita, recurriendo a SQLite local si no hay conexión a internet disponible.

### Escenario 2: Visita de Campo con Captura de GPS
- **Dado** que el asesor realiza la visita física en el negocio del cliente.
- **Cuando** registra la visita, ingresa comentarios y pulsa "Registrar Visita (GPS)".
- **Entonces** la aplicación captura la latitud y longitud actual del asesor, actualiza el estado local a `COMPLETADO` y encola la actualización en la cola de sincronización de SQLite si no detecta señal de internet.

### Escenario 3: Preevaluación Local y Consulta de Buró
- **Dado** que el asesor evalúa la solicitud.
- **Cuando** ejecuta la preevaluación.
- **Entonces** el sistema calcula el ratio de capacidad de pago dividiendo la cuota estimada entre la utilidad neta mensual (ingresos - gastos). Si el ratio es menor a 40%, califica automáticamente como `APTO`.
- **Cuando** consulta el buró simulado, si el último dígito del documento es 9, la solicitud pasa a estado `RECHAZADO` por mala calificación. Si el cliente está en la tabla de inhabilitados, se bloquea y se rechaza de inmediato.

### Escenario 4: Firma Digital y Envío al Comité
- **Dado** que el expediente tiene cargados los documentos requeridos.
- **Cuando** el cliente plasma su firma sobre la pantalla táctil y el asesor pulsa "Enviar al Comité".
- **Entonces** la firma se codifica a Base64, se asocia al expediente y el estado de la solicitud cambia a `RECIBIDO_COMITE` en la base de datos de FastAPI.
