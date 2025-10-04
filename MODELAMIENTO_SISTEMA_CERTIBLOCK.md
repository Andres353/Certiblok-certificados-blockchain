# MODELAMIENTO DEL SISTEMA CERTIBLOCK
## Sistema de Gestión de Certificados Académicos Multi-Tenant

---

## 1. INFORMACIÓN GENERAL DEL PROYECTO

### 1.1 Descripción del Sistema
**Certiblock** es una plataforma de gestión de certificados académicos que utiliza tecnología blockchain para garantizar la autenticidad, seguridad y trazabilidad de los certificados emitidos por instituciones educativas. El sistema implementa una arquitectura multi-tenant que permite a múltiples instituciones gestionar sus certificados de manera independiente.

### 1.2 Tecnologías Utilizadas
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Base de Datos**: Cloud Firestore (NoSQL)
- **Autenticación**: Firebase Auth
- **Almacenamiento**: Firebase Storage
- **Plataformas**: Web, Android, iOS

### 1.3 Arquitectura del Sistema
- **Patrón**: Multi-tenant SaaS (Software as a Service)
- **Arquitectura**: Cliente-Servidor con servicios en la nube
- **Separación de datos**: Por institución (tenant isolation)

---

## 2. ESTRUCTURA ESTÁTICA DEL SISTEMA

### 2.1 Entidades Principales

#### 2.1.1 Usuario (User)
```dart
class User {
  String id;
  String email;
  String password;
  String fullName;
  String role; // super_admin, admin_institution, emisor, student, public_user
  String? institutionId;
  String? studentId;
  String? programId;
  String? facultyId;
  bool isVerified;
  bool mustChangePassword;
  DateTime createdAt;
}
```

#### 2.1.2 Institución (Institution)
```dart
class Institution {
  String id;
  String name;
  String shortName;
  String description;
  String logoUrl;
  String institutionCode; // Código único de 10 dígitos
  InstitutionColors colors;
  InstitutionSettings settings;
  InstitutionStatus status; // active, inactive, suspended, pending
  String createdBy; // ID del super admin
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### 2.1.3 Certificado (Certificate)
```dart
class Certificate {
  String id;
  String uniqueHash; // SHA-256 único
  String institutionId;
  String institutionName;
  String institutionCode;
  String studentId;
  String studentName;
  String studentEmail;
  String studentIdInInstitution;
  String programId;
  String programName;
  String facultyId;
  String facultyName;
  String certificateType;
  String title;
  String description;
  Map<String, dynamic> data;
  String? blockchainHash;
  String qrCode;
  DateTime issuedAt;
  String issuedBy;
  String issuedByName;
  String issuedByRole;
  String status; // active, revoked, expired
  DateTime? expiresAt;
  DateTime? revokedAt;
  String? revokedBy;
  String? revokedReason;
  List<Map<String, dynamic>> validationHistory;
}
```

#### 2.1.4 Plantilla de Certificado (CertificateTemplate)
```dart
class CertificateTemplate {
  String id;
  String name;
  String description;
  String institutionId;
  bool isDefault;
  TemplateDesign design;
  TemplateLayout layout;
  List<TemplateField> fields;
  String createdBy;
  DateTime createdAt;
  DateTime updatedAt;
}
```

#### 2.1.5 Asignación de Emisor (EmisorAssignment)
```dart
class EmisorAssignment {
  String id;
  String type; // general, facultad, carrera, programa
  String areaId;
  String areaName;
  String? parentAreaId;
  String? parentAreaName;
}
```

### 2.2 Roles del Sistema

#### 2.2.1 Jerarquía de Roles
1. **Super Admin** (Nivel 5)
   - Control total del sistema multi-tenant
   - Gestiona todas las instituciones
   - Puede crear y eliminar instituciones

2. **Admin de Institución** (Nivel 4)
   - Gestiona una institución específica
   - Administra usuarios de su institución
   - Aprueba emisores

3. **Emisor** (Nivel 3)
   - Emite certificados para estudiantes
   - Gestiona plantillas de certificados
   - Valida información de estudiantes

4. **Estudiante** (Nivel 2)
   - Ve sus propios certificados
   - Organiza y comparte certificados
   - Descarga certificados

5. **Usuario Público** (Nivel 1)
   - Verifica certificados
   - Escanea códigos QR
   - Ve certificados públicos

### 2.3 Relaciones Entre Entidades

#### 2.3.1 Diagrama de Entidad-Relación (ER)

```
[Super Admin] 1----* [Institución]
                    |
                    | 1----* [Admin Institución]
                    |
                    | 1----* [Emisor]
                    |
                    | 1----* [Estudiante]
                    |
                    | 1----* [Certificado]
                    |
                    | 1----* [Plantilla Certificado]

