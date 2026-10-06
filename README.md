# 🛒 SmartCart (`lista_supermercado`)

> **Aplicación móvil inteligente para la planificación, control presupuestario y compras colaborativas de supermercado y farmacia.**  
> **Versión:** `1.1.2+5` | **Framework:** Flutter 3.x (Material Design 3) | **SDK Dart:** `^3.11.1`

---

## 🌟 Características Principales

* **Entrada Multimodal:** Agrega productos por **Voz continua (Speech to Text)** en español, teclado o escaneo de **Código de Barras** (con auto-búsqueda inmediata en Open Food Facts).
* **Lectura Manos Libres (TTS):** Botón minimalista de solo icono animado en la barra superior para escuchar los productos pendientes mientras recorres los pasillos de la tienda.
* **Memoria Inteligente (Catálogo):** Recuerda y autocompleta automáticamente categoría, prioridad y precios históricos estimados mediante aprendizaje pasivo.
* **Control de Presupuesto:** Cálculo de gasto en tiempo real, barra de progreso inferior flotante adaptativa con `SafeArea` y resumen estadístico.
* **Autenticación Dual con Modo Invitado Blindado:**
  * **Firebase Authentication:** Inicio de sesión y registro con Correo/Contraseña (con verificación obligatoria por email) y **Google Sign-In** nativo con OAuth 2.0.
  * **Modo Invitado 100% Offline:** Entrada directa sin cuenta, operando exclusivamente con SQLite local para máxima privacidad y rapidez.
* **Defensa Anti-Spam y Anti-Bot Multicapa:**
  * Campo trampa **Honeypot** silencioso contra scripts maliciosos.
  * Desafío interactivo [`HumanVerificationTile`](./lib/widgets/human_verification_tile.dart) previo al envío del registro.
  * Protección contra ataques de fuerza bruta con enfriamiento progresivo (rate limiting).
* **Sincronización Colaborativa en Vivo (Cloud Firestore):**
  * Sincroniza listas en tiempo real mediante PINs alfanuméricos seguros de 6 caracteres (ej. `K7X9P2`).
  * Replicación automática de categorías personalizadas (nombres, colores e iconos).
* **Deep Linking y Compartición Inteligente:**
  * Apertura instantánea con un toque mediante enlaces web oficiales (`https://smartcart-a4013.web.app/join?pin=XXXXXX`) y esquemas nativos (`smartcart://join?pin=XXXXXX`).
  * Verificación oficial de **Android App Links** con `assetlinks.json` en Firebase Hosting.
  * Detección en frío (Cold Start) y en caliente (Warm Start) con diálogo cautelar para proteger listas locales.
* **Motor Bidireccional de Notificaciones:**
  * **Banner In-App Superior (HUD):** Widget animado con vibración háptica, swipe-to-dismiss y desvío directo a la lista.
  * **Push Local del Sistema:** Alertas nativas en segundo plano mediante `flutter_local_notifications`.
  * **Filtro Anti-Spam de Ráfagas (1.2s):** Agrupa compras consecutivas (*«Joan realizó N cambios»*) y suprime estrictamente las auto-notificaciones.
* **Historial de Actividad en Tiempo Real:** Modal deslizable con registro cronológico de los últimos 30 eventos ocurridos en la lista compartida.
* **Checkout Resiliente y Offline-First:**
  * Persistencia inmediata en SQLite local antes de sincronizar con la nube, protegido con `try-finally` y timeouts de 4 segundos.
  * Desvinculación y limpieza automática en tiempo real para todos los participantes al concluir la compra.
* **Aislamiento Estricto de Datos entre Usuarios:**
  * Purga automática de base de datos SQLite al cerrar sesión para garantizar que el Modo Invitado arranque siempre desde cero.
  * Rastreo de sesión con `current_session_uid` que previene cualquier mezcla accidental de historiales en la nube.
* **Respaldo Fuera de Línea en Base64:** Exportación e importación segura de listas completas sin requerir conexión a internet.

---

## 📚 Documentación del Proyecto

| Documento | Ubicación | Descripción |
|---|---|---|
| **Contexto Técnico y Guía para Agentes** | [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) | **Fuente única de verdad.** Arquitectura completa, esquema SQLite v8, Firestore, flujos de sincronización, reglas de oro e invariantes del sistema. |
| **Informe de Cambios de la Rama** | [docs/informe_cambios_rama.md](./docs/informe_cambios_rama.md) | Detalle funcional y diagramas de arquitectura de la rama de desarrollo. |
| **Especificación de Seguridad Anti-Spam** | [docs/seguridad_anti_spam.md](./docs/seguridad_anti_spam.md) | Arquitectura de defensa multicapa, honeypot y verificación anti-bot. |
| **Planes de Implementación Históricos** | [docs/archive/](./docs/archive/) | Planes técnicos completados (autenticación, sync de historial, resiliencia y notificaciones). |
| **Estudio de Mercado y UX** | [ux_survey/README.md](./ux_survey/README.md) | Validación Lean Startup y formulario automatizado en Google Apps Script. |

---

## 🧪 Pruebas y Calidad de Código

El proyecto cuenta con una cobertura integral de pruebas automatizadas y cumplimiento estricto de estándares de código:

* **Suite de Pruebas:** **42/42 tests aprobados al 100%** (`flutter test`).
  * Pruebas de modelos (`Producto`, `HistorialCompra`, `CategoriaModel`, `NotificacionEvento`).
  * Pruebas de autenticación y anti-bot (`HumanVerificationTile`, traducción de errores).
  * Pruebas de extracción de PINs y Deep Links.
  * Pruebas de resiliencia de checkout y desvinculación reactiva.
  * Pruebas de aislamiento de base de datos y preferencias de usuario.
* **Análisis Estático:** **0 errores, 0 advertencias y 0 sugerencias** (`flutter analyze`).

---

## 📦 Binarios Compilados

El instalador APK de producción se encuentra compilado con soporte para Core Library Desugaring (Java 17) y firmado digitalmente bajo los esquemas criptográficos V1, V2, V3 y V4:

* 📱 **APK Oficial Release:** [`apk/SmartCart_v1.1.2.apk`](./apk/SmartCart_v1.1.2.apk)
* 🔗 **Enlace Canónico:** [`apk/SmartCart.apk`](./apk/SmartCart.apk)

---

## 🚀 Inicio Rápido

### Requisitos Previos
* **Flutter SDK:** `^3.11.1`
* **Java:** JDK 17
* **Android Studio / VS Code / Antigravity IDE**

### Comandos Comunes

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Ejecutar análisis estático (Linter)
flutter analyze

# 3. Ejecutar suite de pruebas automatizadas
flutter test

# 4. Lanzar en emulador o dispositivo físico
flutter run

# 5. Compilar APK release optimizado
flutter build apk --release
```

---

*Desarrollado para el proyecto SmartCart - Octubre 2026.*
