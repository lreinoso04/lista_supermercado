# 🛒 SmartCart (`lista_supermercado`)

> **Aplicación móvil inteligente para la gestión, control presupuestario y compras colaborativas de supermercado y farmacia.**

---

## 🌟 Características Principales

* **Entrada Multimodal:** Agrega productos por **Voz (Speech to Text)**, teclado o escaneo de **Código de Barras** (con auto-búsqueda en Open Food Facts).
* **Lectura en Voz Alta (TTS):** Modo manos libres para escuchar tu lista de pendientes en la tienda.
* **Memoria Inteligente (Catálogo):** Recuerda automáticamente la categoría, prioridad y precios estimados de productos comprados anteriormente.
* **Control de Presupuesto:** Cálculo de gasto en tiempo real, barra de progreso y resumen estadístico.
* **Sincronización Dual:**
  * **En vivo (Firebase Firestore):** Colabora en tiempo real con familiares mediante un PIN único de 6 caracteres.
  * **Offline-First (SQLite):** Funciona al 100% sin internet, con opción de exportar/importar listas mediante código Base64.
* **Historial Detallado:** Facturas digitales de compras pasadas y opción de reutilizar listas antiguas.

---

## 📚 Documentación del Proyecto

| Documento | Ubicación | Descripción |
|---|---|---|
| **Contexto Técnico y Guía para Agentes** | [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) | **Fuente única de verdad.** Arquitectura completa, esquema de BD (SQLite v7 / Firestore), reglas de oro e invariantes del sistema. |
| **Informe Técnico y Funcional** | [docs/Informe_SmartCart.md](./docs/Informe_SmartCart.md) | Resumen funcional de cara al usuario y detalles técnicos de versiones previas. |
| **Planes de Implementación Históricos** | [docs/archive/](./docs/archive/) | Registro histórico de planes ejecutados (01 al 04). |
| **Estudio de Mercado y UX** | [ux_survey/README.md](./ux_survey/README.md) | Formulario automatizado en Google Apps Script y validación Lean Startup del MVP. |

---

## 🚀 Inicio Rápido

### Requisitos
* Flutter SDK `^3.11.1`
* Android Studio / Xcode / VS Code o Antigravity IDE

### Comandos Comunes
```bash
# Obtener paquetes
flutter pub get

# Ejecutar pruebas unitarias
flutter test

# Ejecutar la app
flutter run
```
