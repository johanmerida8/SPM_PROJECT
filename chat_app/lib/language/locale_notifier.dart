import 'package:flutter/foundation.dart';


class LanguageNotifier extends ChangeNotifier {
  String? _currentLanguage;

  LanguageNotifier(this._currentLanguage);

  String? get currentLocale => _currentLanguage;

  void change(String newLanguage) {
    _currentLanguage = newLanguage;
    notifyListeners();
  }

  static Map<String, Map<String, String>> translations = {
  'en': {
    "welcome": "Welcome",
    "signin": "Sign In",
    "signing": "Signing in...",
    "signingup": "Signing up...",
    "backToLogin": "Back to Login",
    "logged": "Logged in as",
    "logout": "Logout",
    "login": "Login",
    "signup": "Register",
    "continueWith": "Or continue with",
    "notMember": "Not a member?",
    "alreadyMember": "Already a member?",
    "email": "Email",
    "password": "Password",
    "confirmPassword": "Confirm Password",
    "forgotPassword": "Forgot Password?",
    "resetPassword": "Reset Password",
    "settings": "Settings",
    "profile": "Profile",
    "darkMode": "Dark Mode",
    "language": "Language",
    "english": "English",
    "spanish": "Spanish",
    "deleteProfile": "Delete Profile",
    "delete": "Delete",
    "deleteMsg": "Delete Message",
    "edit": "Edit",
    "editMsg": "Edit Message",
    "typing": "Typing...", 
    "newMsg": "Enter new message",
    "update": "Update",
    "save": "Save",
    "cancel": "Cancel",
    "send": "Send",
    "profileDetails": "Profile Details",
    "contacts": "Contacts",
    "search": "Search for a contact",
    "message": "Type a message",
    "name": "Name",
    "bio": "Biography"
  },
  'es': {
    "welcome": "Bienvenido",
    "signin": "Iniciar Sesión",
    "signing": "Iniciando Sesión...",
    "backToLogin": "Volver al Inicio de Sesión",
    "logged": "Sesión iniciada como",
    "logout": "Cerrar Sesión",
    "login": "Inicia Sesión",
    "signup": "Registrar",
    "continueWith": "O continuar con",
    "notMember": "No eres miembro?",
    "alreadyMember": "Ya eres miembro?",
    "email": "Correo Electrónico",
    "password": "Contraseña",
    "confirmPassword": "Confirmar Contraseña",
    "forgotPassword": "Olvidé mi Contraseña?",
    "resetPassword": "Restablecer Contraseña",
    "settings": "Configuración",
    "profile": "Perfil",
    "darkMode": "Modo Oscuro",
    "language": "Idioma",
    "english": "Inglés",
    "spanish": "Español",
    "deleteProfile": "Eliminar Perfil",
    "delete": "Eliminar",
    "deleteMsg": "Borrar Mensaje",
    "edit": "Editar",
    "editMsg": "Editar Mensaje",
    "newMsg": "Ingrese nuevo mensaje",
    "update": "Actualizar",
    "save": "Guardar",
    "cancel": "Cancelar",
    "send": "Enviar",
    "profileDetails": "Detalles del Perfil",
    "contacts": "Contactos",
    "search": "Buscar un contacto",
    "message": "Escribir un mensaje",
    "typing": "Escribiendo...",
    "name": "Nombre",
    "bio": "Biografía"
  },
};

  String translate(String key) {
    return translations[_currentLanguage]?[key] ?? key;
  }
}