// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_context_service.dart';
import '../models/institution.dart';
import '../data/sample_institutions.dart';
import 'institution_service.dart';

final FirebaseAuth auth = FirebaseAuth.instance;
final FirebaseFirestore firestore = FirebaseFirestore.instance;

class AuthService {

  static Future<Map<String, dynamic>> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String studentId,
    String? phone,
    String? document,
    String? birthDate,
    String? address,
  }) async {
    try {
      // Verificar si el email ya existe
      final existingQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'El email ya está registrado',
        };
      }

      // Crear el estudiante en Firestore
      final docRef = await firestore.collection('users').add({
        'email': email.trim(),
        'password': password.trim(),
        'fullName': fullName.trim(),
        'studentId': studentId.trim(),
        'role': 'student',
        'phone': phone?.trim(),
        'document': document?.trim(),
        'birthDate': birthDate?.trim(),
        'address': address?.trim(),
        'isVerified': true,
        'mustChangePassword': false,
        'isTemporaryPassword': false,
        'createdAt': FieldValue.serverTimestamp(),
        'verificationCode': '000000',
      });

      print('✅ Estudiante registrado con ID: ${docRef.id}');

      return {
        'success': true,
        'message': 'Estudiante registrado exitosamente',
        'studentId': docRef.id,
      };
    } catch (e) {
      print('❌ Error registrando estudiante: $e');
      return {
        'success': false,
        'message': 'Error al registrar estudiante: $e',
      };
    }
  }
}

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
  print('🚀 INICIANDO loginUser para: $email');
  try {
    // PRIMERO: Buscar en 'users' (todos los usuarios: student, emisor, etc.)
    print('🔍 Buscando en colección users...');
    try {
      QuerySnapshot usersQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      print('📊 Resultados en users: ${usersQuery.docs.length} documentos encontrados');
      if (usersQuery.docs.isNotEmpty) {
        final userData = usersQuery.docs.first.data() as Map<String, dynamic>;
        print('Usuario encontrado en users: ${userData['role']}');

        // Para usuarios en Firestore, verificar contraseña directamente
        print('🔍 DEBUG PASSWORD COMPARISON:');
        print('   Contraseña ingresada: ${password.trim()}');
        print('   Contraseña en BD: ${userData['password']}');
        print('   ¿Coinciden?: ${userData['password'] == password.trim()}');
        
        if (userData['password'] == password.trim()) {
          // Verificar si está verificado
          if (userData['isVerified'] == true) {
            final role = userData['role'] ?? 'admin_institution';
            final institutionId = userData['institutionId'];
            
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
            final mustChangePassword = userData['mustChangePassword'] == true;
            final isTemporaryPassword = userData['isTemporaryPassword'] == true;

            print('🔍 DEBUG PASSWORD CHANGE (USERS):');
            print('   mustChangePassword: $mustChangePassword');
            print('   isTemporaryPassword: $isTemporaryPassword');
            print('   role: $role');

            // Crear contexto de usuario
            final context = UserContext(
              userId: usersQuery.docs.first.id,
              userRole: role,
              institutionId: institutionId,
              currentInstitution: institution,
              userEmail: email.trim(),
              userName: userData['name'] ?? userData['fullName'] ?? email.trim(),
              mustChangePassword: mustChangePassword,
              isTemporaryPassword: isTemporaryPassword,
            );

            // Establecer contexto
            await UserContextService.setUserContext(context);

            // Verificar si debe cambiar contraseña
            if (mustChangePassword) {
              print('⚠️ Usuario debe cambiar contraseña - usando loginWithContext');
              return 'NEEDS_PASSWORD_CHANGE';
            }
            
            return role;
          } else {
            print('Usuario no verificado');
            return null;
          }
        } else {
          print('Contraseña incorrecta para usuario');
          return null;
        }
      }
    } catch (e) {
      print('Error al buscar en users: $e');
    }

    // TERCERO: Si no está en users, intentar FirebaseAuth
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

  print('❌ No se encontró usuario válido en ninguna colección');
  return null;
}

