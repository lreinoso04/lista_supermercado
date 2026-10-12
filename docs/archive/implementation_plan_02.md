# Plan de Implementación: Mejoras Premium para SmartCart

Se han aceptado las mejoras propuestas. A continuación, el detalle técnico de cómo se implementará cada una.

## ⚠️ User Review Required

> [!IMPORTANT]
> **Modo Oscuro Completo:** Para implementar el Modo Oscuro de manera perfecta, cambiaré el esquema de colores de la aplicación para que no use "blanco" y "gris" estáticos, sino que se adapte al tema del sistema del teléfono (Si tu teléfono está en modo oscuro, la app se pondrá oscura automáticamente).
> **¿Estás de acuerdo con que la app siga el modo oscuro/claro del sistema de tu teléfono por defecto?**

## Cambios Propuestos

### 1. Autocompletado desde el Catálogo 🧠
Cuando agregues un producto por voz o teclado, la app buscará si ya lo compraste antes para autocompletar la categoría, precio y prioridad.

#### [MODIFY] `lib/views/agregar_voz_view.dart`
- Se modificará la función `_showGuardarDialog()` para consultar `provider.catalogo`.
- Si el producto coincide, se reescribirán las variables `_categoriaSeleccionada`, `_precioSeleccionado`, y `_prioridadSeleccionada` con los valores del historial antes de mostrar el diálogo.

### 2. Agrupación por Pasillos (Categorías) 🛒
La lista de compras se agrupará por categorías, facilitando la compra física.

#### [MODIFY] `lib/views/lista_compras_view.dart`
- Se reemplazará la lista plana por una agrupación de mapas `Map<String, List<Producto>>`.
- Se añadirán secciones con sus respectivos títulos y colores por cada categoría que tenga productos pendientes.
- Los productos dentro de cada categoría se ordenarán por prioridad (Alta, Media, Baja).

### 3. Gráficos de Gastos Mensuales 📊
Se añadirá un gráfico de barras visual y elegante en el Perfil para controlar el gasto.

#### [MODIFY] `lib/views/perfil_view.dart`
- Se consultará la base de datos para obtener `HistorialCompra`.
- Se creará un widget de gráfico de barras simple usando contenedores proporcionales que muestren el gasto de las últimas 5 compras o de las últimas 4 semanas.

### 4. Modo Oscuro y Haptic Feedback (Vibración) 🌙 📳
Se añadirá vibración al interactuar y soporte completo para Modo Oscuro.

#### [MODIFY] `lib/main.dart`
- Se agregará la definición de `darkTheme` usando Material 3.
#### [MODIFY] `lib/views/lista_compras_view.dart` & `lib/views/agregar_voz_view.dart` & `lib/views/perfil_view.dart` & `lib/views/historial_compras_view.dart`
- Reemplazo de colores duros (`kBlanco`, `kFondo`) por `Theme.of(context).colorScheme.surface`, etc.
- Adición de `HapticFeedback.lightImpact()` en los botones de "Check" (Comprado) y de "Agregar a la lista".

## Plan de Verificación
1. **Prueba Autocompletado:** Decir "Leche" (ya existente en la BD) y verificar que el diálogo ya venga con "Lácteos" preseleccionado.
2. **Prueba Agrupación:** Agregar "Pollo" (Carnes) y "Leche" (Lácteos) y verificar que en la lista de compras se vean dos secciones distintas.
3. **Prueba Gráficos:** Terminar una compra y revisar el Perfil para ver que la barra del gráfico se ha dibujado.
4. **Prueba Vibración/Oscuro:** Cambiar el teléfono a modo oscuro y ver la app. Presionar el check de un producto y sentir la vibración táctil.
