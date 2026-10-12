# 🛒 SmartCart: Guía de Arquitectura y Contexto para Agentes de IA

> **Documento de Contexto Maestro y Toma de Decisiones Técnicas**  
> **Versión del Proyecto:** `1.1.3+6` | **SDK Dart:** `^3.11.1` | **Framework:** `Flutter 3.x (Material Design 3)`  
> **Fecha de Actualización:** Octubre 2026  
> **Propósito:** Proporcionar a cualquier agente de IA o desarrollador el entendimiento exhaustivo del sistema, su arquitectura de datos, flujos de negocio, restricciones críticas y guía para la toma de decisiones futuras.

---

## 1. Visión General del Producto y Propuesta de Valor

**SmartCart** (`lista_supermercado`) es una aplicación móvil inteligente orientada a la planificación, ejecución y control presupuestario de compras físicas de supermercado y farmacia. 

A diferencia de una lista de tareas tradicional, SmartCart está construida sobre un modelo **offline-first adaptativo con capacidades multimodales, colaboración en la nube en tiempo real y alta seguridad**:
- **Captura Multimodal:** Entrada de productos mediante **Voz (STT)**, teclado y **Escaneo de Código de Barras (cámara + Open Food Facts API)**.
- **Asistente Manos Libres en Tienda:** Motor **Text-to-Speech (TTS)** integrado con botón minimalista en la AppBar para lectura auditiva de la lista de pendientes mientras el usuario empuja el carrito.
- **Memoria Predictiva (Catálogo Inteligente):** Al agregar productos, la app recuerda y autocompleta categoría, prioridad y precios históricos estimados mediante aprendizaje pasivo.
- **Control Presupuestario y Auditoría:** Barra de gasto en tiempo real (`BarraProgresoPresupuesto`), resumen de progreso y registro de compras con desglose exacto de productos adquiridos.
- **Autenticación Dual con Modo Invitado Blindado:** Soporte para **Firebase Authentication** (Correo/Contraseña y Google Sign-In) con verificación obligatoria de correo y preservación total del **Modo Invitado**, el cual opera 100% offline mediante SQLite sin requerir cuenta.
- **Defensa Anti-Spam y Anti-Bot Multicapa:** Campo trampa Honeypot, validación interactiva `HumanVerificationTile`, rate limiting de intentos fallidos y traducción amigable de errores de Firebase al español.
- **Sincronización Colaborativa en Vivo (Cloud Firestore):** Listas compartidas mediante PINs de 6 caracteres alfanuméricos seguros anti-colisión (ej. `K7X9P2`) o enlaces directos (**Deep Links & App Links** vía `app_links` y Firebase Hosting).
- **Motor Bidireccional de Notificaciones:** Detección de cambios en listas compartidas con atribución de autor, supresión estricta de auto-notificaciones, buffer anti-ráfagas de 1.2s y canales híbridos: banner flotante superior HUD (`InAppNotificationBanner`) en primer plano y notificaciones push locales nativas (`flutter_local_notifications`) en segundo plano.
- **Auditoría e Historial de Actividad en Tiempo Real:** Buffer circular de los últimos 30 eventos en Firestore accesible mediante `HistorialCambiosModal`.
- **Checkout Resiliente y Desvinculación Automática:** Finalización colaborativa de compras protegida con `try-finally`, timeouts de 4s, persistencia local inmediata, limpieza de productos en Firestore (`finalizada: true`) y auto-desconexión sin necesidad de reiniciar la app.
- **Aislamiento Estricto Multi-Usuario:** Control de sesión con `current_session_uid` y purga integral de SQLite en logout para evitar que el Modo Invitado o nuevos usuarios accedan a datos de cuentas anteriores.
- **Gestión Multi-Lista y Categorización Dinámica:** Soporte para listas (`supermercado`, `farmacia`), organización por pasillos y replicación automática de categorías personalizadas en la nube.

---

## 2. Pila Tecnológica (Tech Stack)

