// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_context_service.dart';
import '../models/institution.dart';
import '../data/sample_institutions.dart';
import 'institution_service.dart';

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
            // Verificar si debe cambiar contraseña
            final mustChangePassword = studentData['mustChangePassword'] == true;
            if (mustChangePassword) {
              print('⚠️ Usuario debe cambiar contraseña - usando loginWithContext');
              // Redirigir al login con contexto para manejar cambio de contraseña
              return 'NEEDS_PASSWORD_CHANGE';
            }
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
        final role = await getUserRole(user.uid);
        if (role != null) {
          // Verificar si debe cambiar contraseña
          final userDoc = await firestore.collection('users').doc(user.uid).get();
          final userData = userDoc.data();
          final mustChangePassword = userData?['mustChangePassword'] == true;
          
          if (mustChangePassword) {
            print('⚠️ Usuario debe cambiar contraseña - usando loginWithContext');
            return 'NEEDS_PASSWORD_CHANGE';
          }
        }
        return role;
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

/// Iniciar sesión y establecer contexto de usuario multi-tenant
Future<UserContext?> loginWithContext(String email, String password) async {
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
            final role = studentData['role'] ?? 'student';
            final institutionId = studentData['institutionId'];
            
            // Cargar institución si existe
            Institution? institution;
            if (institutionId != null) {
              try {
                institution = await InstitutionService.getInstitution(institutionId);
              } catch (e) {
                print('Error loading institution: $e');
                institution = SampleInstitutions.getInstitutionById(institutionId);
              }
            }

            // Verificar si debe cambiar contraseña
            final mustChangePassword = studentData['mustChangePassword'] == true;
            final isTemporaryPassword = studentData['isTemporaryPassword'] == true;

            print('🔍 DEBUG PASSWORD CHANGE (STUDENTS):');
            print('   mustChangePassword: $mustChangePassword');
            print('   isTemporaryPassword: $isTemporaryPassword');
            print('   role: $role');

            // Crear contexto de usuario
            final context = UserContext(
              userId: studentQuery.docs.first.id,
              userRole: role,
              institutionId: institutionId,
              currentInstitution: institution,
              userEmail: email.trim(),
              userName: studentData['fullName'] ?? email.trim(),
              mustChangePassword: mustChangePassword,
              isTemporaryPassword: isTemporaryPassword,
            );

            // Establecer contexto
            await UserContextService.setUserContext(context);
            
            return context;
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
        final role = await getUserRole(user.uid);
        if (role != null) {
          // Cargar datos del usuario
          final userDoc = await firestore.collection('users').doc(user.uid).get();
          final userData = userDoc.data();
          
          final institutionId = userData?['institutionId'];
          Institution? institution;
          if (institutionId != null) {
            try {
              institution = await InstitutionService.getInstitution(institutionId);
            } catch (e) {
              print('Error loading institution: $e');
              institution = SampleInstitutions.getInstitutionById(institutionId);
            }
          }

          // Verificar si debe cambiar contraseña
          final mustChangePassword = userData?['mustChangePassword'] == true;
          final isTemporaryPassword = userData?['isTemporaryPassword'] == true;

          print('🔍 DEBUG PASSWORD CHANGE:');
          print('   mustChangePassword: $mustChangePassword');
          print('   isTemporaryPassword: $isTemporaryPassword');
          print('   userData: $userData');

          // Crear contexto de usuario
          final context = UserContext(
            userId: user.uid,
            userRole: role,
            institutionId: institutionId,
            currentInstitution: institution,
            userEmail: email.trim(),
            userName: userData?['name'] ?? user.displayName ?? email.trim(),
            mustChangePassword: mustChangePassword,
            isTemporaryPassword: isTemporaryPassword,
          );

          // Establecer contexto
          await UserContextService.setUserContext(context);
          
          return context;
        }
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

/// Cerrar sesión y limpiar contexto
Future<void> logout() async {
  try {
    await auth.signOut();
    await UserContextService.clearUserContext();
  } catch (e) {
    print('Error al cerrar sesión: $e');
  }
}
