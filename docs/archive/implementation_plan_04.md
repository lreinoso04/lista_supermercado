# Plan de Implementación: Listas en Tiempo Real con Firebase ☁️

Este es el plan definitivo para transformar tu aplicación a un sistema sincronizado en la nube. Con esto, dejaremos atrás los códigos Base64 largos y usaremos "Pines de Sincronización" cortos (ej. `A4X98B`).

## ⚠️ User Review Required (Pasos a seguir en tu pantalla)

Veo que estás en la pantalla principal de bienvenida. Vamos a crear el proyecto y la base de datos paso a paso:

> [!IMPORTANT]
> **Paso 1: Crear el Proyecto**
> 1. En la pantalla que me enviaste, haz clic en el cuadro grande de la izquierda: **"Para comenzar, configura un proyecto de Firebase"**.
> 2. Escribe el nombre del proyecto: **SmartCart** (marca la casilla de aceptar términos si te aparece) y haz clic en "Continuar".
> 3. Te preguntará si quieres habilitar Google Analytics. Por ahora **desactívalo** (apaga el interruptor) para hacerlo más rápido y dale a **"Crear proyecto"**.
> 4. Espera a que termine de cargar y dale a "Continuar". Serás redirigido al panel de control de tu nuevo proyecto.

> [!IMPORTANT]
> **Paso 2: Crear la Base de Datos (Firestore)**
> 1. En el menú lateral izquierdo de tu pantalla, haz clic para expandir la sección **"Compilación"** (o "Build" si está en inglés).
> 2. Haz clic en **"Firestore Database"**.
> 3. Presiona el botón **"Crear base de datos"**.
> 4. Te pedirá una ubicación. Deja la que viene por defecto y dale a "Siguiente".
> 5. **(¡Súper Importante!)** Te preguntará sobre las reglas de seguridad. Elige la opción **"Comenzar en modo de prueba"** (Start in test mode) y haz clic en "Habilitar" o "Crear".

¡Y listo! Ya creaste la base de datos en la nube. **Avísame cuando hayas completado estos 2 pasos**. Yo me encargaré desde aquí de conectar el código de tu computadora a la nube usando las herramientas de Flutter.

---

## Cambios Arquitectónicos Propuestos (Lo que haré yo)

### [NEW] `lib/services/firebase_service.dart`
- Crearé un servicio que se conecte directamente a Firestore para leer y escribir productos en tiempo real.
- Generará un código corto de 6 caracteres único para cada "Sala" o "Lista compartida".

### [MODIFY] `lib/providers/lista_provider.dart`
- Integraré un "Stream" (flujo de datos). Esto significa que la app estará "escuchando" a la nube 24/7. Si alguien más marca un producto en su teléfono, tu `ListaProvider` se actualizará solo al instante.
- Mantendremos la base de datos local (SQLite) como respaldo offline.

### [MODIFY] `lib/views/lista_compras_view.dart`
- Actualizaré el botón de "Compartir" para que, en lugar de generar un archivo largo, simplemente te muestre el PIN corto de tu lista actual.
- Actualizaré el botón de "Recibir" para que solo te pida ingresar el PIN corto y conectarte.

### [MODIFY] `pubspec.yaml`
- Añadiré los paquetes oficiales: `firebase_core` y `cloud_firestore`.

## Plan de Verificación
1. Obtendremos el PIN corto de tu lista.
2. Ingresaremos el PIN en otra instancia (o simulando la importación).
3. Verificaremos que al agregar "Manzanas", aparezca instantáneamente en la base de datos de Firestore en tu navegador.