/// Iniciar sesión y establecer contexto de usuario multi-tenant
Future<UserContext?> loginWithContext(String email, String password) async {
  print('🚀 INICIANDO loginWithContext para: $email');
  try {
    // PRIMERO: Buscar en 'users' (super_admin, emisor, student)
    print('🔍 Buscando en colección users...');
    try {
      QuerySnapshot usersQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      print('📊 Resultados en users: ${usersQuery.docs.length} documentos encontrados');
      if (usersQuery.docs.isNotEmpty) {
        final userData = usersQuery.docs.first.data() as Map<String, dynamic>;
        print('Usuario encontrado en users: ${userData['role']}');

        // Verificar contraseña directamente
        print('🔍 DEBUG PASSWORD COMPARISON (USERS):');
        print('   Contraseña ingresada: ${password.trim()}');
        print('   Contraseña en BD: ${userData['password']}');
        print('   ¿Coinciden?: ${userData['password'] == password.trim()}');
        
        if (userData['password'] == password.trim()) {
          // Verificar si está verificado
          if (userData['isVerified'] == true) {
            final role = userData['role'] ?? 'student';
            final institutionId = userData['institutionId'];
            
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
            final mustChangePassword = userData['mustChangePassword'] == true;
            final isTemporaryPassword = userData['isTemporaryPassword'] == true;

            print('🔍 DEBUG PASSWORD CHANGE (USERS):');
            print('   mustChangePassword: $mustChangePassword');
            print('   isTemporaryPassword: $isTemporaryPassword');
            print('   role: $role');

            // Crear contexto de usuario
            final context = UserContext(
              userId: usersQuery.docs.first.id,
              userRole: role,
              institutionId: institutionId,
              currentInstitution: institution,
              userEmail: email.trim(),
              userName: userData['name'] ?? userData['fullName'] ?? email.trim(),
              mustChangePassword: mustChangePassword,
              isTemporaryPassword: isTemporaryPassword,
            );

            // Establecer contexto
            await UserContextService.setUserContext(context);
            
            return context;
          } else {
            print('Usuario no verificado');
            return null;
          }
        } else {
          print('Contraseña incorrecta para usuario en users');
        }
      }
    } catch (e) {
      print('Error al buscar en users: $e');
    }

    // SEGUNDO: Buscar en 'institutions' (admin_institution)
    print('🔍 Buscando en colección institutions...');
    try {
      QuerySnapshot institutionsQuery = await firestore
          .collection('institutions')
          .where('adminEmail', isEqualTo: email.trim())
          .limit(1)
          .get();

      print('📊 Resultados en institutions: ${institutionsQuery.docs.length} documentos encontrados');
      if (institutionsQuery.docs.isNotEmpty) {
        final institutionData = institutionsQuery.docs.first.data() as Map<String, dynamic>;
        print('Institución encontrada: ${institutionData['name']}');

        // Verificar contraseña del admin
        print('🔍 DEBUG PASSWORD COMPARISON (INSTITUTIONS):');
        print('   Contraseña ingresada: ${password.trim()}');
        print('   Contraseña en BD: ${institutionData['adminPassword']}');
        print('   ¿Coinciden?: ${institutionData['adminPassword'] == password.trim()}');

        if (institutionData['adminPassword'] == password.trim()) {
          final institutionId = institutionsQuery.docs.first.id;
          final institution = Institution.fromFirestore(institutionData, institutionId);

          // Verificar si debe cambiar contraseña
          final mustChangePassword = institutionData['adminMustChangePassword'] == true;
          final isTemporaryPassword = institutionData['adminIsTemporaryPassword'] == true;

          print('🔍 DEBUG PASSWORD CHANGE (INSTITUTIONS):');
          print('   mustChangePassword: $mustChangePassword');
          print('   isTemporaryPassword: $isTemporaryPassword');
          print('   role: admin_institution');

          // Crear contexto de usuario
          final context = UserContext(
            userId: institutionId,
            userRole: 'admin_institution',
            institutionId: institutionId,
            currentInstitution: institution,
            userEmail: email.trim(),
            userName: institutionData['adminName'] ?? email.trim(),
            mustChangePassword: mustChangePassword,
            isTemporaryPassword: isTemporaryPassword,
          );

          // Establecer contexto
          await UserContextService.setUserContext(context);
          
          return context;
        } else {
          print('Contraseña incorrecta para admin de institución');
        }
      }
    } catch (e) {
      print('Error al buscar en institutions: $e');
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
