/**
 * Google Apps Script for Google Forms Deployment - MVP Market Study Version
 * Project: Estudio de Mercado: Gestión Inteligente de Compras (SmartCart)
 * Designed by: SmartCart Entrepreneurship Team / Lurein-OptiMatrix Solutions
 * File: create_survey.gs
 * 
 * Instructions:
 * 1. Go to https://script.google.com/
 * 2. Open your Google Apps Script project.
 * 3. Delete the previous code and paste this new script.
 * 4. Save (Ctrl + S) and click "Run" (play icon).
 * 5. Verify the generated Links in the Execution Log at the bottom.
 */

function createSmartCartUXForm() {
  var formTitle = 'Estudio de Mercado: Gestión Inteligente de Compras (SmartCart)';
  var formDescription = '¡Hola! Somos un equipo de emprendedores y estamos participando en un proyecto de innovación tecnológica. Nos encantaría contar con tu ayuda. Diseñamos esta breve encuesta para validar una idea de negocio que busca transformar la experiencia diaria de hacer las compras del hogar, haciéndola más rápida, eficiente y 100% inclusiva. Te tomará menos de 2 minutos completarla y tu opinión es vital para que este proyecto de emprendimiento pueda hacerse realidad. ¡Muchas gracias por tu valioso apoyo!';
  
  Logger.log('Initializing Google Form creation for Market Study...');
  var form = FormApp.create(formTitle);
  form.setDescription(formDescription);
  
  // UX Configurations
  form.setAllowResponseEdits(false)
      .setPublishingSummary(false)
      .setShowLinkToRespondAgain(false) // Market studies don't usually need a "Submit another response" link
      .setProgressBar(true) // Show user progress bar at the bottom
      .setConfirmationMessage('¡Muchas gracias por tu participación! Tus respuestas han sido registradas y nos ayudarán enormemente a validar este proyecto de emprendimiento. ¡Que tengas un excelente día!');

  // =========================================================================
  // SECCIÓN 1: Hábitos de Compra y Problemáticas Actuales
  // =========================================================================
  Logger.log('Adding Section 1...');
  var section1Header = form.addSectionHeaderItem();
  section1Header.setTitle('SECCIÓN 1: Hábitos de Compra y Problemáticas Actuales');
  section1Header.setHelpText('Ayúdanos a entender cómo organizas tus compras actualmente y a qué retos te enfrentas.');

  // Pregunta 1: Encargado de compras (Opción múltiple, Obligatoria)
  var q1 = form.addMultipleChoiceItem();
  q1.setTitle('¿Quién suele encargarse de planificar y realizar las compras del supermercado en tu hogar?')
    .setChoiceValues([
      'Yo principalmente', 
      'Compartido con mi familia/pareja', 
      'Alguien externo al hogar'
    ])
    .setRequired(true);

  // Pregunta 2: Método para anotar (Opción múltiple, Obligatoria)
  var q2 = form.addMultipleChoiceItem();
  q2.setTitle('¿Qué método utilizas más para anotar los productos que necesitas comprar?')
    .setChoiceValues([
      'Lista en papel o notas físicas', 
      'Bloc de notas en el celular', 
      'Aplicaciones móviles de listas', 
      'Ninguno (confío en mi memoria)'
    ])
    .setRequired(true);

  // Pregunta 3: Problemática frecuente (Opción múltiple, Obligatoria)
  var q3 = form.addMultipleChoiceItem();
  q3.setTitle('Al momento de estar en el supermercado, ¿cuál de estos problemas experimentas con mayor frecuencia?')
    .setChoiceValues([
      'Olvidar algún artículo que necesitaba', 
      'Comprar cosas duplicadas o de más', 
      'Exceder el presupuesto que tenía pensado', 
      'Incomodidad para revisar la lista mientras cargo el carrito'
    ])
    .setRequired(true);

  // =========================================================================
  // SECCIÓN 2: Validación de las Soluciones de SmartCart
  // =========================================================================
  Logger.log('Adding Section 2...');
  var section2 = form.addPageBreakItem();
  section2.setTitle('SECCIÓN 2: Validación de las Soluciones de SmartCart');
  section2.setHelpText('Imagina una aplicación móvil gratuita que te permita armar y gestionar tus compras de la siguiente manera. Cuéntanos qué opinas:');

  // Pregunta 4: Dictado por voz (Escala lineal 1-5, Obligatoria)
  var q4 = form.addScaleItem();
  q4.setTitle('¿Qué tan útil te parecería poder agregar productos a tu lista simplemente dictándolos por voz (sin tener que escribir)?')
    .setBounds(1, 5)
    .setLabels('Nada útil', 'Muy útil')
    .setRequired(true);

  // Pregunta 5: Lectura en voz alta TTS (Opción múltiple, Obligatoria)
  var q5 = form.addMultipleChoiceItem();
  q5.setTitle('¿Usarías una función que te lea la lista en voz alta para repasar tus productos mientras caminas por los pasillos sin mirar la pantalla?')
    .setChoiceValues([
      'Sí, la usaría siempre', 
      'Tal vez en ocasiones', 
      'No la utilizaría'
    ])
    .setRequired(true);

  // Pregunta 6: Organización automática por pasillos (Opción múltiple, Obligatoria)
  var q6 = form.addMultipleChoiceItem();
  q6.setTitle('¿Te interesaría que la app ordene tus productos automáticamente por pasillos/categorías (ej. lácteos, carnes, limpieza) para ahorrarte tiempo en el recorrido?')
    .setChoiceValues([
      'Sí, me ahorraría mucho tiempo', 
      'Me da igual', 
      'No lo veo necesario'
    ])
    .setRequired(true);

  // Pregunta 7: Presupuesto estimado (Escala lineal 1-5, Obligatoria)
  var q7 = form.addScaleItem();
  q7.setTitle('¿Qué tan valioso sería para ti que la app calcule un presupuesto estimado de tu compra antes de llegar a la caja?')
    .setBounds(1, 5)
    .setLabels('Poco valioso', 'Muy valioso')
    .setRequired(true);

  // Pregunta 8: Funcionamiento Offline SQLite (Opción múltiple, Obligatoria)
  var q8 = form.addMultipleChoiceItem();
  q8.setTitle('La app funciona 100% de forma local, por lo que puedes usarla dentro del supermercado aunque no tengas internet o señal. ¿Qué opinas de esto?')
    .setChoiceValues([
      'Es excelente y muy necesario', 
      'Es útil, pero no indispensable', 
      'No me es relevante'
    ])
    .setRequired(true);

  // =========================================================================
  // SECCIÓN 3: Intención de Uso y Adopción
  // =========================================================================
  Logger.log('Adding Section 3...');
  var section3 = form.addPageBreakItem();
  section3.setTitle('SECCIÓN 3: Intención de Uso y Adopción');
  section3.setHelpText('Finalmente, cuéntanos si estarías dispuesto/a a usar la aplicación en el futuro.');

  // Pregunta 9: Descarga inicial (Opción múltiple, Obligatoria)
  var q9 = form.addMultipleChoiceItem();
  q9.setTitle('Si esta aplicación estuviera disponible hoy mismo en las tiendas (Google Play / App Store), ¿la descargarías para probarla?')
    .setChoiceValues([
      'Sí, definitivamente', 
      'Tal vez lo consideraría', 
      'No la descargaría'
    ])
    .setRequired(true);

  // Pregunta 10: Características futuras (Casillas, NO obligatoria)
  var q10 = form.addCheckboxItem();
  q10.setTitle('En un futuro, ¿qué característica adicional haría que uses esta app todos los días?')
     .setChoiceValues([
       'Escanear el código de barra de los productos en casa', 
       'Comparar los precios entre diferentes supermercados', 
       'Compartir y editar la lista con mi familia en tiempo real'
     ])
     .setRequired(false);

  // Pregunta 11: Comentarios abiertos / Sugerencias (Párrafo, NO obligatoria)
  var q11 = form.addParagraphTextItem();
  q11.setTitle('¿Tienes alguna sugerencia o idea que debamos tomar en cuenta para este proyecto de emprendimiento?')
     .setRequired(false);

  // Success Logging
  Logger.log('========================================================================');
  Logger.log('🚀 ¡NUEVO FORMULARIO DE ESTUDIO DE MERCADO CREADO CON ÉXITO!');
  Logger.log('========================================================================');
  Logger.log('Título: ' + form.getTitle());
  Logger.log('Enlace de Edición (Admin): ' + form.getEditUrl());
  Logger.log('Enlace para Responder (Público): ' + form.getPublishedUrl());
  Logger.log('ID único de Google Form: ' + form.getId());
  Logger.log('========================================================================');
  
  return {
    editUrl: form.getEditUrl(),
    publishedUrl: form.getPublishedUrl(),
    formId: form.getId()
  };
}
