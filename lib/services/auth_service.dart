import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  FirebaseAuth? _customAuth;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  void setAuthInstanceForTesting(FirebaseAuth auth) {
    _customAuth = auth;
  }

  bool _googleSignInInitialized = false;

  // --- Protección contra ataques de Fuerza Bruta ---
  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;
  static const int maxFailedAttempts = 3;
  static const int lockoutDurationSeconds = 30;

  /// Stream para escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  /// Usuario actual autenticado
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Indica si el usuario está autenticado
  bool get isAuthenticated {
    try {
      return _auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Comprueba si el inicio de sesión está temporalmente bloqueado por intentos fallidos
  bool isLoginLocked() {
    if (_lockoutUntil == null) return false;
    if (DateTime.now().isBefore(_lockoutUntil!)) {
      return true;
    }
    // Si ya expiró el bloqueo, restablecer
    _lockoutUntil = null;
    _failedLoginAttempts = 0;
    return false;
  }

  /// Retorna los segundos restantes del bloqueo temporal
  int getLockoutRemainingSeconds() {
    if (_lockoutUntil == null) return 0;
    final diff = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  /// Registra un intento fallido de inicio de sesión
  void recordFailedLoginAttempt() {
    _failedLoginAttempts++;
    if (_failedLoginAttempts >= maxFailedAttempts) {
      _lockoutUntil = DateTime.now().add(const Duration(seconds: lockoutDurationSeconds));
    }
  }

  /// Restablece los intentos fallidos al iniciar sesión con éxito
  void resetFailedLoginAttempts() {
    _failedLoginAttempts = 0;
    _lockoutUntil = null;
  }

  /// Inicializa GoogleSignIn si es necesario
  Future<void> _initGoogleSignIn() async {
    if (_googleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize();
      _googleSignInInitialized = true;
    } catch (e) {
      debugPrint("GoogleSignIn init warning: $e");
    }
  }

  /// Inicia sesión con correo electrónico y contraseña con protección de fuerza bruta
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (isLoginLocked()) {
      final secs = getLockoutRemainingSeconds();
      throw 'Acceso temporalmente bloqueado por múltiples intentos fallidos. Espera $secs segundos.';
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      resetFailedLoginAttempts();
      return credential;
    } on FirebaseAuthException catch (e) {
      recordFailedLoginAttempt();
      throw getReadableAuthError(e);
    } catch (e) {
      recordFailedLoginAttempt();
      throw 'Error inesperado al iniciar sesión: $e';
    }
  }

  /// Registra una nueva cuenta con correo y contraseña, y envía el correo de verificación
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        if (displayName != null && displayName.trim().isNotEmpty) {
          await user.updateDisplayName(displayName.trim());
        }
        // Enviar verificación de correo de forma obligatoria
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint("Error al enviar correo de verificación inicial: $e");
        }
        await user.reload();
      }

      resetFailedLoginAttempts();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw getReadableAuthError(e);
    } catch (e) {
      throw 'Error inesperado al registrar usuario: $e';
    }
  }

  /// Envía manualmente el correo de verificación al usuario activo
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Recarga el usuario y verifica si el correo ya ha sido confirmado
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      final updatedUser = _auth.currentUser;
      return updatedUser?.emailVerified ?? false;
    }
    return false;
  }

  /// Envía un correo de recuperación de contraseña
  Future<void> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw getReadableAuthError(e);
    } catch (e) {
      throw 'Error al enviar recuperación de contraseña: $e';
    }
  }

  /// Inicia sesión con Google
  /// En Web utiliza popup con GoogleAuthProvider.
  /// En Android/iOS utiliza el flujo nativo con google_sign_in.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        final cred = await _auth.signInWithPopup(googleProvider);
        resetFailedLoginAttempts();
        return cred;
      }

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw 'El inicio de sesión interactivo con Google no es compatible con este dispositivo. Usa correo y contraseña.';
      }

      await _initGoogleSignIn();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      final GoogleSignInClientAuthorization? authz =
          await account.authorizationClient.authorizationForScopes(['email']);

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: authz?.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      resetFailedLoginAttempts();
      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null; // El usuario canceló la selección de cuenta
      }
      debugPrint("GoogleSignInException: ${e.code} - ${e.description}");
      throw _getReadableGoogleError(e.code.toString());
    } on FirebaseAuthException catch (e) {
      throw getReadableAuthError(e);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('canceled') || msg.contains('cancelled')) {
        return null;
      }
      if (msg.contains('10') || msg.contains('DEVELOPER_ERROR')) {
        throw 'Error de configuración: Falta registrar la huella SHA-1 en Firebase Console para Google Sign-In.';
      }
      throw 'Error al iniciar sesión con Google: $e';
    }
  }

  /// Cierra la sesión activa
  Future<void> signOut() async {
    try {
      if (!kIsWeb && GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (e) {
      debugPrint("Error al cerrar sesión en Google: $e");
    }
    await _auth.signOut();
  }

  /// Traduce los códigos de error de FirebaseAuth a mensajes claros en español
  static String getReadableAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe ninguna cuenta registrada con este correo electrónico.';
      case 'wrong-password':
        return 'La contraseña ingresada es incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos. Por favor verifica tus datos.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo. Prueba iniciando sesión.';
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 8 caracteres, con mayúsculas y números.';
      case 'user-disabled':
        return 'Esta cuenta ha sido inhabilitada por un administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Tu cuenta ha sido bloqueada temporalmente. Espera unos momentos.';
      case 'operation-not-allowed':
        return 'El proveedor de inicio de sesión no está habilitado en Firebase Console.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu conexión a internet e inténtalo de nuevo.';
      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta vinculada a este correo con otro método de acceso.';
      default:
        return e.message ?? 'Ocurrió un error con la autenticación (${e.code}).';
    }
  }

  /// Traduce errores de Google Sign In
  static String _getReadableGoogleError(String code) {
    if (code.contains('canceled')) {
      return 'Inicio de sesión cancelado.';
    }
    if (code.contains('10') || code.contains('developerError')) {
      return 'Falta registrar el certificado SHA-1 de la app en Firebase Console.';
    }
    return 'No se pudo completar el inicio de sesión con Google ($code).';
  }
}
