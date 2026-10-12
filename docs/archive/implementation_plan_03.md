# Plan de Implementación: Listas Separadas y Escáner de Código de Barras

A continuación, presento la arquitectura técnica para las dos nuevas funcionalidades que has elegido.

## ⚠️ User Review Required (IMPORTANTE)

> [!WARNING]
> **Requisito de Windows (Modo Desarrollador):**
> Al intentar instalar el paquete de la cámara para el escáner de barras, el compilador de Windows detectó que no tienes activado el "Modo Desarrollador". Para que tu computadora pueda compilar el paquete de la cámara (que usa código C++), **debes activar el Modo Desarrollador en Windows**:
> 1. Abre Configuración en tu PC > Privacidad y Seguridad > Para programadores (o busca "Modo Desarrollador" en el botón Inicio).
> 2. Activa el interruptor "Modo para desarrolladores".
> 3. ¡Eso es todo! Confírmame cuando lo hayas hecho para no tener errores al compilar tu app.

## Cambios Propuestos

### 1. Lista Separada (Farmacia vs Supermercado) 💊🛒

#### [MODIFY] `lib/models/producto.dart`
- Se añadirá el campo `tipoLista` (String) al modelo de Producto (por defecto será `'supermercado'`).

#### [MODIFY] `lib/services/db_service.dart`
- Aumentaré la versión de la base de datos a `6`.
- Agregaré una instrucción SQL (`ALTER TABLE`) para agregar la columna `tipoLista` a tus productos existentes de forma que no pierdas ningún dato.

#### [MODIFY] `lib/providers/lista_provider.dart`
- Agregaré una variable `_listaActual` (que puede ser `'supermercado'` o `'farmacia'`).
- La lista de productos visibles ahora se filtrará según qué lista tienes seleccionada.
- Añadiré una función para alternar entre listas de manera instantánea.

#### [MODIFY] `lib/views/lista_compras_view.dart`
- En la barra superior (AppBar), añadiré un selector elegante (un SegmentedControl o botones) para que puedas cambiar con un solo toque entre "🛒 Supermercado" y "💊 Farmacia".

### 2. Escáner de Código de Barras 📷

#### [MODIFY] `pubspec.yaml`
- Los paquetes `simple_barcode_scanner` y `http` ya fueron inyectados en tu archivo de configuración.

#### [MODIFY] `lib/views/agregar_voz_view.dart`
- Se añadirá un botón grande de "Escanear Código de Barras" en la pestaña "Manual".
- Al presionar, abrirá la cámara utilizando el paquete de Flutter.
- Al detectar el código, la app se conectará silenciosamente a la API gratuita de **Open Food Facts** para obtener el nombre del producto exacto.
- Ese nombre llenará el campo de texto y activará el sistema de autocompletado inteligente que ya hicimos antes.

## Plan de Verificación
1. **Listas Múltiples:** Al entrar, veremos que puedes agregar un "Desodorante" estando en la pestaña Farmacia. Al cambiar a Supermercado, el desodorante desaparecerá (está en la otra lista).
2. **Escáner:** Apuntaremos la cámara al código de un producto real (ej. Galletas). La app debería leer el código y colocar "Galletas" en el título automáticamente consultando la base de datos global.
