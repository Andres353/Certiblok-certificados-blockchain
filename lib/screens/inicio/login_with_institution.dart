// lib/screens/inicio/login_with_institution.dart
// Pantalla de login simplificada

import 'package:flutter/material.dart';
import '../../services/adapters/auth_adapter.dart';
import '../../services/auth_security_service.dart';
import '../../services/alert_service.dart';
import '../home_page.dart';
import 'change_password_page.dart';
import 'password_reset_screen.dart';

class LoginWithInstitution extends StatefulWidget {
  @override
  _LoginWithInstitutionState createState() => _LoginWithInstitutionState();
}

class _LoginWithInstitutionState extends State<LoginWithInstitution> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _securityMessage;

  @override
  void initState() {
    super.initState();
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    if (_emailController.text.isNotEmpty) {
      final email = _emailController.text.trim();
      final isLocked = await AuthSecurityService.isAccountLocked(email);
      
      if (isLocked) {
        final remainingTime = await AuthSecurityService.getRemainingLockoutTime(email);
        setState(() {
          _securityMessage = 'Cuenta bloqueada. Intenta de nuevo en ${remainingTime ?? 15} minutos.';
        });
      } else {
        final remainingAttempts = await AuthSecurityService.getRemainingAttempts(email);
        if (remainingAttempts < 5) {
          setState(() {
            _securityMessage = 'Te quedan $remainingAttempts intentos antes del bloqueo.';
          });
        } else {
          setState(() {
            _securityMessage = null;
          });
        }
      }
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    final email = _emailController.text.trim();

    // Verificar si la cuenta está bloqueada antes de intentar login
    final isLocked = await AuthSecurityService.isAccountLocked(email);
    if (isLocked) {
      final remainingTime = await AuthSecurityService.getRemainingLockoutTime(email);
      _showError(
        'Cuenta bloqueada por múltiples intentos fallidos.\n'
        'Intenta de nuevo en ${remainingTime ?? 15} minutos.',
      );
      _checkAccountStatus();
      return;
    }

    setState(() {
      _isLoading = true;
      _securityMessage = null;
    });

    try {
      final userContext = await AuthAdapter.loginWithContext(
        email,
        _passwordController.text.trim(),
      );

      if (userContext != null) {
        // Limpiar mensaje de seguridad al login exitoso
        setState(() {
          _securityMessage = null;
        });

        // Verificar si necesita cambiar contraseña
        if (userContext.mustChangePassword == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordPage(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(role: userContext.userRole)),
          );
        }
      } else {
        // Login fallido, verificar intentos restantes
        final remainingAttempts = await AuthSecurityService.getRemainingAttempts(email);
        final isStillLocked = await AuthSecurityService.isAccountLocked(email);
        
        if (isStillLocked) {
          final remainingTime = await AuthSecurityService.getRemainingLockoutTime(email);
          _showError(
            'Cuenta bloqueada por múltiples intentos fallidos.\n'
            'Intenta de nuevo en ${remainingTime ?? 15} minutos.',
          );
        } else if (remainingAttempts > 0) {
          _showError(
            'Credenciales incorrectas.\n'
            'Te quedan $remainingAttempts intentos antes del bloqueo.',
          );
        } else {
          _showError('Credenciales incorrectas');
        }
        
        _checkAccountStatus();
      }
    } catch (e) {
      // Manejar excepciones específicas de bloqueo
      final errorMessage = e.toString();
      if (errorMessage.contains('bloqueada')) {
        _showError(errorMessage);
        _checkAccountStatus();
      } else {
        _showError('Error al iniciar sesión: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AlertService.showError(context, 'Error', message);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo o título
                    Icon(
                      Icons.school,
                      size: 64,
                      color: Color(0xff6C4DDC),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff2E2F44),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ingresa tus credenciales para acceder',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Campo de email
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        // Verificar estado de cuenta cuando cambia el email
                        _checkAccountStatus();
                      },
                    ),
                    SizedBox(height: 16),

                    // Campo de contraseña
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      obscureText: _obscurePassword,
                    ),
                    
                    // Mensaje de seguridad
                    if (_securityMessage != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _securityMessage!.contains('bloqueada')
                              ? Colors.red[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _securityMessage!.contains('bloqueada')
                                ? Colors.red[300]!
                                : Colors.orange[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _securityMessage!.contains('bloqueada')
                                  ? Icons.lock
                                  : Icons.warning,
                              color: _securityMessage!.contains('bloqueada')
                                  ? Colors.red[700]
                                  : Colors.orange[700],
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _securityMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _securityMessage!.contains('bloqueada')
                                      ? Colors.red[900]
                                      : Colors.orange[900],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 24),

                    // Botón de login
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Enlace de olvidaste tu contraseña
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PasswordResetScreen(),
                          ),
                        );
                      },
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),

                    // Enlace de registro
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register-student');
                      },
                      child: Text(
                        '¿No tienes cuenta? Regístrate aquí',
                        style: TextStyle(
                          color: Color(0xff6C4DDC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}