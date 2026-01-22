# 🎓 Certiblock - Plataforma Multi-Tenant de Certificados Académicos con Blockchain

## 📋 Descripción

Certiblock es una plataforma innovadora multi-tenant que permite a instituciones académicas registrar y validar certificados académicos a través de la tecnología Blockchain, garantizando seguridad, trazabilidad y autenticidad en el proceso de emisión de títulos y certificados educativos.

## ✨ Características Principales

- 🏢 **Multi-Tenant**: Soporte para múltiples instituciones académicas
- 🔐 **Autenticación Segura**: Sistema de login con Firebase Auth
- 👥 **Múltiples Roles**: Super Admin, Admin de Institución, Emisores, Estudiantes
- 📧 **Verificación por Email**: Códigos de verificación para nuevos registros
- 🌐 **Multiplataforma**: Aplicación Flutter para Web, iOS y Android
- 🔒 **Base de Datos Segura**: Firestore con reglas de seguridad y aislamiento por institución
- 📱 **Diseño Responsivo**: Adaptable a diferentes tamaños de pantalla
- 🎨 **Personalización**: Cada institución puede personalizar su marca y configuración

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

### 📚 Documentación Completa

Para instalar el proyecto en una nueva laptop, consulta la documentación completa:

- **🚀 [GUIA_INSTALACION_COMPLETA.md](GUIA_INSTALACION_COMPLETA.md)** - Guía completa paso a paso con toda la información necesaria
- **⚡ [RESUMEN_RAPIDO_INSTALACION.md](RESUMEN_RAPIDO_INSTALACION.md)** - Resumen rápido para instalación rápida
- **🔐 [CONFIGURACIONES_CREDENCIALES.md](CONFIGURACIONES_CREDENCIALES.md)** - Todas las credenciales y configuraciones
- **✅ [CHECKLIST_PRE_FORMATEO.md](CHECKLIST_PRE_FORMATEO.md)** - Checklist antes de formatear/subir a Git

### Prerrequisitos

- Flutter SDK 3.1.0 o superior
- Dart SDK
- Node.js >= 16.0.0 (para Hardhat y contratos inteligentes)
- Git
- Cuenta de Firebase
- Cuenta de Supabase
- Cuenta de EmailJS (para verificación por email)

### Pasos de Instalación Rápida

1. **Clonar el repositorio**
   ```bash
   git clone [URL_DEL_REPOSITORIO]
   cd frontend_app
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   npm install
   ```

3. **Configurar servicios**
   - Ver `GUIA_INSTALACION_COMPLETA.md` para configuración detallada
   - Credenciales documentadas en `CONFIGURACIONES_CREDENCIALES.md`

4. **Ejecutar la aplicación**
   ```bash
   flutter run -d chrome
   ```

**⚠️ IMPORTANTE:** Para una instalación completa y sin problemas, sigue la guía completa en `GUIA_INSTALACION_COMPLETA.md`

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
