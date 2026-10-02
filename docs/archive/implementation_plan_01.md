# Plan de Implementación: Correcciones y Nuevas Funciones en SmartCart

Se han analizado los requerimientos y el código actual para proponer la siguiente solución.

## ⚠️ User Review Required (Preguntas Importantes)

> [!IMPORTANT]
> **Sobre los mensajes SMS:**
> En aplicaciones móviles (especialmente en iOS), no es posible enviar mensajes SMS automáticamente "en segundo plano" sin la intervención del usuario, a menos que se use un servicio de pago como Twilio. En Android se puede usar un paquete especial para enviar SMS de fondo, pero requiere permisos estrictos que Google Play suele rechazar a menos que sea la app de SMS por defecto.
> 
> **Pregunta 1:** ¿Deseas que la app **abra la aplicación de mensajes de texto (SMS)** de tu teléfono con el mensaje y el número ya escritos para que solo tengas que presionar "Enviar", o prefieres intentar el envío en segundo plano solo para Android? (La opción de abrir la app de mensajes es la más compatible y recomendada).
> 
> **Pregunta 2:** Para los SMS, ¿a qué número de teléfono se enviarán? ¿Deberíamos agregar un campo en el "Perfil" para guardar el número de teléfono (por ejemplo, el de tu pareja o familiar)?

> [!IMPORTANT]
> **Sobre el recordatorio:**
> ¿En qué momento exacto se debe enviar el recordatorio de la lista? ¿Debería haber un botón de "Enviar Recordatorio" en la pantalla de la lista, o se debe enviar automáticamente al agregar productos (si los mensajes están activos)?

## Cambios Propuestos

### 1. Corrección del Bug de Categorías (Dropdown muestra 'Otros')
**Problema detectado:** El proveedor de la lista (`ListaProvider`) se inicializa de forma "perezosa" (lazy). Cuando el usuario presiona "Agregar" por primera vez, el proveedor comienza a cargar las categorías desde la base de datos de manera asíncrona, por lo que la lista está vacía en ese milisegundo y solo muestra "Otros". En el segundo intento, ya cargó y muestra todas.
**Solución:** 
- Cambiar la inicialización en `main.dart` para que el proveedor se cree de inmediato (con `lazy: false`), asegurando que las categorías estén cargadas antes de que el usuario interactúe.

#### [MODIFY] `lib/main.dart`
- Configurar `lazy: false` en el `ChangeNotifierProvider` de `ListaProvider`.

### 2. Reutilizar Listas del Historial
**Problema detectado:** Falta la opción de volver a agregar los productos de una compra antigua.
**Solución:**
- Modificar `HistorialComprasView` para agregar un botón **"Reutilizar Lista"** en cada tarjeta del historial.
- Al presionar, se verificará si hay productos pendientes en la lista actual.
- Si hay productos: Mostrar un diálogo de confirmación (Sí/No) advirtiendo que esto sustituirá la lista actual.
  - **Sí:** Vacía la lista actual y carga los productos del historial.
  - **No:** Cancela la acción.
- Si la lista actual está vacía: Carga directamente los productos.

#### [MODIFY] `lib/views/historial_compras_view.dart`
- Añadir el botón "Reutilizar" y la lógica del diálogo de confirmación.
#### [MODIFY] `lib/providers/lista_provider.dart`
- Crear el método `cargarListaDesdeHistorial(HistorialCompra h, {bool sustituir = false})` para manejar la copia de los productos a la lista activa.

### 3. Recordatorios y Notificaciones por SMS
**Solución:**
- Añadir un campo de "Número de Teléfono" en `PerfilView` para saber a quién enviar los SMS.
- Usar el paquete `url_launcher` (o el que decidas en la respuesta a las preguntas) para enviar los SMS.
- Crear un botón rápido en `ListaComprasView` para "Enviar Recordatorio SMS".
- Al importar una lista (pegar código), lanzar automáticamente el SMS de confirmación indicando que la lista fue recibida.

#### [MODIFY] `lib/views/perfil_view.dart`
- Agregar campo para el número de teléfono.
#### [MODIFY] `lib/views/lista_compras_view.dart`
- Añadir función para disparar el SMS de recordatorio.
- Actualizar el flujo de "Importar Lista" para lanzar el SMS de recepción si la opción de mensajes está activa.

## Plan de Verificación
1. **Prueba manual del Bug 1:** Reiniciar la app y abrir inmediatamente el micrófono para agregar un producto; verificar que la lista de categorías esté completa.
2. **Prueba manual del Bug 2:** Ir al historial, seleccionar una compra vieja y reutilizarla. Comprobar que reemplaza o agrega los productos correctamente según la decisión en el diálogo.
3. **Prueba manual del Bug 3:** Configurar un número en el perfil, activar los mensajes, importar una lista y verificar que se inicie el flujo de SMS.

**Espero tus comentarios sobre las preguntas de la sección "User Review Required" para comenzar.**
