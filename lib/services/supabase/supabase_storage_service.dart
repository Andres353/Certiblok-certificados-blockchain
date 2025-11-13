// lib/services/supabase/supabase_storage_service.dart
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static SupabaseClient get _client => Supabase.instance.client;

  // 1. SUBIR ARCHIVO
  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
    String? contentType,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );
      
      // Obtener URL pública
      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error subiendo archivo $path a $bucket: $e');
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
