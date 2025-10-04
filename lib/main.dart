import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend_app/screens/inicio/main_menu.dart';
import 'package:frontend_app/screens/inicio/set_password_page.dart';
import 'package:frontend_app/screens/admin/manage_emisores_screen.dart';
import 'package:frontend_app/screens/admin/faculties_programs_screen.dart';
import 'package:frontend_app/screens/certificates/my_certificates_screen.dart';
import 'package:frontend_app/screens/inicio/register_student.dart';
import 'package:frontend_app/screens/programs/programs_opportunities_screen.dart';
import 'package:frontend_app/screens/programs/my_applications_screen.dart';
import 'package:frontend_app/screens/programs/applications_management_screen.dart';
import 'package:frontend_app/screens/programs/programs_management_screen.dart';
import 'package:frontend_app/screens/programs/create_program_screen.dart';
import 'package:frontend_app/services/database_initializer.dart';
import 'package:frontend_app/services/super_admin_initializer.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar datos de ejemplo en la base de datos
  await DatabaseInitializer.initializeSampleData();
  
  // Inicializar Super Admin
  await SuperAdminInitializer.initializeSuperAdmin();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certiblock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainMenu(),

      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/set-password')) {
          final uri = Uri.parse(settings.name!);
          final userId = uri.queryParameters['userId'] ?? '';
          return MaterialPageRoute(
            builder: (_) => SetPasswordPage(userId: userId),
          );
        }
        
        // Ruta para gestión de emisores
        if (settings.name == '/manage_emisores') {
          return MaterialPageRoute(
            builder: (_) => ManageEmisoresScreen(),
          );
        }
        
        // Ruta para facultades y programas
        if (settings.name == '/faculties_programs') {
          return MaterialPageRoute(
            builder: (_) => ProgramsScreen(),
          );
        }
        
        // Ruta para mis certificados
        if (settings.name == '/my-certificates') {
          return MaterialPageRoute(
            builder: (_) => MyCertificatesScreen(),
          );
        }
        
        // Ruta para registro de estudiante
        if (settings.name == '/register-student') {
          return MaterialPageRoute(
            builder: (_) => RegisterStudent(),
          );
        }
        
        // Rutas para programas y postulaciones
        if (settings.name == '/programs-opportunities') {
          return MaterialPageRoute(
            builder: (_) => ProgramsOpportunitiesScreen(),
          );
        }
        
        if (settings.name == '/my-applications') {
          return MaterialPageRoute(
            builder: (_) => MyApplicationsScreen(),
          );
        }
        
        if (settings.name == '/applications-management') {
          return MaterialPageRoute(
            builder: (_) => ApplicationsManagementScreen(),
          );
        }
        
        if (settings.name == '/programs-management') {
          return MaterialPageRoute(
            builder: (_) => ProgramsManagementScreen(),
          );
        }
        
        if (settings.name == '/create-program') {
          return MaterialPageRoute(
            builder: (_) => CreateProgramScreen(),
          );
        }
        
        // Otras rutas...
        return null;
      },
      
    );
  }
}
