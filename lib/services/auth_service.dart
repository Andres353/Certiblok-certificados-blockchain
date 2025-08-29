// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;

/// Registrar un usuario con FirebaseAuth y guardarlo en la colección 'users'
Future<void> registerUser(String email, String password) async {
  try {
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    User? user = userCredential.user;

    if (user != null) {
      // 🔄 Renovar token recién creado
      await user.getIdToken(true);

      // Guardar datos adicionales en Firestore
      await firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'role': 'user', // Rol por defecto al registrar
      });
      print('Usuario registrado con uid: ${user.uid}');
    }
  } on FirebaseAuthException catch (e) {
    print('Error al registrar usuario (FirebaseAuth): ${e.code} - ${e.message}');
  } catch (e, stackTrace) {
    print('Error inesperado al registrar usuario: $e');
    print('StackTrace: $stackTrace');
  }
}

/// Obtener el rol de un usuario desde la colección 'users'
Future<String?> getUserRole(String uid) async {
  try {
    DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
    print('Doc data para $uid: ${doc.data()}');
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data != null && data.containsKey('role')) {
        return data['role'] as String?;
      } else {
        print('No existe campo role en documento');
      }
    } else {
      print('Documento no existe');
    }
  } catch (e) {
    print('Error al obtener rol de usuario: $e');
  }
  return null;
}

/// Iniciar sesión y renovar token antes de acceder a Firestore
Future<String?> loginUser(String email, String password) async {
  try {
    // PRIMERO: Buscar en 'students' (prioridad alta)
    try {
      QuerySnapshot studentQuery = await firestore
          .collection('students')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (studentQuery.docs.isNotEmpty) {
        final studentData = studentQuery.docs.first.data() as Map<String, dynamic>;
        print('Usuario encontrado en students: ${studentData['role']}');

        if (studentData['password'] == password.trim()) {
          // Verificar si está verificado
          if (studentData['isVerified'] == true) {
            return studentData['role'] ?? 'student';
          } else {
            print('Estudiante no verificado');
            return null;
          }
        } else {
          print('Contraseña incorrecta para estudiante');
          return null;
        }
      }
    } catch (e) {
      print('Error al buscar en students: $e');
    }

    // SEGUNDO: Si no está en students, intentar FirebaseAuth
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // 🔄 Forzar renovación del token
        await user.getIdToken(true);
        print('Token renovado para: ${user.email}');

        // Buscar rol en 'users'
        return await getUserRole(user.uid);
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuth Error: ${e.code} - ${e.message}');
      return null;
    }
  } catch (e, stacktrace) {
    print('Error inesperado: $e');
    print('Stacktrace: $stacktrace');
  }

  return null;
}
