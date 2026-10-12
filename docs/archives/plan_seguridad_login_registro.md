# Plan de Implementación: Blindaje y Seguridad del Sistema de Autenticación en SmartCart

## Descripción del Objetivo

El objetivo de esta intervención es fortalecer la seguridad del sistema de acceso y registro de **SmartCart** antes de avanzar con la reestructuración general de la arquitectura. Se implementará una defensa en profundidad que mitigue ataques automatizados (bots, fuerza bruta, spam de cuentas falsas) y proteja la base de datos de usuarios e información en Firestore.

### Mejoras a Implementar:
1. **Verificación de Correo Electrónico:** Envío automático de correo de confirmación al registrarse, pantalla dedicada de validación de email con temporizador para reenvíos y bloqueo de acceso a la app si el correo no está verificado (las cuentas de Google quedan verificadas automáticamente).
2. **Protección Anti-Bot y reCAPTCHA en Registro:** Desafío de validación humana para evitar creación masiva de cuentas por scripts maliciosos, campo *honeypot* invisible para atrapar scrapers automáticos y guía de integración con Firebase App Check (reCAPTCHA / Play Integrity).
3. **Seguridad Adicional Recomendada:**
   - **Medidor y política de contraseñas robustas:** Mínimo 8 caracteres, combinación de mayúsculas, minúsculas y números con indicador visual de fortaleza en tiempo real.
   - **Mitigación de ataques de fuerza bruta:** Bloqueo temporal exponencial (cooldown de 30-60s) tras 3 intentos consecutivos fallidos de inicio de sesión.
   - **Sanitización estricta de entradas:** Limpieza de espacios, normalización a minúsculas y validación rigurosa de formato.
   - **Reglas de seguridad para Firestore:** Recomendación de reglas que exijan `request.auth.token.email_verified == true`.

---

## Revisión del Usuario Requerida

> [!IMPORTANT]
> **Comportamiento de Cuentas Existentes y Cuentas de Google**
> - **Cuentas de Google:** Google ya certifica el correo como verificado (`user.emailVerified == true`), por lo que los usuarios que inicien sesión con Google entrarán directamente sin interrupciones.
> - **Cuentas creadas por Correo/Contraseña:** Se requerirá que hagan clic en el enlace enviado a su correo antes de poder acceder a las listas de compras.

> [!WARNING]
> **Método de Captcha y Anti-Bot**
> Para garantizar que la protección funcione tanto en **Android**, **Web** como en **Windows** sin requerir llaves de pago o dependencias de webviews pesadas que puedan fallar en emuladores locales, implementaremos:
> 1. Un **Widget interactivo de Verificación Humana (Human Verification Challenge)** nativo y reactivo en el formulario de registro.
> 2. Técnica **Honeypot** (campo trampa oculto que los bots llenan pero los usuarios reales no ven).
> 3. Limitador de tasa (*Rate Limiter*) por cliente para evitar envíos repetitivos en ráfaga.
> 4. Adicionalmente, documentaremos cómo activar **Firebase App Check** en Firebase Console para blindar Firestore a nivel de servidor.

---

## Preguntas Abiertas

> [!TIP]
> ¿Deseas que los usuarios en **Modo Invitado** mantengan acceso a la app sin verificar correo (limitando su almacenamiento solo a SQLite local), o prefieres que el registro/login sea obligatorio para todos los usuarios?
> *(La propuesta actual mantiene el Modo Invitado restringido únicamente a datos locales en el dispositivo, sin acceso a Firestore remoto).*

---

## Diagrama de Flujo de Autenticación Segura

```mermaid
flowchart TD
    Inicio([Usuario inicia la app]) --> Gate{¿Está autenticado?}
    
    Gate -->|No| Login[LoginView]
    Gate -->|Sí| ProviderCheck{¿Es cuenta Google?}
    
    ProviderCheck -->|Sí| AppPrincipal[MainNavigation: Acceso Completo]
    ProviderCheck -->|No| EmailVerified{¿emailVerified == true?}
    
    EmailVerified -->|Sí| AppPrincipal
    EmailVerified -->|No| PantallaVerificacion[EmailVerificationView]
    
    PantallaVerificacion -->|Pulsar 'Ya lo verifiqué'| ReloadUser[user.reload()]
    ReloadUser --> EmailVerified
    PantallaVerificacion -->|Pulsar 'Reenviar'| ResendEmail[sendEmailVerification() + Cooldown 60s]
    PantallaVerificacion -->|Pulsar 'Cerrar Sesión'| Logout[AuthService.signOut()] --> Login

    subgraph RegistroSeguro["Flujo de Registro con Blindaje"]
        Formulario[Llenar formulario] --> CheckHoneypot{¿Honeypot vacío?}
        CheckHoneypot -->|No (Bot detectado)| DropSilent[Rechazo silencioso]
        CheckHoneypot -->|Sí| CheckPassword{¿Contraseña segura >= 8 car?}
        CheckPassword -->|No| ErrorPassword[Solicitar mayúscula + número]
        CheckPassword -->|Sí| CaptchaCheck{¿Verificación Humana Resuelta?}
        CaptchaCheck -->|No| ErrorCaptcha[Resolver verificación]
        CaptchaCheck -->|Sí| FirebaseCreate[FirebaseAuth.createUser]
        FirebaseCreate --> SendVerification[user.sendEmailVerification()]
        SendVerification --> PantallaVerificacion
    end
```

