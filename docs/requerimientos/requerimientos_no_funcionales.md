# Requerimientos No Funcionales — SIP Mobile Core 360

Este documento detalla las especificaciones no funcionales (RNF) técnicas que estructuran la calidad, el rendimiento y la seguridad del ecosistema.

## 1. Rendimiento y Escalabilidad
- **RNF-1.1:** El backend desarrollado en FastAPI debe procesar solicitudes HTTP concurrentes de manera eficiente gracias al uso del paradigma asíncrono ASGI de Python.
- **RNF-1.2:** Los endpoints críticos de consulta (saldos, movimientos, cartera) deben responder en menos de 500 milisegundos bajo condiciones de carga normales.
- **RNF-1.3:** La base de datos debe soportar un esquema de pools de conexiones (mediante SQLAlchemy pre-ping) para reutilizar conexiones activas de forma segura.

## 2. Conectividad y Resiliencia (Offline-First)
- **RNF-2.1:** La aplicación móvil debe funcionar de manera offline-first para el flujo del asesor, utilizando SQLite local (`sqflite`) para leer la cartera y encolar visitas, borradores de solicitudes y documentos.
- **RNF-2.2:** La aplicación debe autodetectar el estado de la red (mediante `connectivity_plus`) y sincronizar automáticamente la cola de transacciones locales pendientes en cuanto se restablezca la conectividad.

## 3. Seguridad e Integridad de Datos
- **RNF-3.1:** El tráfico de red entre la app móvil y el Core Mobile debe estar encriptado de extremo a extremo utilizando protocolos seguros HTTPS (TLS 1.3).
- **RNF-3.2:** Las claves de acceso de los usuarios deben encriptarse en la base de datos utilizando el algoritmo de hashing seguro de una sola vía `bcrypt`.
- **RNF-3.3:** El backend debe emitir JWT tokens firmados digitalmente con expiración explícita (ej. 480 minutos) y algoritmo HMAC-SHA256 (`HS256`).

## 4. Portabilidad y Compatibilidad
- **RNF-4.1:** La aplicación móvil debe ser multiplataforma (compilando nativamente en Android 10+ e iOS 15+ a partir de un único código base en Flutter).
- **RNF-4.2:** El código del backend debe ejecutarse en entornos virtualizados basados en Linux, Windows o Mac sobre Python 3.10+.