[Emisor] 1----* [Asignación Emisor]
[Estudiante] 1----* [Certificado]
[Institución] 1----* [Plantilla Certificado]
```

---

## 3. ESTRUCTURA DINÁMICA DEL SISTEMA

### 3.1 Casos de Uso Principales

#### 3.1.1 Gestión de Usuarios
- **CU001**: Registrar Estudiante
- **CU002**: Iniciar Sesión
- **CU003**: Cambiar Contraseña
- **CU004**: Recuperar Contraseña
- **CU005**: Gestionar Perfil

#### 3.1.2 Gestión de Instituciones
- **CU006**: Crear Institución
- **CU007**: Gestionar Institución
- **CU008**: Configurar Institución
- **CU009**: Suspender Institución

#### 3.1.3 Gestión de Certificados
- **CU010**: Emitir Certificado
- **CU011**: Validar Certificado
- **CU012**: Revocar Certificado
- **CU013**: Ver Certificados
- **CU014**: Descargar Certificado

#### 3.1.4 Gestión de Plantillas
- **CU015**: Crear Plantilla
- **CU016**: Editar Plantilla
- **CU017**: Aplicar Plantilla
- **CU018**: Gestionar Plantillas

### 3.2 Flujos de Trabajo Principales

#### 3.2.1 Flujo de Emisión de Certificado
```
1. Emisor inicia sesión
2. Selecciona estudiante
3. Elige tipo de certificado
4. Completa datos del certificado
5. Selecciona plantilla
6. Genera certificado
7. Guarda en base de datos
8. Genera código QR
9. Notifica al estudiante
```

#### 3.2.2 Flujo de Validación de Certificado
```
1. Usuario escanea QR o ingresa ID
2. Sistema busca certificado
3. Verifica estado (activo/revocado/expirado)
4. Verifica expiración
5. Registra validación en historial
6. Muestra resultado de validación
```

#### 3.2.3 Flujo de Registro de Estudiante
```
1. Estudiante accede a registro
2. Ingresa datos personales
3. Selecciona institución
4. Ingresa código de institución
5. Sistema valida código
6. Crea cuenta de usuario
7. Envía confirmación
8. Estudiante inicia sesión
```

### 3.3 Diagramas de Secuencia

#### 3.3.1 Secuencia de Emisión de Certificado
```
Actor: Emisor
Sistema: Certiblock
BaseDatos: Firestore

Emisor -> Sistema: Iniciar emisión
Sistema -> Emisor: Mostrar formulario
Emisor -> Sistema: Completar datos
Sistema -> BaseDatos: Validar estudiante
BaseDatos -> Sistema: Datos válidos
Sistema -> BaseDatos: Crear certificado
BaseDatos -> Sistema: Certificado creado
Sistema -> Sistema: Generar QR
Sistema -> Emisor: Mostrar certificado
```

#### 3.3.2 Secuencia de Validación de Certificado
```
Actor: Usuario
Sistema: Certiblock
BaseDatos: Firestore