| Capa / Subsistema | Tecnología / Paquete | Versión | Rol en el Proyecto |
|---|---|---|---|
| **Lenguaje & Core** | Dart / Flutter | `^3.11.1` | Base del proyecto multiplataforma Android/iOS |
| **Gestión de Estado** | `provider` | `^6.1.2` | `ListaProvider` centralizado (`ChangeNotifier`) con inicialización eager |
| **Persistencia Local** | `sqflite`, `path`, `path_provider` | `^2.3.0` / `^1.9.0` / `^2.1.3` | Base de datos SQLite relacional (`supermercado.db`, versión 8) |
| **Configuraciones & Caché** | `shared_preferences` | `^2.3.5` | Preferencias de usuario, sesión (`current_session_uid`), avatar y settings |
| **Autenticación Cloud** | `firebase_auth`, `google_sign_in` | `^6.7.0` / `^7.2.0` | Autenticación híbrida Email/Password y Google OAuth 2.0 |
| **Cloud & Sincronización** | `firebase_core`, `cloud_firestore` | `^4.7.0` / `^6.3.0` | Sincronización colaborativa en vivo por PIN y respaldo de historial por UID |
| **Deep Linking & Web** | `app_links` | `^7.2.1` | Detección de Cold/Warm start para esquemas `smartcart://` y URLs Web |
| **Notificaciones Locales** | `flutter_local_notifications` | `^22.3.1` | Notificaciones nativas en bandeja del sistema con Android desugaring |
| **Reconocimiento de Voz** | `speech_to_text` | `^7.0.0` | Dictado por voz continuo en español con auto-reintento |
| **Síntesis de Voz (TTS)** | `flutter_tts` | `^3.8.5` | Lectura auditiva de pendientes con botón de solo icono animado |
| **Escáner de Barras** | `simple_barcode_scanner` | `^0.6.0` | Escaneo mediante cámara para códigos EAN/UPC |
| **Consumo de APIs REST** | `http` | `^1.6.0` | Consulta a Open Food Facts (`world.openfoodfacts.org`) |
| **Compartición & Enlaces** | `share_plus`, `url_launcher` | `^10.1.3` / `^6.3.1` | Compartir listas/enlaces por mensajería, SMS y soporte por correo |
| **Multimedia / Perfil** | `image_picker` | `^1.2.2` | Selección y persistencia de foto de perfil desde galería |
| **Diseño / Navegación** | `google_nav_bar`, Material 3 | `^5.0.7` | Barra inferior flotante, preservación de estado con `IndexedStack` y Dark Mode |

---

## 3. Estructura de Directorios y Responsabilidades

