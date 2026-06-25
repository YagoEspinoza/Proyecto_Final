# Checklist y Rúbrica de Entrega — SIP Mobile Core 360

Este documento sirve como autoevaluación final de la rúbrica y criterios de aceptación del proyecto.

## Criterios Técnicos Obligatorios

| Requerimiento Rúbrica | Estado | Evidencia / Ubicación |
| --- | :---: | --- |
| **App Móvil Única Multirrol** | `[x]` | Contiene pantallas dinámicas según el rol de la sesión ([main.dart](file:///c:/proyectoappsip/mobile_app_sip/lib/main.dart)). |
| **Autenticación JWT en FastAPI** | `[x]` | Rutas `/auth/login`, `/auth/me` con generación de token. |
| **Almacenamiento Seguro (JWT)** | `[x]` | Token guardado en [secure_storage_service.dart](file:///c:/proyectoappsip/mobile_app_sip/lib/core/storage/secure_storage_service.dart) (no en SharedPrefs). |
| **Seguridad de Roles (RBAC)** | `[x]` | Rutas del backend validadas con `require_roles(...)` en [dependencies.py](file:///c:/proyectoappsip/backend_core_mobile/app/core/dependencies.py). |
| **Amortización Francesa Real** | `[x]` | Implementado en [desembolso_service.py](file:///c:/proyectoappsip/backend_core_mobile/app/services/desembolso_service.py) ajustando última cuota. |
| **Base de Datos Espejo `cr_*`** | `[x]` | Tablas, relaciones y registros creados exitosamente en PostgreSQL. |
| **Offline-First en Fuerza de Ventas** | `[x]` | Caching de cartera y encolamiento de visitas/solicitudes en SQLite ([local_database.dart](file:///c:/proyectoappsip/mobile_app_sip/lib/core/storage/local_database.dart)). |
| **Sincronización Outbox** | `[x]` | Eventos persistidos en `sync_outbox` y registros procesados con logs. |
| **Firma Digital & GPS en Visita** | `[x]` | Coordenadas capturadas con `Geolocator` y firmas con canvas de `Signature`. |
| **Listas de Inhabilitados** | `[x]` | Bloqueo automático en buró si el DNI figura en inhabilitados. |
