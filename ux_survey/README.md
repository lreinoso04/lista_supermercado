# 📋 Estudio de Mercado: Gestión Inteligente de Compras (SmartCart)

Este directorio contiene las herramientas de automatización y diseño estructurado para desplegar la encuesta de estudio de mercado y validación de Producto Mínimo Viable (MVP) para **SmartCart**, bajo el estándar de **Lurein-OptiMatrix Solutions**.

---

## 📂 Contenido del Directorio

1. **[create_survey.gs](file:///c:/Users/lrein/Desktop/Mis%20Proyectos/lista_supermercado/ux_survey/create_survey.gs)**: Código de automatización en **Google Apps Script** para desplegar el formulario en Google Forms con optimizaciones avanzadas de UX.
2. **[survey_structure.json](file:///c:/Users/lrein/Desktop/Mis%20Proyectos/lista_supermercado/ux_survey/survey_structure.json)**: Estructura de la encuesta en formato estructurado (JSON) para importaciones de bases de datos, integraciones externas o uso mediante la API REST de Google Forms.

---

## 🚀 UX Optimizado: Qué hace el Script Automáticamente

Para un estudio de mercado, la tasa de rebote (personas que abandonan la encuesta a la mitad) es crítica. Este script implementa automáticamente mejores prácticas para maximizar las respuestas completadas:

1. **Paginación Dinámica (3 Secciones Cortas):** La encuesta está dividida en 3 pantallas rápidas y enfocadas por tema, reduciendo el cansancio visual del encuestado (especialmente en teléfonos móviles).
2. **Barra de Progreso Integrada (`setProgressBar(true)`):** Muestra al encuestado de forma transparente cuánto le falta para terminar (menos de 2 minutos).
3. **Página de Agradecimiento Profesional (`setConfirmationMessage(...)`):** Genera un mensaje empático personalizado agradeciendo al usuario por apoyar un proyecto de innovación tecnológica y emprendimiento.
4. **Desactivación de Respuestas Múltiples Redundantes:** Desactiva la repetición innecesaria para asegurar respuestas limpias y de calidad.

---

## 🛠️ Instrucciones de Despliegue con Google Apps Script

Sigue estos sencillos pasos para crear y publicar el formulario automáticamente:

1. Accede a tu consola de **[Google Apps Script](https://script.google.com/)**.
2. Abre tu proyecto actual (o haz clic en **"Nuevo proyecto"**).
3. Borra el código anterior y pega el contenido completo de **[create_survey.gs](file:///c:/Users/lrein/Desktop/Mis%20Proyectos/lista_supermercado/ux_survey/create_survey.gs)**.
4. Presiona **Guardar (Ctrl + S)**.
5. Selecciona la función `createSmartCartUXForm` en el menú superior y pulsa **Ejecutar (Run)**.
6. Copia los nuevos enlaces de edición y de respuesta del registro de ejecución inferior.

---

## 📊 Plan de Análisis del MVP (Problem-Solution Fit)

Este diseño de encuesta responde directamente a la metodología Lean Startup para validar una idea de negocio:

### 1. Validación del Problema (Sección 1)
* **Objetivo:** Confirmar qué tan reales y frecuentes son las problemáticas que SmartCart busca solucionar (ej. olvidar artículos, salirse del presupuesto, incomodidad en tienda). Si un porcentaje alto experimenta estos dolores, el mercado está validado.

### 2. Validación de la Propuesta de Valor (Sección 2)
* **Dictado por Voz (Q4):** Evalúa la recepción del reconocimiento de voz offline.
* **Lectura TTS (Q5):** Mide el interés en usar la app en "modo manos libres" dentro de la tienda.
* **Clasificación por Pasillos (Q6):** Valida la propuesta de ahorro de tiempo.
* **Cálculo de Presupuesto (Q7):** Mide la disposición a usar la app para controlar el gasto real frente al presupuesto.
* **Modo Offline (Q8):** Valida el dolor derivado de la mala señal de red móvil en el interior de los supermercados.

### 3. Intención de Adopción (Sección 3)
* **Ratio de Conversión Teórico (Q9):** Evalúa la intención directa de descarga inmediata de la app.
* **Priorización de Características Futuras (Q10):** Permite priorizar la hoja de ruta de desarrollo del MVP según las necesidades reales del mercado (ej. si gana el escáner de códigos de barras, se desarrolla primero).