```
lista_supermercado/
├── android/                        # Configuración nativa Android
│   ├── app/
│   │   ├── build.gradle.kts        # Desugaring Java 17, firma release V1/V2/V3/V4 y key.properties
│   │   └── smartcart-keystore.jks  # Almacén de claves PKCS12 para producción (vigente hasta 2054)
│   └── key.properties              # Credenciales locales de firma digital (ignorado en Git público)
├── apk/                            # Binarios de distribución
│   ├── SmartCart_v1.1.2.apk        # APK Release oficial v1.1.2+5 firmado
│   └── SmartCart.apk               # Enlace canónico de descarga rápida
├── docs/                           # Documentación técnica y planes
│   ├── informe_cambios_rama.md     # Informe exhaustivo de la rama de desarrollo
│   ├── seguridad_anti_spam.md      # Especificación de seguridad y protección anti-bot
│   └── archive/                    # Historial de planes de implementación completados
├── web/
│   └── .well-known/assetlinks.json # Verificación oficial de Android App Links para Firebase Hosting
├── lib/
│   ├── main.dart                   # Entrypoint. Inicialización de Firebase, NotificationService, AppLinks y navegación
│   ├── firebase_options.dart       # Configuración oficial de Firebase generada por CLI
│   ├── models/
│   │   ├── producto.dart           # Entidad Producto con UUID v4 RFC 4122 y serialización toMap/fromMap
│   │   ├── categoria_model.dart    # Entidad CategoriaModel (nombre, colorValue, iconCode)
│   │   ├── historial_compra.dart   # Entidad HistorialCompra con UUID v4, pinLista y snapshot productosJson
│   │   └── notificacion_evento.dart# Entidad para eventos de listas compartidas y tiempo relativo
│   ├── providers/
│   │   └── lista_provider.dart     # Provider central: SQLite v8, Firestore listeners, checkout resiliente, sync nube
│   ├── services/
│   │   ├── auth_service.dart       # Firebase Auth (Email/Google), verificación de email y traducción de errores
│   │   ├── db_service.dart         # SQLite singleton (versión 8, migraciones v1-v8, purga de datos por usuario)
│   │   ├── deep_link_service.dart  # Procesamiento y extracción de PINs desde URIs/App Links
│   │   ├── firebase_service.dart   # Cliente Firestore: sync colaborativo, subcolecciones, reglas de timeouts
│   │   └── notification_service.dart # Gestión de banners In-App, push locales y buffer anti-spam de ráfagas
│   ├── theme/
│   │   └── colors.dart             # Paleta cromática oficial (kVerde, kVerdeClaro, kVerdeMenta, kNaranja, etc.)
│   ├── views/
│   │   ├── agregar_voz_view.dart   # Pantalla 1: Dictado por voz continuo, escáner EAN/UPC y entrada manual
│   │   ├── lista_compras_view.dart # Pantalla 2: Carrito activo, TTS solo icono, modal de actividad, banner HUD
│   │   ├── categorias_view.dart    # Pantalla 3: Catálogo interactivo de categorías con expansión y CRUD
│   │   ├── historial_compras_view.dart # Vista secundaria: Compras pasadas, modal desglose y reutilización de listas
│   │   ├── perfil_view.dart        # Pantalla 4: Avatar, estadísticas, switches de notificaciones y logout seguro
│   │   ├── login_view.dart         # Pantalla de acceso: Email/Password, Google Sign-In, Anti-Bot y Modo Invitado
│   │   └── email_verification_view.dart # Pantalla de espera interactiva de verificación de correo
│   └── widgets/
│       ├── auth_gate.dart          # Compuerta reactiva que dirige entre Login, Verificación y MainNavigation
│       ├── google_logo.dart        # Logotipo vectorial oficial de Google
│       ├── human_verification_tile.dart # Desafío interactivo anti-bot para el formulario de registro
│       ├── in_app_notification_banner.dart # Banner flotante animado superior tipo HUD con swipe-to-dismiss
│       ├── historial_cambios_modal.dart # Modal deslizable con registro cronológico de actividad reciente
│       ├── agregar_producto_dialog.dart # Modal de confirmación al capturar producto (precio, categoría, cantidad)
│       ├── editar_producto_dialog.dart  # Modal para editar atributos de productos existentes
│       ├── producto_card.dart      # Tarjeta interactiva con checkbox háptico, badge de prioridad y swipe to dismiss
│       ├── barra_progreso_presupuesto.dart # Barra inferior flotante con SafeArea y cálculo de gasto en tiempo real
│       └── dialogos_sincronizacion.dart # Diálogos de Conectar/Compartir en vivo (PIN, Deep Link o Base64)
├── test/                           # Suite de pruebas automatizadas (42/42 tests aprobados al 100%)
│   ├── auth_test.dart              # Traducción de errores FirebaseAuthException y renderizado de GoogleLogo
│   ├── categoria_sync_test.dart    # Serialización y persistencia de categorías en listas compartidas
│   ├── deep_link_test.dart         # Extracción de PINs desde esquemas personalizados, URLs web y constructores
│   ├── finalizar_compra_resilience_test.dart # Resiliencia offline-first, try-finally y cálculo de compras
│   ├── finalizar_lista_cleanup_test.dart # Payload finalizada: true, vaciado de productos y desvinculación
│   ├── historial_sync_test.dart    # Serialización de UUID v4 en historial y compatibilidad retroactiva
│   ├── login_view_test.dart        # Pruebas de widget de formulario de login, switches y botón de invitado
│   ├── notifications_test.dart     # Supresión de auto-notificaciones, deduplicación y banner In-App HUD
│   ├── producto_test.dart          # Integridad de modelo Producto, copyWith, toMap y UUID v4
│   ├── security_auth_test.dart     # Comportamiento interactivo del anti-bot HumanVerificationTile
│   ├── user_data_isolation_test.dart # Aislamiento de SQLite entre cuentas y Modo Invitado, purga en logout
│   └── user_profile_isolation_test.dart # Aislamiento de preferencias en SharedPreferences por UID
├── firestore.rules                 # Reglas oficiales de seguridad para Cloud Firestore en producción
├── firebase.json                   # Configuración de hosting, rewrites de URLs y despliegue de Firestore
└── pubspec.yaml                    # Dependencias, entorno Dart/Flutter y configuración de assets
```

---

## 4. Arquitectura de Datos y Persistencia