---

## Cambios Propuestos

### 1. Capa de Servicios: Seguridad y Verificación

#### [MODIFY] `lib/services/auth_service.dart`
- Agregar método `sendEmailVerification()`:
  ```dart
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
  ```
- Agregar método `checkEmailVerified()`:
  ```dart
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    }
    return false;
  }
  ```
- Modificar `registerWithEmail`:
  - Enviar inmediatamente la verificación tras crear el usuario.
- Agregar control de **ataques de fuerza bruta** (Rate Limiter / Cooldown temporal de login en memoria o SharedPreferences tras 3 intentos errados).

---

### 2. Capa de Widgets y Vistas: Verificación y Captcha

#### [NEW] `lib/widgets/human_verification_tile.dart`
- Widget interactivo de verificación humana para el formulario de registro:
  - Checkbox interactivo estilo reCAPTCHA con desafío visual dinámico (validación de clic consciente / patrón seguro).
  - Estado: no resuelto, verificando con animación, resuelto con éxito.
  - Bloquea el botón "Crear Cuenta" hasta que el usuario complete la interacción.

#### [NEW] `lib/views/email_verification_view.dart`
- Pantalla elegante que se presenta cuando el usuario tiene la sesión iniciada pero aún no ha validado su correo electrónico:
  - Ilustración/ícono animado de correo pendiente.
  - Correo electrónico del usuario resaltado.
  - Botón principal **"Ya verifiqué mi correo"** (recarga el usuario y le da paso inmediato a la aplicación).
  - Botón secundario **"Reenviar correo de confirmación"** con temporizador regresivo de 60 segundos para evitar abusos del servicio SMTP.
  - Botón de escape **"Cerrar sesión / Usar otro correo"**.

#### [MODIFY] `lib/views/login_view.dart`
- **Indicador de Fortaleza de Contraseña:** Barra de 3 niveles (Débil, Media, Fuerte) con validación de mayúsculas, minúsculas y números.
- **Campo Honeypot oculto:** Un campo invisible para usuarios reales. Si un bot autocompleta todos los inputs, el sistema detecta el campo trampa y aborta el registro.
- **Protección contra Fuerza Bruta:** Contador de intentos fallidos en login; al 3er intento erróneo activa un bloqueo temporal con cuenta regresiva.
- **Integración de `HumanVerificationTile`** en la pestaña de registro.

#### [MODIFY] `lib/widgets/auth_gate.dart`
- Actualizar la lógica del Gate:
  ```dart
  if (snapshot.hasData && snapshot.data != null) {
    final user = snapshot.data!;
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    
    // Si no es Google y no ha verificado su correo, retener en EmailVerificationView
    if (!user.emailVerified && !isGoogle) {
      return const EmailVerificationView();
    }
    
    return const MainNavigation();
  }
  ```

#### [MODIFY] `lib/views/perfil_view.dart`
- En el perfil del usuario, si la cuenta es por correo pero está pendiente de verificar (o recientemente verificada), mostrar el indicador de verificación en tiempo real con opción de reenvío si fuera necesario.

---

### 3. Pruebas Automatizadas

#### [NEW] `test/security_auth_test.dart`
- Prueba de la lógica de validación de contraseñas robustas (mayúsculas, minúsculas, números, longitud >= 8).
- Prueba del limitador de fuerza bruta y cooldown temporal.
- Prueba del detector de campo trampa (*honeypot*).
- Prueba de renderizado y estados de `HumanVerificationTile`.

---

## Plan de Verificación

### Pruebas Automatizadas
1. **Análisis Estático:**
   ```powershell
   flutter analyze
   ```
   *Criterio de éxito:* 0 errores y 0 advertencias (`No issues found!`).

2. **Ejecución de Pruebas Unitarias y de Widgets:**
   ```powershell
   flutter test
   ```
   *Criterio de éxito:* Todas las pruebas pasadas incluyendo las nuevas pruebas de seguridad.

### Verificación Manual
1. **Flujo de Registro Seguro:**
   - Intentar registrarse con contraseña débil (< 8 caracteres o sin números) -> Verificar que el medidor y validador alerten al usuario.
   - Intentar registrarse sin completar la verificación humana -> El botón permanece inhabilitado o solicita completar el captcha.
   - Registrarse con datos válidos -> La app debe mostrar la pantalla de `EmailVerificationView` y confirmar que se envió el correo.
2. **Flujo de Verificación de Correo:**
   - En `EmailVerificationView`, pulsar "Reenviar correo" -> Comprobar que inicia el temporizador de 60 segundos y se desactiva temporalmente el botón.
   - Pulsar "Ya verifiqué mi correo" (sin verificar en el email) -> Muestra aviso de que el correo sigue pendiente de confirmación.
   - Tras hacer clic en el enlace recibido en el correo, pulsar "Ya verifiqué mi correo" -> Acceso inmediato a la lista de compras.
3. **Flujo de Fuerza Bruta en Login:**
   - Ingresar contraseña incorrecta 3 veces consecutivas -> Comprobar que se activa el bloqueo temporal de 30 segundos impidiendo nuevos intentos hasta que el temporizador llegue a cero.
4. **Acceso con Google:**
   - Iniciar sesión con Google -> Comprobar que entra directamente sin pasar por la pantalla de verificación, ya que Google certifica la identidad.
