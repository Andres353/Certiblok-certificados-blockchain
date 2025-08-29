# 🎓 Certiblock - Plataforma de Certificados Académicos con Blockchain

## 📋 Descripción

Certiblock es una plataforma innovadora que permite registrar y validar certificados académicos a través de la tecnología Blockchain, garantizando seguridad, trazabilidad y autenticidad en el proceso de emisión de títulos y certificados educativos.

## ✨ Características Principales

- 🔐 **Autenticación Segura**: Sistema de login con Firebase Auth
- 👥 **Múltiples Roles**: Administradores, usuarios e instituciones
- 📧 **Verificación por Email**: Códigos de verificación para nuevos registros
- 🌐 **Multiplataforma**: Aplicación Flutter para Web, iOS y Android
- 🔒 **Base de Datos Segura**: Firestore con reglas de seguridad
- 📱 **Diseño Responsivo**: Adaptable a diferentes tamaños de pantalla

## 🚀 Tecnologías Utilizadas

- **Frontend**: Flutter 3.1+
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Autenticación**: Firebase Authentication
- **Base de Datos**: Cloud Firestore
- **Almacenamiento**: Firebase Storage
- **Email**: EmailJS para verificación
- **Plataformas**: Web, iOS, Android, Windows, macOS, Linux

## 📱 Capturas de Pantalla

*[Aquí puedes agregar capturas de pantalla de tu aplicación]*

## 🛠️ Instalación y Configuración

### Prerrequisitos

- Flutter SDK 3.1.0 o superior
- Dart SDK
- Cuenta de Firebase
- Cuenta de EmailJS (para verificación por email)

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone [URL_DEL_REPOSITORIO]
   cd frontend_app
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Firebase**
   - Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
   - Habilitar Authentication, Firestore y Storage
   - Descargar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS)
   - Colocar archivos en las carpetas correspondientes

4. **Configurar EmailJS**
   - Crear cuenta en [EmailJS](https://www.emailjs.com/)
   - Configurar servicio de email
   - Actualizar credenciales en `lib/screens/register_student.dart`

5. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── firebase_options.dart     # Configuración de Firebase
├── screens/                  # Pantallas de la aplicación
│   ├── main_menu.dart       # Menú principal
│   ├── login_screen.dart    # Pantalla de login
│   ├── register_student.dart # Registro de estudiantes
│   └── ...
├── services/                 # Servicios de la aplicación
│   └── auth_service.dart    # Servicio de autenticación
└── header/                   # Componentes de header personalizados
    ├── HeaderHome.dart      # Header principal
    └── ...
```

## 🔧 Configuración de Firebase

### Reglas de Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /students/{studentId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🚀 Despliegue

### Web
```bash
flutter build web
flutter deploy
```

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

**Tu Nombre** - [Tu Email]

## 🙏 Agradecimientos

- Flutter Team por el framework
- Firebase por la infraestructura backend
- EmailJS por el servicio de email
- Comunidad Flutter por el soporte

## 📞 Contacto

- **Email**: [tu-email@ejemplo.com]
- **LinkedIn**: [tu-linkedin]
- **GitHub**: [tu-github]

---

⭐ **Si este proyecto te gusta, dale una estrella en GitHub!**
