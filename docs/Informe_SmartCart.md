# 🛒 Informe Técnico y Funcional: SmartCart

Este documento detalla el alcance, las características y la arquitectura interna de **SmartCart**, una aplicación inteligente diseñada para gestionar listas de supermercado.

---

## 1. Resumen No Técnico (Para Usuarios/Clientes)

**SmartCart** es una aplicación móvil diseñada para facilitar, organizar y optimizar las compras del supermercado. No es un simple "bloc de notas", sino una herramienta predictiva que ayuda a los usuarios a llevar el control total de sus gastos y requerimientos.

### Capacidades Principales (¿Qué hace en su totalidad?):
* **Escritura y Voz:** Puedes agregar artículos manualmente o usar el micrófono para que la aplicación transcriba lo que necesitas comprar.
* **Lectura Automática (TTS):** Dispone de un botón que **lee tu lista en voz alta**, ideal para cuando estás empujando el carrito en el supermercado y no quieres mirar la pantalla.
* **Organización Categorizada:** Los productos se dividen por áreas del supermercado (Lácteos, Carnes, Limpieza, etc.) y prioridades (Alta, Media, Baja).
* **Control de Presupuesto:** Puedes ponerle a cada producto un precio estimado. La aplicación tiene una barra de progreso inteligente que calcula al instante cuánto de tu carrito ya está asegurado y cuánto dinero llevas gastado de manera dinámica.
* **Memoria Fotográfica (Catálogo):** Todo lo que agregas a la lista (como "Leche Descremada") se queda guardado en la memoria profunda de la aplicación. La próxima vez, la app ya conocerá el producto, su categoría, y su posible precio.
* **Historial Detallado:** Al pulsar "Terminar Compra", todo tu carrito pasa por una banda y queda registrado. Tienes un panel de Historial que muestra el monto total que pagaste cada vez que fuiste de compras; si despliegas una fecha en particular, te mostrará la factura exacta (qué llevaste, a qué precio y cuántos).

---

## 2. Lo Nuevo (Agregado Recientemente)

Las siguientes funciones fueron las implementadas a través de la reestructuración profunda en las capas lógicas y visuales:

1. **Desglose de Historial con Modal Inteligente.** Antes, el historial solo mostraba un gasto total y una fecha. Ahora, los usuarios disponen de botones explícitos para **Ver** o **Eliminar**. Al darle a *"Ver"*, emerge desde abajo una hoja (*Bottom Sheet*) altamente estilizada listando ítem por ítem todo lo que facturaste ese día.
2. **Selección Activa para la Compra.** Al "Terminar Compra", la aplicación ya **no borra todos tus productos**. Ahora, discierne sabiamente qué productos sí lograste comprar (los que tienen el '✔' verde anotado) y cuáles quedaron pedientes. Los productos comprados se empaquetan y viajan al historial, mientras que los pendientes te siguen esperando en la lista para tu próxima vuelta al supermercado.
3. **Purgado de Historial Controlado.** Inclusión nativa de una opción *"Eliminar"* en la vista de historial que muestra una alerta cautelar y luego permite borrar registros antiguos para mantener fresca tu base de datos.
4. **Motor Inmortal de Migración.** Para lograr el punto 1, tuvimos que forjear las bases de la memoria del teléfono pasando a una arquitectura que permitiera guardar estructuras completas utilizando la codificación `JSON` internamente.

---

## 3. Detalles Técnicos (Para Desarrolladores/Revisores)

El proyecto está desarrollado bajo **Flutter** (Dart) con una arquitectura escalable MVC-Like.

### Tecnologías Clave:
* **UI/UX:** Flutter Framework, diseño minimalista adaptado en `Material Design 3` usando paletas de colores armónicas construidas en utilidades estáticas. Widgets clave implementados: `InkWell` para toque natural, `Dismissible` para efecto "swipe", `DraggableScrollableSheet` para modales y `AnimatedContainer` para variaciones suaves de estado.
* **Gestión de Estado Centralizada:** **Provider** (`ChangeNotifier`). Existe un `ListaProvider` que manipula el árbol de lógica aislado respecto a los `ListBuilder` interactivos; lo que permite que varios widgets escuchen cambios y varíen instantáneamente sin recargar toda la ventana.
* **Persistencia Relacional Local:** **SQLite** vía el plugin `sqflite`. No se usan dependencias online, todo el comportamiento vive con integridad en cachés locales de larga duración.
* **Servicios de SO (Device Capabilities):** `speech_to_text` (Reconocimiento del habla hacia texto) y `flutter_tts` (Text-To-Speech) asincrónico atado a handlers de fin del callback.

### Arquitectura de Base de Datos (DBService)
La aplicación maneja un esquema en control de versión con migraciones `onUpgrade`. La base `supermercado.db` se encuentra emparejada mediante 3 tablas cardinales construidas con sentencias `IF NOT EXISTS`:

1. **Tabla `productos`**: Actúa temporalmente, almacenando el carrito local.
2. **Tabla `catalogo`**: Una tabla de sugerencias. Guarda cada `upsert` que se haya procesado para auto-relleno local.
3. **Tabla `historial_compras`**: Modificada a la v4. Registra los metadatos de compra (`fecha`, `total`). La reciente integración del campo `productosJson TEXT` guarda de manera serializada a memoria blanda la lista completa de objetos `Producto` comprados (`jsonEncode`), lo cual rompió limitantes de 1-N sin tener que forzar múltiples tablas en SQLite y cruzar claves primarias de gran envergadura innecesariamente. 

### Patrón Lógico del Check-Out (`terminarCompra`)
Se ejecuta sin aserción pesada: hace un barrido a través de `List.where((p) => p.comprado)`. 
A nivel CRUD: 
1. Transcodifica la sub-lista filtrada a `JSON`.
2. Lanza una promesa `upsertCatalogo` individual por producto hacia el catálogo para entrenar a la base de datos de los gustos y modificaciones recientes.
3. Lo remueve estáticamente con un `delete` y recarga limpiamente el framework de la UI invocando `notifyListeners()`. 

Esta lógica modular proporciona la mejor sinergia entre fiabilidad y velocidad de redibujo (`60 FPS` garantizados durante la gestión transaccional).