Usuario -> Sistema: Escanear QR/Ingresar ID
Sistema -> BaseDatos: Buscar certificado
BaseDatos -> Sistema: Datos del certificado
Sistema -> Sistema: Verificar estado
Sistema -> Sistema: Verificar expiración
Sistema -> BaseDatos: Registrar validación
Sistema -> Usuario: Mostrar resultado
```

---

## 4. ARQUITECTURA TÉCNICA

### 4.1 Capas del Sistema

#### 4.1.1 Capa de Presentación (UI)
- **Widgets Flutter**: Pantallas responsivas
- **Navegación**: Gestión de rutas
- **Estado**: Gestión de estado local

#### 4.1.2 Capa de Lógica de Negocio (Services)
- **AuthService**: Autenticación y autorización
- **CertificateService**: Gestión de certificados
- **InstitutionService**: Gestión de instituciones
- **UserContextService**: Contexto de usuario multi-tenant

#### 4.1.3 Capa de Datos (Models)
- **Modelos de datos**: Representación de entidades
- **Serialización**: Conversión JSON/Firestore
- **Validación**: Reglas de negocio

#### 4.1.4 Capa de Persistencia (Firebase)
- **Firestore**: Base de datos NoSQL
- **Authentication**: Gestión de usuarios
- **Storage**: Almacenamiento de archivos

### 4.2 Patrones de Diseño Implementados

#### 4.2.1 Multi-Tenant Architecture
- **Aislamiento de datos**: Por institución
- **Configuración personalizada**: Por tenant
- **Escalabilidad**: Horizontal

#### 4.2.2 Service Layer Pattern
- **Separación de responsabilidades**
- **Reutilización de código**
- **Testabilidad**

#### 4.2.3 Repository Pattern
- **Abstracción de datos**
- **Independencia de la fuente de datos**

---

## 5. SEGURIDAD Y VALIDACIÓN

### 5.1 Medidas de Seguridad
- **Autenticación**: Firebase Auth
- **Autorización**: Roles y permisos
- **Aislamiento**: Multi-tenant
- **Validación**: Códigos QR únicos
- **Hash**: SHA-256 para certificados

### 5.2 Validaciones Implementadas
- **Códigos de institución**: 10 dígitos únicos
- **Códigos de carrera**: Formato INSTITUCION-CARRERA-XXX
- **Certificados**: Hash único SHA-256
- **QR Codes**: URLs de validación únicas

---

## 6. ESCALABILIDAD Y RENDIMIENTO

### 6.1 Escalabilidad Horizontal
- **Multi-tenant**: Soporte para múltiples instituciones
- **Firebase**: Escalado automático
- **Caching**: SharedPreferences para contexto local

### 6.2 Optimizaciones
- **Consultas eficientes**: Filtros por institución
- **Paginación**: Límites en consultas
- **Caching local**: Datos de usuario

---

## 7. CONCLUSIONES

El sistema Certiblock implementa una arquitectura robusta y escalable para la gestión de certificados académicos, utilizando tecnologías modernas como Flutter y Firebase. La implementación multi-tenant permite a múltiples instituciones gestionar sus certificados de manera independiente, mientras que las características de blockchain y validación QR garantizan la autenticidad y trazabilidad de los certificados emitidos.

### 7.1 Fortalezas del Sistema
- **Arquitectura multi-tenant** bien implementada
- **Seguridad robusta** con validaciones múltiples
- **Interfaz responsiva** para múltiples plataformas
- **Escalabilidad** horizontal
- **Trazabilidad completa** de certificados

### 7.2 Áreas de Mejora Futuras
- **Integración blockchain** completa
- **Notificaciones push** en tiempo real
- **Analytics avanzados** por institución
- **API REST** para integraciones externas
- **Backup automático** de certificados

---

## 8. DIAGRAMAS ADICIONALES

### 8.1 Diagrama de Clases (Estructura Estática)

```
┌─────────────────────────────────────────────────────────────────┐
│                        SISTEMA CERTIBLOCK                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   SUPER ADMIN   │    │ ADMIN INSTITUCIÓN│    │   EMISOR     │ │
│  │                 │    │                 │    │              │ │
│  │ - manageAll()   │    │ - manageInst()  │    │ - emitCert() │ │
│  │ - createInst()  │    │ - approveEmisor()│   │ - validate() │ │
│  │ - deleteInst()  │    │ - manageUsers() │    │ - viewCerts()│ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│           │                       │                       │     │
│           │                       │                       │     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   INSTITUCIÓN   │    │   ESTUDIANTE    │    │   PÚBLICO    │ │
│  │                 │    │                 │    │              │ │
│  │ - id            │    │ - viewOwnCerts()│    │ - verifyCert()│ │
│  │ - name          │    │ - organizeCerts()│   │ - scanQR()   │ │
│  │ - institutionCode│   │ - downloadCerts()│   │ - viewPublic()│ │
│  │ - colors        │    │ - shareCerts()  │    │              │ │
│  │ - settings      │    │ - viewHistory() │    │              │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│           │                       │                       │     │
│           │                       │                       │     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   CERTIFICADO   │    │ PLANTILLA CERT. │    │ ASIGNACIÓN   │ │
│  │                 │    │                 │    │   EMISOR     │ │
│  │ - uniqueHash    │    │ - design        │    │              │ │
│  │ - institutionId │    │ - layout        │    │ - type       │ │
│  │ - studentId     │    │ - fields        │    │ - areaId     │ │
│  │ - qrCode        │    │ - institutionId │    │ - areaName   │ │
│  │ - status        │    │ - isDefault     │    │ - parentArea │ │
│  │ - validationHist│    │ - createdBy     │    │              │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Diagrama de Flujo de Datos (Estructura Dinámica)

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   USUARIO   │    │   SISTEMA   │    │  FIREBASE   │    │ BLOCKCHAIN  │
│             │    │  CERTIBLOCK │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       │ 1. Login          │                   │                   │
       ├──────────────────►│                   │                   │
       │                   │ 2. Auth Request   │                   │
       │                   ├──────────────────►│                   │
       │                   │ 3. Auth Response  │                   │
       │                   │◄──────────────────┤                   │
       │ 4. Dashboard      │                   │                   │
       │◄──────────────────┤                   │                   │
       │                   │                   │                   │
       │ 5. Emit Cert      │                   │                   │
       ├──────────────────►│                   │                   │
       │                   │ 6. Validate Data  │                   │
       │                   ├──────────────────►│                   │
       │                   │ 7. Data Valid    │                   │
       │                   │◄──────────────────┤                   │
       │                   │ 8. Create Cert    │                   │
       │                   ├──────────────────►│                   │
       │                   │ 9. Generate Hash  │                   │
       │                   ├──────────────────►│                   │
       │                   │ 10. Store Hash    │                   │
       │                   │◄──────────────────┤                   │
       │ 11. Cert Created  │                   │                   │
       │◄──────────────────┤                   │                   │
       │                   │                   │                   │
       │ 12. Verify Cert   │                   │                   │
       ├──────────────────►│                   │                   │
       │                   │ 13. Search Cert   │                   │
       │                   ├──────────────────►│                   │
       │                   │ 14. Cert Data     │                   │
       │                   │◄──────────────────┤                   │
       │                   │ 15. Validate      │                   │
       │                   ├──────────────────►│                   │
       │                   │ 16. Hash Valid    │                   │
       │                   │◄──────────────────┤                   │
       │ 17. Validation    │                   │                   │
       │◄──────────────────┤                   │                   │
