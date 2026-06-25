# Requerimientos Funcionales — SIP Mobile Core 360

Este documento enumera los requerimientos funcionales (RF) obligatorios del ecosistema bancario integrado.

## 1. Módulo de Autenticación y Seguridad
- **RF-1.1:** El sistema debe soportar un login unificado con dos vistas/tabs: uno para clientes (identificado por su DNI) y otro para colaboradores (identificado por su código de empleado).
- **RF-1.2:** La aplicación móvil debe almacenar de manera segura el JWT retornado en el almacenamiento seguro local (`flutter_secure_storage`).
- **RF-1.3:** Debe implementarse un bloqueo local de inicio de sesión de 30 minutos si se registran 5 intentos fallidos consecutivos.
- **RF-1.4:** El backend debe validar mediante RBAC (Role-Based Access Control) que cada endpoint sea consumido únicamente por los roles autorizados.

## 2. Módulo Cliente / Homebanking
- **RF-2.1:** El cliente debe visualizar los saldos disponible y contable de su cuenta de ahorro pyme en tiempo real.
- **RF-2.2:** El cliente debe consultar su historial completo de movimientos transaccionales y tarjetas.
- **RF-2.3:** El cliente debe poder realizar transferencias monetarias a cuentas propias y de terceros.
- **RF-2.4:** El cliente debe poder simular y enviar una solicitud de crédito especificando monto, plazo, seguro de desgravamen, garantía y destino.
- **RF-2.5:** El cliente debe poder pagar cuotas pendientes de su crédito activo debitando el saldo de su cuenta de ahorros.
- **RF-2.6:** El cliente debe poder visualizar las notificaciones de desembolsos y pagos.

## 3. Módulo Fuerza de Ventas (Asesor)
- **RF-3.1:** El asesor debe visualizar su cartera de clientes asignada del día.
- **RF-3.2:** El asesor debe poder registrar visitas de campo capturando la ubicación GPS del dispositivo móvil.
- **RF-3.3:** El asesor debe poder calcular la capacidad de pago del cliente y generar el score de preevaluación.
- **RF-3.4:** El asesor debe poder consultar el buró de crédito simulado del cliente. Si el cliente está en listas de inhabilitados o tiene calificación PERDIDA, la solicitud se bloqueará y pasará a RECHAZADO.
- **RF-3.5:** El asesor debe digitalizar firmas del cliente plasmadas en una pantalla táctil.
- **RF-3.6:** El asesor debe poder cargar imágenes y archivos de sustento (DNI, fotos de negocio).

## 4. Módulo Supervisor y Administrador
- **RF-4.1:** El supervisor debe visualizar y recibir los expedientes enviados a comité.
- **RF-4.2:** El supervisor debe poder aprobar (definiendo el monto final aprobado), condicionar (agregando glosa) o rechazar solicitudes.
- **RF-4.3:** El supervisor debe poder ordenar el desembolso automatizado, acreditando fondos en la cuenta de ahorros del cliente y creando el cronograma de cuotas correspondiente.
- **RF-4.4:** El administrador debe poder dar mantenimiento CRUD a usuarios, clientes, asesores y productos crediticios.
- **RF-4.5:** El administrador debe visualizar y filtrar el historial de logs de sincronización de la outbox transaccional.
