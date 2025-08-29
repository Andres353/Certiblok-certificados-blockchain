import 'package:flutter/material.dart';
import 'package:frontend_app/screens/admin_dashboard.dart' as admin;
import 'package:frontend_app/screens/emisor_dashboard.dart' as emisor;
import 'package:frontend_app/screens/student_dashboard.dart' as student;
import 'package:frontend_app/screens/public_dashboard.dart' as public;
import '../constants/roles.dart';

class HomePage extends StatelessWidget {
  final String role;
  HomePage({required this.role});

  @override
  Widget build(BuildContext context) {
    print('=== DEBUG HOMEPAGE ===');
    print('Rol recibido: $role');
    print('Tipo de rol: ${role.runtimeType}');
    
    // Usar los nuevos roles del sistema UV
    switch (role) {
      case UserRoles.ADMIN_UV:
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
      case 'admin':
        print('Enviando a AdminDashboard (legacy)');
        print('Construyendo AdminDashboard...');
        return admin.AdminDashboard();
      case 'user':
        print('Enviando a AdminDashboard (legacy user)');
        print('Construyendo AdminDashboard...');
        return admin.AdminDashboard(); // Cambiado de PublicDashboard a AdminDashboard
      case 'student':
        print('Enviando a StudentDashboard (legacy)');
        print('Construyendo StudentDashboard...');
        return student.StudentDashboard();
      default:
        print('Rol no reconocido, enviando a PublicDashboard por defecto');
        // Si no se reconoce el rol, mostrar dashboard público
        return public.PublicDashboard();
    }
  }
}