```

### 8.3 Diagrama de Arquitectura Multi-Tenant

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA MULTI-TENANT                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   INSTITUCIÓN A │  │   INSTITUCIÓN B │  │   INSTITUCIÓN C │ │
│  │                 │  │                 │  │                 │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │ Super Admin │ │  │ │ Super Admin │ │  │ │ Super Admin │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │Admin Inst. A│ │  │ │Admin Inst. B│ │  │ │Admin Inst. C│ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │  Emisores   │ │  │ │  Emisores   │ │  │ │  Emisores   │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │ Estudiantes │ │  │ │ Estudiantes │ │  │ │ Estudiantes │ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  │ ┌─────────────┐ │  │ ┌─────────────┐ │  │ ┌─────────────┐ │ │
│  │ │ Certificados│ │  │ │ Certificados│ │  │ │ Certificados│ │ │
│  │ └─────────────┘ │  │ └─────────────┘ │  │ └─────────────┘ │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│           │                   │                   │             │
│           └───────────────────┼───────────────────┘             │
│                               │                                 │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                FIREBASE FIRESTORE                           │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │ │
│  │  │Institution A│  │Institution B│  │Institution C│         │ │
│  │  │Collection   │  │Collection   │  │Collection   │         │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │ │
│  │  │Certificates │  │Certificates │  │Certificates │         │ │
│  │  │(Filtered by │  │(Filtered by │  │(Filtered by │         │ │
│  │  │ Institution)│  │ Institution)│  │ Institution)│         │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘         │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 8.4 Diagrama de Estados de Certificado

```
┌─────────────┐
│   CREADO    │
└──────┬──────┘
       │
       │ Emitir
       ▼
