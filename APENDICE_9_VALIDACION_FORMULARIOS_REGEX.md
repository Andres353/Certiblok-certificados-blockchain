# APÉNDICE Nº 9
## PRUEBAS DE VALIDACIÓN DE FORMULARIOS CON EXPRESIONES REGULARES (REGEX) (CAJA BLANCA)

Se llevaron a cabo pruebas de validación de formularios que usan expresiones regulares para garantizar la exactitud de los datos ingresados en los formularios y asegurar que cumplan con los patrones específicos establecidos. Estas expresiones regulares se encuentran en el Sistema Web, Aplicación Móvil y API de CertiBlock:

---

## 1. Correos Electrónicos

La función `isEmail` valida la cadena de entrada `email` como una posible dirección de correo electrónico asegurándose de que comience con uno o más caracteres del conjunto de letras, dígitos y caracteres especiales permitidos (`[\w-\.]`), seguidos por un símbolo "@", luego una sección de dominio que consta de uno o más grupos de caracteres del conjunto de letras, dígitos y guiones (`[\w-]`) separados por puntos y que terminan con un dominio de 2 a 4 caracteres alfanuméricos (`[\w-]{2,4}`), que devuelve `true` o verdadero si la cadena de entrada coincide con este patrón y `false` o falso si no es así:

```dart
bool isEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isEmail("estudiante@certiblock.com")` | `True` |
| `isEmail("admin@universidad.edu.co")` | `True` |
| `isEmail("hola mundo")` | `False` |
| `isEmail("correo@sin-dominio")` | `False` |
| `isEmail("test@certiblock")` | `False` |
| `isEmail("@certiblock.com")` | `False` |

---

## 2. Nombres y Apellidos de Persona

La función `isName` valida la cadena de entrada `name` como un posible nombre o apellido de una persona asegurándose de que consta de al menos dos palabras (nombre y apellido), cada una con al menos 2 caracteres, que no contenga números ni caracteres especiales, y que tenga una longitud total mínima de 5 caracteres. La validación también verifica que no contenga caracteres especiales como `[!@#$%^&*(),.?":{}|<>]`:

```dart
bool isName(String name) {
  final cleanValue = name.trim().replaceAll(RegExp(r'\s+'), ' ');
  final words = cleanValue.split(' ');
  
  // Validar que tenga al menos 2 palabras (nombre y apellido)
  if (words.length < 2) {
    return false;
  }
  
  // Validar que cada palabra tenga al menos 2 caracteres
  for (String word in words) {
    if (word.length < 2) {
      return false;
    }
  }
  
  // Validar que no contenga números
  if (RegExp(r'[0-9]').hasMatch(cleanValue)) {
    return false;
  }
  
  // Validar que no contenga caracteres especiales
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(cleanValue)) {
    return false;
  }
  
  // Validar longitud total mínima
  if (cleanValue.length < 5) {
    return false;
  }
  
  return true;
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isName("Juan Pérez")` | `True` |
| `isName("María González")` | `True` |
| `isName("Rodrigo")` | `False` (solo una palabra) |
| `isName("Juan 123")` | `False` (contiene números) |
| `isName("Pablo@Daniel")` | `False` (contiene caracteres especiales) |
| `isName("A B")` | `False` (palabras muy cortas) |
| `isName("Axel")` | `False` (solo una palabra) |

---

## 3. Número Telefónico

La función `isPhoneNumber` valida si la cadena de entrada `phone` contiene solo dígitos numéricos (0-9) y devuelve `true` o verdadero si consta exclusivamente de dígitos, lo que indica un número de teléfono válido, y `false` o falso si contiene caracteres que no sean dígitos:

```dart
bool isPhoneNumber(String phone) {
  final phoneRegex = RegExp(r'^[0-9]+$');
  return phoneRegex.hasMatch(phone);
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isPhoneNumber("67253445")` | `True` |
| `isPhoneNumber("68127845")` | `True` |
| `isPhoneNumber("7021544")` | `True` |
| `isPhoneNumber("+57 2 3212100")` | `False` (contiene espacios y símbolos) |
| `isPhoneNumber("Hola Mundo")` | `False` |
| `isPhoneNumber("Phone Number")` | `False` |

---

## 4. Documento de Identidad

La función `isDocument` valida la cadena de entrada `document` para garantizar que se adhiera al patrón de un documento de identidad: debe constar exclusivamente de dígitos numéricos (0-9) y tener una longitud mínima de 6 caracteres:

```dart
bool isDocument(String document) {
  final documentRegex = RegExp(r'^[0-9]+$');
  if (!documentRegex.hasMatch(document)) {
    return false;
  }
  if (document.length < 6) {
    return false;
  }
  return true;
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isDocument("12345678")` | `True` |
| `isDocument("987654321")` | `True` |
| `isDocument("12345")` | `False` (menos de 6 caracteres) |
| `isDocument("ABC123456")` | `False` (contiene letras) |
| `isDocument("12.345.678")` | `False` (contiene puntos) |

---

## 5. Contraseña Segura

La función `isSecurePassword` valida la cadena de entrada `password` para garantizar que cumpla con los requisitos de seguridad: debe tener al menos 8 caracteres de longitud, contener al menos una letra minúscula, una letra mayúscula y un dígito numérico:

```dart
bool isSecurePassword(String password) {
  // Validar longitud mínima
  if (password.length < 8) {
    return false;
  }
  
  // Validar que contenga al menos una minúscula, una mayúscula y un dígito
  final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)');
  return passwordRegex.hasMatch(password);
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isSecurePassword("Password123")` | `True` |
| `isSecurePassword("MiClave2024")` | `True` |
| `isSecurePassword("password")` | `False` (falta mayúscula y número) |
| `isSecurePassword("PASSWORD123")` | `False` (falta minúscula) |
| `isSecurePassword("Pass123")` | `False` (menos de 8 caracteres) |
| `isSecurePassword("password123")` | `False` (falta mayúscula) |