### 4.1. Base de Datos SQLite Local (`supermercado.db`)
El servicio [`DBService`](file:///c:/Users/Joan%20Marquez/Documents/GitHub/lista_supermercado/lib/services/db_service.dart) gestiona el esquema local utilizando control de versiones y migraciones incrementales `onUpgrade`:

* **Versión actual de BD:** `8`
* **Historial de migraciones:**
  * **v1:** Creación base de tabla `productos`.
  * **v2:** Adición de columna `precioEstimado` en `productos`.
  * **v3:** Creación de tablas `catalogo` e `historial_compras`.
  * **v4:** Adición de columna `productosJson` a `historial_compras` para guardar el snapshot serializado.
  * **v5:** Creación e inicialización de tabla `categorias` con 8 categorías base predeterminadas.
  * **v6:** Adición de columna `tipoLista` (`'supermercado'` / `'farmacia'`) a `productos`.
  * **v7:** Adición de columna `uuid` (TEXT NOT NULL UNIQUE) a `productos` y migración retroactiva con UUID v4.
  * **v8:** Adición de columnas `uuid` (TEXT NOT NULL UNIQUE), `pinLista` (TEXT) y `finalizadoPorNombre` (TEXT) a `historial_compras` para soporte de compras colaborativas y sincronización en la nube.

#### Tablas en SQLite (Versión 8):
1. **`productos`**: Carrito activo en el dispositivo.
   ```sql
   CREATE TABLE productos (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     uuid TEXT NOT NULL UNIQUE,
     nombre TEXT NOT NULL,
     categoria TEXT NOT NULL,
     cantidad INTEGER NOT NULL,
     comprado INTEGER NOT NULL,
     prioridad TEXT NOT NULL,
     precioEstimado REAL NOT NULL DEFAULT 0.0,
     tipoLista TEXT NOT NULL DEFAULT 'supermercado'
   );
   ```
2. **`catalogo`**: Base de conocimiento local de productos conocidos para autocompletado predictivo.
   ```sql
   CREATE TABLE catalogo (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     nombre TEXT NOT NULL,
     categoria TEXT NOT NULL,
     prioridad TEXT NOT NULL,
     precioEstimado REAL NOT NULL DEFAULT 0.0
   );
   ```
3. **`historial_compras`**: Registros de compras finalizadas con snapshot completo.
   ```sql
   CREATE TABLE historial_compras (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     uuid TEXT NOT NULL UNIQUE,
     fecha TEXT NOT NULL,
     total REAL NOT NULL,
     cantidadProductos INTEGER NOT NULL,
     productosJson TEXT,
     pinLista TEXT,
     finalizadoPorNombre TEXT
   );
   ```
4. **`categorias`**: Catálogo de categorías configurables con colores e iconos.
   ```sql
   CREATE TABLE categorias (
     id INTEGER PRIMARY KEY AUTOINCREMENT,
     nombre TEXT NOT NULL,
     colorValue INTEGER NOT NULL,
     iconCode INTEGER NOT NULL
   );
   ```

#### Métodos de Purga y Aislamiento en `DBService`:
* `limpiarDatosUsuario({bool limpiarCatalogo = false})`: Vacia `productos` e `historial_compras` al cerrar sesión para garantizar que el Modo Invitado arranque siempre en blanco.
* `deleteAllHistorial()` y `deleteAllCatalogo()`: Purgas selectivas para reinicio seguro de perfil.

---

### 4.2. Esquema en Cloud Firestore y Reglas de Seguridad

#### Colección 1: `listas/{PIN}` (Lista Compartida en Vivo)
* **Documento:** `{PIN}` (6 caracteres alfanuméricos, ej. `K7X9P2`).
* **Campos del Documento:**
  ```json
  {
    "productos": [
      {
        "uuid": "8c59f032-6a4a-4b96-932b-42fa60541991",
        "nombre": "Leche Descremada",
        "categoria": "Lácteos",
        "cantidad": 2,
        "comprado": 0,
        "prioridad": "Alta",
        "precioEstimado": 45.0,
        "tipoLista": "supermercado"
      }
    ],
    "categorias": [
      {
        "nombre": "Orgánicos",
        "colorValue": 4284922986,
        "iconCode": 58340
      }
    ],
    "ultimoCambio": {
      "autorUid": "u7d81hs... / uuid-invitado",
      "autorNombre": "Joan",
      "tipo": "marcado",
      "productoNombre": "Leche Descremada",
      "detalle": "Joan marcó Leche Descremada",
      "timestamp": 1727885400000
    },
    "actividadReciente": [
      {
        "id": "uuid-evento",
        "autorUid": "...",
        "autorNombre": "Joan",
        "tipo": "agregado",
        "productoNombre": "Café",
        "cantidad": 1,
        "timestamp": 1727885300000
      }
    ],
    "finalizada": false,
    "ultimaActualizacion": "Timestamp"
  }
  ```
* **Subcolección:** `listas/{PIN}/historial/{UUID}`: Almacena compras colaborativas finalizadas para auditoría compartida.

#### Colección 2: `usuarios/{UID}` (Historial y Datos Privados de Usuario)
* **Subcolección:** `usuarios/{UID}/historial_compras/{UUID}`: Respaldo en la nube del historial de compras del usuario autenticado. Se descarga automáticamente al iniciar sesión en un nuevo dispositivo.

#### Reglas Oficiales de Seguridad ([`firestore.rules`](file:///c:/Users/Joan%20Marquez/Documents/GitHub/lista_supermercado/firestore.rules)):
* **`listas/{pin}`:** Acceso condicionado a validación de PIN (longitud 4–8 caracteres alfanuméricos). Lectura y actualización colaborativa permitida a miembros que poseen el PIN. **Listado global denegado** (`allow list: if false;`) para evitar enumeración y raspado no autorizado.
* **`usuarios/{userId}`:** Aislamiento estricto de usuario (`request.auth.uid == userId`). Ningún usuario puede leer ni modificar los datos personales ni el historial de otro usuario.

---

## 5. Flujos de Negocio Críticos y Lógica de Sincronización

```mermaid
flowchart TD
    subgraph Entrada ["Flujo de Captura"]
        A[Usuario introduce producto] --> B{Método}
        B -->|Voz| C[SpeechToText transcribe]
        B -->|Barras| D[Camera Scan -> Open Food Facts]
        B -->|Manual| E[Teclado en diálogo]
        C & D & E --> F[Consulta a tabla catalogo]
        F --> G[Autocompleta o aplica defaults]
        G --> H[AgregarProductoDialog confirma]
        H --> I[Inserta en SQLite: productos y catalogo]
    end

    subgraph Sincronizacion ["Sincronización Firestore"]
        I --> J{¿Hay PIN activo?}
        J -->|Sí| K[Escribe en listas/PIN con ultimoCambio]
        J -->|No| L[Fin del guardado local]
        K --> M[Buffer Anti-Spam: 1.2s]
        M --> N{¿Es auto-cambio?}
        N -- Sí --> O[Suprime notificación local]
        N -- No --> P[Emite InAppBanner o Push del sistema]
    end

    subgraph Checkout ["Finalización de Compra Resiliente"]
        Q[Pulsar Terminar Compra] --> R[SQLite guarda Historial e inscribe compras]
        R --> S{¿Lista compartida?}
        S -- No --> T[Limpia carrito local SQLite]
        S -- Sí --> U[Firestore: productos: [], finalizada: true]
        U --> V[Participantes detectan finalizada: true]
        V --> W[Guardan compra, limpian carrito y desconectan]
        U --> X[Iniciador auto-desconecta y limpia memoria]
    end
```

### 5.1. Ciclo de Vida del Checkout Resiliente (`terminarCompra`)
1. **Prioridad Local Inmediata (Offline-First):** Se genera el registro en SQLite (`DBService.instance.createHistorial`), se entrena el catálogo (`upsertCatalogo`) y se eliminan los productos comprados del carrito local.
2. **Estructura Inmune con `try ... finally`:** Se asegura que `_isLoading = false; notifyListeners();` se ejecute siempre, impidiendo que la pantalla se congele con un spinner infinito si la red falla.
3. **Timeouts en la Nube de 4 Segundos:** Toda comunicación remota hacia Firestore cuenta con `.timeout(const Duration(seconds: 4))`.
4. **Limpieza Automática y Desvinculación de Participantes:**
   - En Firestore se actualiza el documento con `'productos': []` y `'finalizada': true`.
   - El iniciador ejecuta inmediatamente `desconectarFirebase()` y `_productos.clear()`.
   - Los dispositivos participantes detectan `finalizada: true` en el listener, guardan la compra en su historial, vacían su lista local, disparan el banner informativo (*«¡Familiar ha finalizado la compra! Guardada en tu historial»*) y se desconectan de Firebase en caliente sin requerir reinicio de la aplicación.
5. **Bloqueo de Reconexión:** Si se intenta conectar a un PIN cerrado, se rechaza la conexión con el mensaje: *"Esta lista de compras ya fue finalizada y cerrada."*

### 5.2. Motor de Notificaciones Bidireccionales
* **Atribución de Eventos:** Cada mutación remota inscribe `ultimoCambio` con `autorUid`, `autorNombre`, `tipo`, `productoNombre` y `detalle`.
* **Supresión de Auto-Notificaciones:** Se coteja `autorUid` con el UID de Firebase o UUID de invitado local. El dispositivo que realiza la acción **nunca** se auto-notifica.
* **Buffer Anti-Spam por Ráfagas (1.2 segundos):** Múltiples cambios en un lapso breve se consolidan en una sola alerta (*«Joan realizó N cambios en la lista compartida»*).
* **Canales Híbridos:**
  - **In-App (Primer Plano):** Banner flotante animado tipo HUD [`InAppNotificationBanner`](file:///c:/Users/Joan%20Marquez/Documents/GitHub/lista_supermercado/lib/widgets/in_app_notification_banner.dart) con vibración háptica, swipe-to-dismiss y auto-cierre en 3.8s.
  - **Push Local (Segundo Plano):** Despacho en la barra de estado vía [`NotificationService`](file:///c:/Users/Joan%20Marquez/Documents/GitHub/lista_supermercado/lib/services/notification_service.dart) y `flutter_local_notifications`.

### 5.3. Aislamiento Estricto de Sesión y Modo Invitado
* **Control con `current_session_uid`:** Almacenado en `SharedPreferences`. Si un nuevo usuario inicia sesión en un dispositivo previamente usado, el método `verificarYLimpiarSesionSiCambioUsuario()` purga SQLite antes de descargar datos de la nube.
* **Purga en Logout:** Al presionar "Cerrar sesión", se ejecutan `limpiarDatosUsuario()` y `limpiarDatosLocalesPorCierreDeSesion()`. El Modo Invitado siempre inicia en blanco con 0 productos y 0 compras.
* **Namespaces por UID:** Preferencias de usuario guardadas bajo prefijos aislados (`user_notifs_$uid`, `user_rol_$uid`, frente a `guest_notifs`).

---

## 6. Integraciones de Hardware, APIs y Configuración Nativa

1. **Reconocimiento de Voz (`speech_to_text`):**
   - Configurado con reinicio automático de escucha ante silencios intermitentes (`_restartListening`).
   - Prioriza locales en español (`es-ES`, `es-MX`, `es-US`, o `es`).
2. **Lectura Auditiva (`flutter_tts`):**
   - Botón de solo icono animado en el AppBar de "Mi Lista" con estados: Inactivo, Leyendo, Pausado.
   - Configuración de velocidad (`0.5`), tono (`1.0`) y volumen (`1.0`).
3. **Escáner de Códigos de Barras (`simple_barcode_scanner` + `http`):**
   - Consulta a `https://world.openfoodfacts.org/api/v0/product/{barcode}.json` con timeout de 8 segundos.
   - Autocompleta nombre del producto en español directamente en el diálogo de guardado.
4. **Deep Linking y App Links (`app_links`):**
   - Soporte nativo para esquemas `smartcart://join?pin=XXXXXX` y URLs web `https://smartcart-a4013.web.app/join?pin=XXXXXX`.
   - Verificación de dominio mediante `web/.well-known/assetlinks.json` con SHA-256 del certificado de producción.
   - Diálogo cautelar si el usuario ya tiene productos locales en su lista activa.
5. **Configuración de Android Release:**
   - **Firma Digital:** Keystore PKCS12 (`smartcart-keystore.jks`) con esquemas V1, V2, V3 y V4 en `android/app/build.gradle.kts`.
   - **Core Library Desugaring:** `desugar_jdk_libs:2.1.4` y Java 17 para compatibilidad universal de APIs de tiempo.
   - **Permisos en Manifest:** `POST_NOTIFICATIONS`, `RECORD_AUDIO`, `CAMERA`.

---

## 7. Reglas de Oro e Invariantes para Agentes (Directrices de No Ruptura)

> [!CAUTION]
> **REGLAS CRÍTICAS QUE CUALQUIER AGENTE DEBE RESPETAR AL MODIFICAR ESTE PROYECTO:**

1. **Invariante de Identidad (`UUID`):**
   - La identidad universal de productos e historiales es siempre `uuid` (UUID v4 RFC 4122). Nunca confíes en el `id` autoincremental de SQLite para sincronización remota o importación de listas.
   - Al duplicar o importar productos de compras pasadas, SIEMPRE asigna `id = null` y genera un nuevo `uuid` mediante `Producto.generarUuid()`.
2. **Migraciones de Base de Datos (`DBService`):**
   - **NUNCA** elimines ni alteres las sentencias de migración previas (`oldVersion < 2`, ..., `< 8`).
   - Si requieres agregar columnas o tablas, incrementa la versión de la base de datos (e.g., a `9`) y añade un nuevo bloque `if (oldVersion < 9)` en `_upgradeDB`. Envuelve las sentencias `ALTER TABLE` en bloques `try/catch`.
3. **Resiliencia Offline-First en Checkout:**
   - Cualquier operación de compra o limpieza debe estructurarse con `try ... finally` para garantizar que `_isLoading = false` se ejecute siempre.
   - La persistencia local en SQLite debe ejecutarse **antes** de interactuar con la nube.
   - Todas las llamadas a Firestore deben tener un `.timeout()` defensivo (máximo 4–5 segundos).
4. **Aislamiento Multi-Usuario y Privacidad:**
   - Nunca expongas datos locales a un nuevo usuario o al Modo Invitado tras un cierre de sesión. Siempre invoca `limpiarDatosUsuario()` en logout y valida `current_session_uid`.
5. **Supresión de Auto-Notificaciones:**
   - Toda lógica de notificación debe comparar `autorUid != localUid` para impedir que el usuario reciba alertas de sus propios cambios.
6. **Inicialización Eager del Provider (`main.dart`):**
   - Mantén `ChangeNotifierProvider(create: (_) => ListaProvider()..cargarListas(), lazy: false)`. Si se vuelve `lazy: true`, las categorías no estarán cargadas al abrir el primer diálogo y se mostrará erróneamente solo "Otros".
7. **Modo Oscuro Adaptativo:**
   - No hardcodees `Colors.white` o `Colors.black` en fondos ni tarjetas. Usa siempre `Theme.of(context).cardColor`, `Theme.of(context).scaffoldBackgroundColor`, o evalúa `final isDark = Theme.of(context).brightness == Brightness.dark;`.

---

## 8. Estado Actual de Calidad y Próximas Oportunidades (Roadmap)

### Estado Actual de Calidad:
* **Pruebas Automatizadas:** **46/46 pruebas pasando al 100%** en 13 archivos de prueba (`test/`).
* **Análisis Estático (`flutter analyze`):** **0 errores, 0 advertencias, 0 sugerencias de linter**.
* **Binarios Release Compilados:** `apk/SmartCart_v1.1.3.apk` (~55.5 MB con tree-shaking optimizado al 99.0%).
* **Reglas de Seguridad:** Desplegadas oficialmente en `firestore.rules`.

### Próximas Oportunidades de Mejora (Roadmap):
| Tarea / Oportunidad | Archivos Involucrados | Descripción / Estado Actual |
|---|---|---|
| **Selector Visual de Lista en AppBar** | `lib/views/lista_compras_view.dart`, `lib/providers/lista_provider.dart` | La columna `tipoLista` ya está implementada en SQLite v6 y Firestore. Falta añadir un selector visual/segmento en la barra superior para alternar vistas entre `'supermercado'` y `'farmacia'`. |
| **Limpieza Automática de Listas Inactivas (TTL)** | Cloud Functions / Firebase Console | Implementar una Cloud Function programada para eliminar documentos de `listas/{pin}` que lleven más de 30 días finalizados o inactivos. |
| **Feedback de Red en Escáner de Barras** | `lib/views/agregar_voz_view.dart` | Mostrar un banner visual amigable si la consulta a Open Food Facts supera el timeout o el dispositivo está completamente offline al escanear. |
| **Pruebas de Integración End-to-End (E2E)** | `integration_test/` | Añadir pruebas de integración de flujo completo: escaneo -> agregar -> marcar -> checkout -> verificar historial. |

---

*Archivo de gobernanza técnica y contexto maestro para el desarrollo de SmartCart.*