┌─────────────┐
│   ACTIVO    │◄─────────────────┐
└──────┬──────┘                  │
       │                         │
       │ Revocar                 │ Validar
       ▼                         │
┌─────────────┐                  │
│  REVOCADO   │                  │
└──────┬──────┘                  │
       │                         │
       │                         │
       │ Expirar                 │
       ▼                         │
┌─────────────┐                  │
│  EXPIRADO   │                  │
└─────────────┘                  │
                                 │
                                 │
                                 ▼
                        ┌─────────────┐
                        │ VALIDACIÓN  │
                        │  EXITOSA    │
                        └─────────────┘
```

---

## 9. ESPECIFICACIONES TÉCNICAS

### 9.1 Requisitos del Sistema
- **Flutter SDK**: >=3.1.0 <4.0.0
- **Firebase**: Core, Auth, Firestore, Storage
- **Plataformas**: Android, iOS, Web
- **Resolución**: Responsive (móvil y escritorio)

### 9.2 Dependencias Principales
```yaml
dependencies:
  flutter: sdk
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.0
  cloud_firestore: ^4.5.0
  firebase_storage: ^11.0.16
  qr_flutter: ^4.1.0
  pdf: ^3.10.7
  crypto: ^3.0.3
  shared_preferences: ^2.2.2
```

### 9.3 Estructura de Base de Datos Firestore

#### 9.3.1 Colección: institutions
```json
{
  "id": "institution_id",
  "name": "Universidad del Valle",
  "shortName": "UV",
  "institutionCode": "1234567890",
  "colors": {...},
  "settings": {...},
  "status": "active",
  "createdBy": "super_admin_id",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 9.3.2 Colección: users
```json
{
  "id": "user_id",
  "email": "user@email.com",
  "role": "student",
  "institutionId": "institution_id",
  "fullName": "Nombre Completo",
  "studentId": "12345",
  "isVerified": true,
  "mustChangePassword": false,
  "createdAt": "timestamp"
}
```

#### 9.3.3 Colección: certificates
```json
{
  "id": "certificate_id",
  "uniqueHash": "sha256_hash",
  "institutionId": "institution_id",
  "studentId": "student_id",
  "certificateType": "diploma",
  "title": "Título del Certificado",
  "qrCode": "https://certiblock.com/validate/id",
  "status": "active",
  "issuedAt": "timestamp",
  "validationHistory": [...]
}
```

---

*Documento generado automáticamente basado en el análisis del código fuente del proyecto Certiblock*