---

## 6. Código de Color Hexadecimal

La función `isHexColor` valida la cadena de entrada `color` para garantizar que se adhiera al formato de color hexadecimal: debe comenzar con el símbolo "#" seguido de exactamente 6 caracteres hexadecimales (0-9, A-F, a-f):

```dart
bool isHexColor(String color) {
  final hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');
  return hexColorRegex.hasMatch(color);
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isHexColor("#6C4DDC")` | `True` |
| `isHexColor("#FF5733")` | `True` |
| `isHexColor("#000000")` | `True` |
| `isHexColor("#FFFFFF")` | `True` |
| `isHexColor("6C4DDC")` | `False` (falta el símbolo #) |
| `isHexColor("#6C4D")` | `False` (menos de 6 caracteres) |
| `isHexColor("#6C4DDCFF")` | `False` (más de 6 caracteres) |
| `isHexColor("#GGGGGG")` | `False` (contiene caracteres no hexadecimales) |

---

## 7. URL Válida

La función `isValidUrl` valida la cadena de entrada `url` para garantizar que sea una URL válida con protocolo HTTP o HTTPS:

```dart
bool isValidUrl(String url) {
  if (url.isEmpty) {
    return false;
  }
  
  // Validar URLs HTTP/HTTPS
  if (url.startsWith('http://') || url.startsWith('https://')) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasAbsolutePath;
  }
  
  return false;
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isValidUrl("https://www.certiblock.com")` | `True` |
| `isValidUrl("http://universidad.edu.co")` | `True` |
| `isValidUrl("www.certiblock.com")` | `False` (falta protocolo) |
| `isValidUrl("certiblock.com")` | `False` (falta protocolo) |
| `isValidUrl("ftp://archivo.com")` | `False` (protocolo no permitido) |
| `isValidUrl("not a url")` | `False` |

---

## 8. Dirección

La función `isValidAddress` valida la cadena de entrada `address` para garantizar que tenga una longitud mínima de 10 caracteres cuando no está vacía:

```dart
bool isValidAddress(String address) {
  // Si está vacía, es válida (opcional)
  if (address.isEmpty) {
    return true;
  }
  
  // Si tiene contenido, debe tener al menos 10 caracteres
  return address.length >= 10;
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isValidAddress("Calle 13 #100-00, Cali")` | `True` |
| `isValidAddress("Avenida Principal 456")` | `True` |
| `isValidAddress("")` | `True` (opcional) |
| `isValidAddress("Calle 1")` | `False` (menos de 10 caracteres) |
| `isValidAddress("Carrera 5")` | `False` (menos de 10 caracteres) |

---

## 9. Nombre de Institución

La función `isValidInstitutionName` valida la cadena de entrada `name` para garantizar que el nombre de la institución tenga al menos 3 caracteres:

```dart
bool isValidInstitutionName(String name) {
  if (name.trim().isEmpty) {
    return false;
  }
  return name.trim().length >= 3;
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isValidInstitutionName("Universidad del Valle")` | `True` |
| `isValidInstitutionName("UdeA")` | `True` |
| `isValidInstitutionName("UV")` | `False` (menos de 3 caracteres) |
| `isValidInstitutionName("")` | `False` (vacío) |
| `isValidInstitutionName("  ")` | `False` (solo espacios) |

---

## 10. Hash de Certificado Blockchain

La función `isValidBlockchainHash` valida la cadena de entrada `hash` para garantizar que sea un hash hexadecimal válido de 64 caracteres (256 bits), utilizado para certificados en la blockchain:

```dart
bool isValidBlockchainHash(String hash) {
  final hashRegex = RegExp(r'^[0-9a-fA-F]{64}$');
  return hash.length == 64 && hashRegex.hasMatch(hash);
}
```

**Ejemplos:**

| Entrada | Respuesta |
|---------|-----------|
| `isValidBlockchainHash("a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456")` | `True` |
| `isValidBlockchainHash("1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")` | `True` |
| `isValidBlockchainHash("a1b2c3")` | `False` (menos de 64 caracteres) |
| `isValidBlockchainHash("a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef12345g")` | `False` (contiene 'g' no hexadecimal) |
| `isValidBlockchainHash("")` | `False` (vacío) |

---

## Resumen de Validaciones Implementadas

| Campo | Expresión Regular | Ubicación en el Sistema |
|-------|-------------------|------------------------|
| Correo Electrónico | `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$` | Registro de estudiantes, registro de instituciones, login |
| Nombre Completo | Validación múltiple (sin números, sin caracteres especiales, mínimo 2 palabras) | Registro de estudiantes, registro de instituciones |
| Teléfono | `^[0-9]+$` | Registro de estudiantes, registro de instituciones |
| Documento de Identidad | `^[0-9]+$` (mínimo 6 caracteres) | Registro de estudiantes |
| Contraseña | `^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)` (mínimo 8 caracteres) | Cambio de contraseña, registro |
| Color Hexadecimal | `^#[0-9A-Fa-f]{6}$` | Editor de plantillas de certificados |
| URL | Validación de URI HTTP/HTTPS | Registro de instituciones, URLs de logos |
| Dirección | Mínimo 10 caracteres (opcional) | Registro de estudiantes, registro de instituciones |
| Hash Blockchain | `^[0-9a-fA-F]{64}$` | Servicio de blockchain, validación de certificados |

---

**Fuente:** Elaboración Propia (2025)


