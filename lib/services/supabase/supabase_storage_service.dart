// lib/services/supabase/supabase_storage_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_context_service.dart';

class SupabaseStorageService {
  static SupabaseClient get _client => Supabase.instance.client;

  // 1. SUBIR ARCHIVO
  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
    bool requireAuth = false, // Por defecto no requiere autenticación (para registro de instituciones)
  }) async {
    try {
      // Verificar autenticación solo si es requerida
      if (requireAuth) {
        final user = _client.auth.currentUser;
        final context = UserContextService.currentContext;
        
        if (user == null && context == null) {
          print('❌ Error: Usuario no autenticado en Supabase ni en contexto de aplicación');
          throw Exception('Usuario no autenticado. Por favor, inicia sesión nuevamente.');
        }
        
        if (user != null) {
          print('🔐 Usuario autenticado en Supabase Auth: ${user.id}');
          print('🔐 Email: ${user.email}');
          print('🔐 Sesión activa: ${_client.auth.currentSession != null}');
        } else if (context != null) {
          print('⚠️ No hay sesión en Supabase Auth, pero hay contexto de usuario');
          print('   Usuario: ${context.userEmail}');
          print('   Rol: ${context.userRole}');
          print('   Intentando subir archivo usando contexto de usuario...');
          print('   NOTA: Esto requiere que las políticas RLS estén configuradas para autenticación personalizada');
          print('   Si falla, ejecuta: supabase_storage_policies_custom_auth.sql');
        }
      } else {
        print('🔓 Subiendo archivo sin requerir autenticación (registro público)');
      }
      
      print('📤 Subiendo archivo a bucket: $bucket, path: $path');
      
      await _client.storage.from(bucket).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );
      
      // Obtener URL según el tipo de bucket
      // Para buckets públicos: usar getPublicUrl
      // Para buckets privados: usar getSignedUrl
      String fileUrl;
      
      // Verificar si el bucket es público o privado
      // Por ahora, asumimos que pdfs puede ser privado, otros son públicos
      if (bucket == 'pdfs') {
        // Para bucket pdfs, intentar URL pública primero
        // Si el bucket es público, funcionará
        // Si es privado, necesitamos URL firmada
        try {
          fileUrl = _client.storage.from(bucket).getPublicUrl(path);
          print('✅ Archivo subido exitosamente (URL pública): $fileUrl');
        } catch (e) {
          // Si falla, el bucket es privado, usar URL firmada
          print('⚠️ Bucket pdfs es privado, generando URL firmada...');
          final signedUrl = await _client.storage
              .from(bucket)
              .createSignedUrl(path, 86400); // Válida por 24 horas
          fileUrl = signedUrl;
          print('✅ Archivo subido exitosamente (URL firmada): $fileUrl');
        }
      } else {
        // Para otros buckets (públicos), usar URL pública
        fileUrl = _client.storage.from(bucket).getPublicUrl(path);
        print('✅ Archivo subido exitosamente (URL pública): $fileUrl');
      }
      
      return fileUrl;
    } catch (e) {
      print('❌ Error subiendo archivo $path a $bucket: $e');
      print('   Tipo de error: ${e.runtimeType}');
      if (e.toString().contains('row-level security')) {
        print('⚠️ Error de RLS - Verifica que las políticas estén configuradas correctamente');
        print('   Para registro de instituciones, ejecuta supabase_storage_policies_fix.sql');
      }
      return null;
    }
  }

  // 2. DESCARGAR ARCHIVO
  static Future<Uint8List?> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final response = await _client.storage.from(bucket).download(path);
      return response;
    } catch (e) {
      print('Error descargando archivo $path de $bucket: $e');
      return null;
    }
  }

  // 3. ELIMINAR ARCHIVO
  static Future<bool> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
      return true;
    } catch (e) {
      print('Error eliminando archivo $path de $bucket: $e');
      return false;
    }
  }

  // 4. OBTENER URL PÚBLICA
  static String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // 5. OBTENER URL FIRMADA (TEMPORAL)
  static Future<String?> getSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600, // 1 hora por defecto
  }) async {
    try {
      final response = await _client.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);
      return response;
    } catch (e) {
      print('Error obteniendo URL firmada para $path: $e');
      return null;
    }
  }

  // 6. LISTAR ARCHIVOS EN BUCKET
  static Future<List<FileObject>> listFiles({
    required String bucket,
    String? folder,
  }) async {
    try {
      final response = await _client.storage
          .from(bucket)
          .list(
            path: folder ?? '',
          );
      return response;
    } catch (e) {
      print('Error listando archivos en $bucket: $e');
      return [];
    }
  }

  // 7. COPIAR ARCHIVO
  static Future<bool> copyFile({
    required String bucket,
    required String sourcePath,
    required String destinationPath,
  }) async {
    try {
      // Descargar archivo original
      final fileBytes = await downloadFile(bucket: bucket, path: sourcePath);
      if (fileBytes == null) return false;

      // Subir como nuevo archivo
      final newUrl = await uploadFile(
        bucket: bucket,
        path: destinationPath,
        fileBytes: fileBytes,
      );
      
      return newUrl != null;
    } catch (e) {
      print('Error copiando archivo de $sourcePath a $destinationPath: $e');
      return false;
    }
  }

  // 8. MOVER ARCHIVO
  static Future<bool> moveFile({
    required String bucket,
    required String sourcePath,
    required String destinationPath,
  }) async {
    try {
      // Copiar archivo
      final success = await copyFile(
        bucket: bucket,
        sourcePath: sourcePath,
        destinationPath: destinationPath,
      );
      
      if (success) {
        // Eliminar archivo original
        return await deleteFile(bucket: bucket, path: sourcePath);
      }
      
      return false;
    } catch (e) {
      print('Error moviendo archivo de $sourcePath a $destinationPath: $e');
      return false;
    }
  }

  // 9. CREAR BUCKET
  static Future<bool> createBucket({
    required String bucketName,
    bool isPublic = false,
  }) async {
    try {
      await _client.storage.createBucket(
        bucketName,
        BucketOptions(
          public: isPublic,
        ),
      );
      return true;
    } catch (e) {
      print('Error creando bucket $bucketName: $e');
      return false;
    }
  }

  // 10. ELIMINAR BUCKET
  static Future<bool> deleteBucket(String bucketName) async {
    try {
      await _client.storage.deleteBucket(bucketName);
      return true;
    } catch (e) {
      print('Error eliminando bucket $bucketName: $e');
      return false;
    }
  }
}
