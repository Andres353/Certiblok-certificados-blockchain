// lib/screens/inicio/change_password_page.dart
// Pantalla para cambio obligatorio de contraseña temporal

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import '../../services/user_context_service.dart';
import '../admin/super_admin_dashboard.dart';
import '../admin/admin_dashboard.dart';
import '../emisor/emisor_dashboard.dart';
import '../student/student_dashboard.dart';
import '../public/public_dashboard.dart';

class ChangePasswordPage extends StatefulWidget {
  final String? currentPassword;
  
  const ChangePasswordPage({
    Key? key,
    this.currentPassword,
  }) : super(key: key);

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-llenar contraseña actual si se proporciona
    if (widget.currentPassword != null) {
      _currentPasswordController.text = widget.currentPassword!;
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentContext = UserContextService.currentContext;
      if (currentContext == null) {
        throw Exception('Contexto de usuario no disponible');
      }

      print('🔍 DEBUG CAMBIO CONTRASEÑA:');
      print('   Usuario: ${currentContext.userEmail}');
      print('   Rol: ${currentContext.userRole}');
      print('   UID: ${currentContext.userId}');
      print('   InstitutionId: ${currentContext.institutionId}');

      final supabase = Supabase.instance.client;
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      // Hash de la nueva contraseña
      final hashedNewPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      if (currentContext.userRole == 'admin_institution') {
        // Admin de institución - buscar en tabla institutions
        print('   🔐 Cambiando contraseña para admin de institución...');
        
        final institutionResponse = await supabase
            .from('institutions')
            .select('*')
            .eq('id', currentContext.institutionId ?? currentContext.userId)
            .single();

        // Verificar contraseña actual
        final storedPassword = institutionResponse['admin_password_hash'] ?? '';
        bool passwordMatches = false;

        if (storedPassword.startsWith('\$2') && storedPassword.length >= 28) {
          try {
            passwordMatches = BCrypt.checkpw(currentPassword, storedPassword);
          } catch (e) {
            passwordMatches = currentPassword == storedPassword;
          }
        } else {
          passwordMatches = currentPassword == storedPassword;
        }

        if (!passwordMatches) {
          throw Exception('La contraseña actual es incorrecta');
        }

        // Actualizar contraseña en Supabase
        await supabase
            .from('institutions')
            .update({
              'admin_password_hash': hashedNewPassword,
              'admin_must_change_password': false,
              'admin_is_temporary_password': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentContext.institutionId ?? currentContext.userId);

        print('   ✅ Contraseña de admin de institución cambiada exitosamente');

      } else {
        // Otros usuarios - buscar en tabla users
        print('   🔐 Cambiando contraseña para usuario...');
        
        final userResponse = await supabase
            .from('users')
            .select('*')
            .eq('id', currentContext.userId)
            .single();

        // Verificar contraseña actual
        final storedPassword = userResponse['password_hash'] ?? '';
        bool passwordMatches = false;

        if (storedPassword.startsWith('\$2') && storedPassword.length >= 28) {
          try {
            passwordMatches = BCrypt.checkpw(currentPassword, storedPassword);
          } catch (e) {
            passwordMatches = currentPassword == storedPassword;
          }
        } else {
          passwordMatches = currentPassword == storedPassword;
        }

        if (!passwordMatches) {
          throw Exception('La contraseña actual es incorrecta');
        }

        // Actualizar contraseña en Supabase
        await supabase
            .from('users')
            .update({
              'password_hash': hashedNewPassword,
              'must_change_password': false,
              'is_temporary_password': false,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentContext.userId);

        print('   ✅ Contraseña de usuario cambiada exitosamente');
      }

      // Actualizar contexto de usuario
      print('   Actualizando contexto de usuario...');
      final updatedContext = UserContext(
        userId: currentContext.userId,
        userRole: currentContext.userRole,
        institutionId: currentContext.institutionId,
        currentInstitution: currentContext.currentInstitution,
        userEmail: currentContext.userEmail,
        userName: currentContext.userName,
        mustChangePassword: false,
        isTemporaryPassword: false,
      );
      await UserContextService.setUserContext(updatedContext);
      print('   ✅ Contexto de usuario actualizado');

      // Mostrar éxito
      print('   Mostrando mensaje de éxito...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contraseña cambiada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Pequeño delay para asegurar que el contexto se actualice
        print('   Esperando actualización del contexto...');
        await Future.delayed(Duration(milliseconds: 500));

        // Navegar directamente al dashboard según el rol
        print('   Redirigiendo al dashboard del rol: ${currentContext.userRole}');
        print('   ✅ Contraseña cambiada exitosamente - Redirigiendo...');
        _navigateToDashboard(currentContext.userRole);
      }

    } catch (e) {
      print('❌ ERROR EN CAMBIO DE CONTRASEÑA: $e');
      String errorMessage = 'Error al cambiar contraseña';
      
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'La contraseña actual es incorrecta';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'La nueva contraseña es muy débil';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Debe iniciar sesión nuevamente';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = 'Usuario no encontrado';
      } else if (e.toString().contains('invalid-credential')) {
        errorMessage = 'Credenciales inválidas';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToDashboard(String role) {
    print('🚀 NAVEGANDO AL DASHBOARD - Rol: $role');
    switch (role) {
      case 'super_admin':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SuperAdminDashboard()),
        );
        break;
      case 'admin_institution':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
        break;
      case 'emisor':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmisorDashboard()),
        );
        break;
      case 'student':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => StudentDashboard()),
        );
        break;
      case 'public_user':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PublicDashboard()),
        );
        break;
      default:
        // Fallback a home page
        Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cambio de Contraseña'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // No mostrar botón de regreso
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cambio de Contraseña Obligatorio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Por seguridad, debe cambiar su contraseña temporal',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),

              // Contraseña actual
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  hintText: 'Ingrese su contraseña temporal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La contraseña actual es requerida';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Nueva contraseña
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  hintText: 'Ingrese su nueva contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La nueva contraseña es requerida';
                  }
                  if (value.length < 8) {
                    return 'La contraseña debe tener al menos 8 caracteres';
                  }
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                    return 'La contraseña debe contener mayúsculas, minúsculas y números';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Confirmar contraseña
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  hintText: 'Confirme su nueva contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La confirmación de contraseña es requerida';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Requisitos de contraseña
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requisitos de la contraseña:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Mínimo 8 caracteres'),
                    Text('• Al menos una letra mayúscula'),
                    Text('• Al menos una letra minúscula'),
                    Text('• Al menos un número'),
                    Text('• No usar contraseñas comunes'),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Botón de cambio
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Cambiar Contraseña',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
