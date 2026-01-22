# Controles de Autenticación - Guía de Uso

Este documento describe los controles de seguridad de autenticación que se han implementado en el sistema.

## Características Implementadas

### 1. **Timeout de Inactividad**
- La sesión se cierra automáticamente después de 30 minutos de inactividad
- Configurable en `AuthSecurityService._inactivityTimeoutMinutes`

### 2. **Bloqueo por Intentos Fallidos**
- Después de 5 intentos fallidos de login, la cuenta se bloquea por 15 minutos
- Configurable en `AuthSecurityService._maxFailedAttempts` y `_accountLockoutMinutes`

### 3. **Verificación Periódica de Sesión**
- La sesión se valida automáticamente cada 5 minutos
- Verifica que el token no haya expirado y que el usuario siga autenticado

### 4. **Monitoreo de Actividad**
- Registra automáticamente la actividad del usuario
- Detecta cuando la aplicación vuelve al primer plano

## Uso

### Integración Automática

Los controles están integrados automáticamente en `AuthAdapter`. No necesitas hacer nada especial:

```dart
// El login automáticamente:
// - Verifica si la cuenta está bloqueada
// - Registra actividad
// - Inicia monitoreo de sesión
final userContext = await AuthAdapter.loginWithContext(email, password);

// El logout automáticamente:
// - Detiene el monitoreo
// - Limpia datos de seguridad
await AuthAdapter.logout();
```

### Widget de Monitoreo de Sesión

Para monitorear automáticamente la sesión en tus pantallas, envuelve tu contenido con `AuthSessionMonitor`:

```dart
import 'package:frontend_app/widgets/auth_session_monitor.dart';

class MyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthSessionMonitor(
      onSessionExpired: () {
        // Opcional: callback cuando la sesión expira
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      },
      child: Scaffold(
        // Tu contenido aquí
      ),
    );
  }
}
```

### Uso Manual del Servicio

Si necesitas control manual:

```dart
import 'package:frontend_app/services/auth_security_service.dart';

// Registrar actividad del usuario
await AuthSecurityService.recordUserActivity();

// Verificar si la sesión está activa
final isActive = await AuthSecurityService.isSessionActive();

// Validar sesión
final isValid = await AuthSecurityService.validateSession();

// Verificar si una cuenta está bloqueada
final isLocked = await AuthSecurityService.isAccountLocked(email);

// Obtener intentos restantes
final remainingAttempts = await AuthSecurityService.getRemainingAttempts(email);

// Obtener estado de seguridad
final status = await AuthSecurityService.getSecurityStatus();
```

## Ejemplo de Integración en Dashboard

```dart
import 'package:frontend_app/widgets/auth_session_monitor.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return AuthSessionMonitor(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dashboard'),
        ),
        body: YourContent(),
      ),
    );
  }
}
```

## Configuración

Puedes ajustar los valores en `lib/services/auth_security_service.dart`:

```dart
// Tiempo de inactividad antes de cerrar sesión (minutos)
static const int _inactivityTimeoutMinutes = 30;

// Máximo de intentos fallidos antes de bloquear
static const int _maxFailedAttempts = 5;

// Tiempo de bloqueo de cuenta (minutos)
static const int _accountLockoutMinutes = 15;

// Intervalo de validación de sesión (segundos)
static const int _sessionValidationIntervalSeconds = 300;
```

## Manejo de Errores en Login

El sistema maneja automáticamente:

1. **Cuenta bloqueada**: Muestra mensaje con tiempo restante
2. **Intentos fallidos**: Muestra cuántos intentos quedan
3. **Sesión expirada**: Cierra sesión automáticamente y redirige al login

## Notas Importantes

- Los controles están activos automáticamente una vez que se usa `AuthAdapter.loginWithContext()`
- No es necesario llamar manualmente a `recordUserActivity()` en cada interacción
- El widget `AuthSessionMonitor` maneja automáticamente el monitoreo de actividad
- Los intentos fallidos se limpian automáticamente después del bloqueo o login exitoso
