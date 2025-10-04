import 'package:flutter/material.dart';
import 'package:frontend_app/screens/admin/admin_dashboard.dart' as admin;
import 'package:frontend_app/screens/admin/super_admin_dashboard.dart' as super_admin;
import 'package:frontend_app/screens/emisor/emisor_dashboard.dart' as emisor;
import 'package:frontend_app/screens/student/student_dashboard.dart' as student;
import 'package:frontend_app/screens/public/public_dashboard.dart' as public;
import 'package:frontend_app/screens/inicio/change_password_page.dart';
import '../constants/roles.dart';
import '../services/user_context_service.dart';

class HomePage extends StatefulWidget {
  final String role;
  HomePage({required this.role});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkPasswordChange();
  }

  Future<void> _checkPasswordChange() async {
    // Cargar contexto de usuario
    final context = await UserContextService.loadUserContext();
    
    print('🔍 DEBUG PASSWORD CHECK:');
    print('   Context loaded: ${context != null}');
    if (context != null) {
      print('   mustChangePassword: ${context.mustChangePassword}');
      print('   isTemporaryPassword: ${context.isTemporaryPassword}');
      print('   userRole: ${context.userRole}');
    }
    
    // Verificar si el usuario necesita cambiar contraseña
    if (UserContextService.isInitialized && UserContextService.needsPasswordChange()) {
      print('🔄 REDIRIGIENDO A CAMBIO DE CONTRASEÑA');
      // Redirigir a la pantalla de cambio de contraseña
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          this.context,
          MaterialPageRoute(
            builder: (context) => ChangePasswordPage(),
          ),
        );
      });
    } else {
      print('✅ NO NECESITA CAMBIAR CONTRASEÑA');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('=== DEBUG HOMEPAGE ===');
    print('Rol recibido: ${widget.role}');
    print('Tipo de rol: ${widget.role.runtimeType}');
    
    // Usar los nuevos roles del sistema multi-tenant
    switch (widget.role) {
      case UserRoles.SUPER_ADMIN:
        print('Enviando a SuperAdminDashboard');
        return super_admin.SuperAdminDashboard();
      case UserRoles.ADMIN_INSTITUTION:
        print('Enviando a AdminDashboard');
        return admin.AdminDashboard();
      case UserRoles.EMISOR:
        print('Enviando a EmisorDashboard');
        return emisor.EmisorDashboard();
      case UserRoles.STUDENT:
        print('Enviando a StudentDashboard');
        return student.StudentDashboard();
      case UserRoles.PUBLIC_USER:
        print('Enviando a PublicDashboard');
        return public.PublicDashboard();
      // Mantener compatibilidad con roles legacy
      case UserRoles.ADMIN_UV:
        print('Enviando a AdminDashboard (legacy UV)');
        return admin.AdminDashboard();
      case 'admin':
        print('Enviando a AdminDashboard (legacy)');
        return admin.AdminDashboard();
      case 'user':
        print('Enviando a AdminDashboard (legacy user)');
        return admin.AdminDashboard();

      default:
        print('Rol no reconocido, enviando a PublicDashboard por defecto');
        // Si no se reconoce el rol, mostrar dashboard público
        return public.PublicDashboard();
    }
  }
}
