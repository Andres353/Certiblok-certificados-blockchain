import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend_app/screens/main_menu.dart';
import 'package:frontend_app/screens/set_password_page.dart'; // <-- Importa aquí
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        // Otras rutas...
        return null;
      },
      
    );
  }
}
