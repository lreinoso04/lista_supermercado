# Plan de Solución: Sincronización Nube-Local, Logo Erguido y Tarjetas de Historial Responsivas

## 1. Contexto y Diagnóstico del Problema

### Problema 1: Sincronización de Compras desde la Nube al Local tras Login
- **Causa Raíz:** 
  - `ListaProvider()..cargarListas()` se ejecutaba únicamente una sola vez en `main.dart` al iniciar la app.
  - Al cerrar sesión, la base de datos local SQLite se limpia correctamente para proteger la privacidad. Sin embargo, cuando el usuario vuelve a iniciar sesión (por correo o Google), `AuthGate` cambia el widget a `MainNavigation`, pero **nadie volvía a llamar a `cargarListas()` ni a `sincronizarHistorialConFirebase()`**.
  - Por esta razón, el historial se mantenía vacío hasta que el usuario cerraba y abría la aplicación (lo que volvía a disparar `main.dart`).
  - Adicionalmente, `sincronizarHistorialConFirebase()` no reportaba estado reactivo (`notifyListeners()`), carecía de una bandera `isSyncingHistorial` para avisar al usuario, y realizaba inserciones secuenciales en lugar de transacciones por lotes (`batch`).
- **Solución Propuesta:**
  1. Conectar `ListaProvider` con el flujo de autenticación (`AuthService.instance.authStateChanges` o trigger explícito desde `AuthGate`), de modo que cada vez que un usuario inicie sesión, se dispare inmediatamente `cargarListas()`.
  2. Implementar `bool _isSyncingHistorial` en `ListaProvider` con notificación a la UI para mostrar un indicador claro ("Sincronizando historial desde la nube...").
  3. Agregar en `lib/services/db_service.dart` el método `upsertHistorialBatch` para guardar las compras recibidas de Firestore en una única transacción SQLite ultrarrápida.
  4. Agregar en el `AppBar` de `HistorialComprasView` un `IconButton` de sincronización manual con animación de carga y confirmación por `SnackBar`.

---

### Problema 2: Orientación del Logo en la Pantalla de Login
- **Causa Raíz:**
  - El archivo `assets/icon.png` contenía físicamente la imagen girada 90° en sentido antihorario (las ruedas del carrito estaban orientadas hacia el borde izquierdo).
- **Solución Propuesta:**
  - Reemplazar permanentemente `assets/icon.png` por la versión orientada correctamente (ruedas en la base, manillar en la parte superior izquierda), verificada previamente mediante inspección visual.
  - Eliminar los archivos temporales generados durante el diagnóstico (`icon_rotated.png`, `icon_upright.png`).

---

### Problema 3: Tarjetas de Historial de Compra No Responsivas (Solapamiento de Texto y Botones)
- **Causa Raíz:**
  - En `HistorialComprasView`, cada elemento usa una fila rígida `Row` dividida en:
    - Izquierda: `Expanded(Column(...))` que contiene fecha, cantidad de productos, etiqueta de PIN y texto "Finalizado por: ...".
    - Derecha: `Column(...)` con el precio y una `Row` fija con 3 botones (`Ver`, `Reutilizar`, `Eliminar`).
  - En pantallas medianas o pequeñas, o cuando el texto de "Finalizado por" o el PIN es largo, la columna de botones (que ocupa ~190-210 px) compite con la columna de texto (a la que le quedan menos de 120 px), provocando desbordamientos de render (`RenderFlex overflow`) y compresión excesiva de textos.
- **Solución Propuesta:**
  - Reestructurar la tarjeta con una jerarquía vertical limpia y adaptable:
    1. **Cabecera superior (Row):** Fecha formateada a la izquierda y Precio Total en texto destacado y legible a la derecha.
    2. **Zona de Metadatos y Badges (`Wrap`):**
       - Badge con icono de carrito y cantidad de productos.
       - Badge distintivo de PIN (si aplica).
       - Badge de autor "Finalizado por: [Nombre]" con icono de usuario.
       - Al usar `Wrap`, si los textos son largos o la pantalla es angosta, los elementos saltan a la siguiente línea de forma fluida sin desbordar ni cortarse.
    3. **Separador sutil (`Divider`).**
    4. **Fila de Acciones inferior (`Row` / `Wrap` alineada a la derecha):**
       - Botones `Ver`, `Reutilizar` y `Eliminar` ubicados a todo el ancho disponible, garantizando accesibilidad táctil óptima y cero colisión con el contenido textual.

---

## 2. Plan Detallado de Implementación

### Paso 1: Servicios y Proveedores (`DBService` y `ListaProvider`)
1. **`lib/services/db_service.dart`**:
   - Crear `upsertHistorialBatch(List<HistorialCompra> lista)` usando `db.transaction()` y `batch.insert(..., conflictAlgorithm: ConflictAlgorithm.replace)`.
2. **`lib/providers/lista_provider.dart`**:
   - Agregar propiedad `bool _isSyncingHistorial = false` y su getter `bool get isSyncingHistorial => _isSyncingHistorial`.
   - Modificar `sincronizarHistorialConFirebase()`:
     - Marcar `_isSyncingHistorial = true; notifyListeners();`.
     - Obtener compras remotas y aplicar `upsertHistorialBatch`.
     - Finalizar con `_isSyncingHistorial = false; notifyListeners();`.
   - Escuchar los cambios de autenticación en el ciclo de vida o asegurar que `cargarListas()` se invoque al autenticarse.

### Paso 2: Autenticación Reactiva (`AuthGate`)
1. **`lib/widgets/auth_gate.dart`**:
   - En el listener de `StreamBuilder<User?>`, cuando el usuario pase de desconectado a autenticado, verificar si requiere recarga e invocar `Provider.of<ListaProvider>(context, listen: false).cargarListas()` para asegurar la descarga inmediata de la nube sin requerir reinicio de la app.

### Paso 3: Interfaz de Usuario de Historial (`HistorialComprasView`)
1. **`lib/views/historial_compras_view.dart`**:
   - Suscribirse reactivamente al estado de `ListaProvider` para actualizar la lista local cuando finalice la sincronización.
   - En el `AppBar`:
     - Agregar `IconButton` con icono `Icons.sync_rounded` (o `CircularProgressIndicator` si está sincronizando).
     - Tooltip descriptivo: "Sincronizar con la nube".
     - Al presionar, ejecutar la sincronización y mostrar feedback visual.
   - Debajo del `AppBar`: Si `provider.isSyncingHistorial` es verdadero, mostrar una barra o banner informativo: `"Sincronizando compras desde la nube..."`.
   - Rediseñar el `itemBuilder` de las tarjetas de compra aplicando la estructura de cabecera + `Wrap` de metadatos + botones inferiores.

### Paso 4: Corrección de Assets del Logo
1. Sobrescribir `assets/icon.png` con la versión rotada correctamente (ruedas hacia abajo).
2. Limpiar archivos temporales `assets/icon_rotated.png` y `assets/icon_upright.png`.

---

## 3. Plan de Verificación y Entrega
1. **Pruebas Automatizadas:**
   - Ejecutar `flutter test` para validar que todas las pruebas existentes sigan pasando.
   - Probar que no existan errores de análisis estático (`flutter analyze`).
2. **Validación Funcional:**
   - Probar el flujo de Login -> Sincronización automática -> Apertura de historial con datos descargados.
   - Probar el botón de descarga manual en el historial.
   - Verificar la orientación del logo en `LoginView`.
   - Validar visualmente la tarjeta de compras con datos largos (PIN, nombres extensos) para asegurar que no ocurran solapamientos ni desbordamientos.
