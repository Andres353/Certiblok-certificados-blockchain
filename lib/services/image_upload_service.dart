// lib/services/image_upload_service.dart
// Servicio para manejo de imágenes y logos de instituciones
// MIGRADO A SUPABASE STORAGE

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'supabase/supabase_storage_service.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  // Buckets organizados en Supabase
  static const String _logosBucket = 'institution-logos';
  static const String _imagesBucket = 'images';
  static const String _pdfsBucket = 'pdfs';
  static const String _signaturesBucket = 'signatures';

  // Subir imagen desde galería
  static Future<String?> pickAndUploadImage({
    String folder = 'institution_logos',
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      print('🔄 Iniciando selección de imagen...');
      
      // Seleccionar imagen
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (image == null) {
        print('❌ No se seleccionó ninguna imagen');
        return null;
      }

      print('✅ Imagen seleccionada: ${image.name}');
      
      // Leer bytes de la imagen
      Uint8List imageBytes = await image.readAsBytes();
      print('📊 Tamaño original: ${imageBytes.length} bytes');
      
      // Comprimir imagen automáticamente
      imageBytes = await compressImage(imageBytes, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality);
      print('📊 Tamaño después de compresión: ${imageBytes.length} bytes');
      
      // Validar tamaño
      if (!isValidImageSize(imageBytes)) {
        throw Exception('La imagen es demasiado grande. Máximo 5MB permitido.');
      }
      
      // Determinar bucket según el tipo
      String bucket = _getBucketForFolder(folder);
      
      // Generar nombre único
      final String baseName = path.basenameWithoutExtension(image.name);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$baseName.jpg';
      final String filePath = folder.isEmpty ? fileName : '$folder/$fileName';
      
      print('📁 Subiendo a Supabase Storage...');
      print('   Bucket: $bucket');
      print('   Path: $filePath');
      
      // NO requerir autenticación - todas las subidas son públicas
      bool requireAuth = false;
      
      // Subir a Supabase Storage
      final String? downloadUrl = await SupabaseStorageService.uploadFile(
        bucket: bucket,
        path: filePath,
        fileBytes: imageBytes,
        contentType: 'image/jpeg',
        requireAuth: requireAuth,
      );

      if (downloadUrl == null) {
        throw Exception('No se pudo obtener la URL de la imagen subida');
      }

      print('✅ Imagen subida exitosamente: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error al seleccionar y subir imagen: $e');
      rethrow;
    }
  }

  // Subir imagen desde cámara (solo móvil)
  static Future<String?> pickAndUploadImageFromCamera({
    String folder = 'institution_logos',
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      // Verificar si estamos en web
      if (kIsWeb) {
        throw Exception('La cámara no está disponible en web. Use la galería en su lugar.');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );

      if (image == null) return null;

      Uint8List imageBytes = await image.readAsBytes();
      
      // Comprimir imagen automáticamente
      imageBytes = await compressImage(imageBytes, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality);
      
      String bucket = _getBucketForFolder(folder);
      final String baseName = path.basenameWithoutExtension(image.path);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$baseName.jpg';
      final String filePath = folder.isEmpty ? fileName : '$folder/$fileName';
      
      // NO requerir autenticación - todas las subidas son públicas
      bool requireAuth = false;
      
      final String? downloadUrl = await SupabaseStorageService.uploadFile(
        bucket: bucket,
        path: filePath,
        fileBytes: imageBytes,
        contentType: 'image/jpeg',
        requireAuth: requireAuth,
      );

      return downloadUrl;
    } catch (e) {
      print('❌ Error al tomar foto y subir: $e');
      return null;
    }
  }

  // Subir bytes de imagen (método principal)
  static Future<String> uploadImageBytes(Uint8List imageBytes, String filePathParam) async {
    try {
      print('🔄 Subiendo imagen a Supabase Storage...');
      print('📊 Tamaño original: ${imageBytes.length} bytes');
      
      // Comprimir imagen automáticamente si es muy grande
      if (imageBytes.length > 500 * 1024) { // Si es mayor a 500KB
        print('🔄 Comprimiendo imagen automáticamente...');
        imageBytes = await compressImage(imageBytes);
        print('📊 Tamaño después de compresión: ${imageBytes.length} bytes');
      }
      
      // Determinar bucket y path
      final parts = filePathParam.split('/');
      String bucket = _imagesBucket;
      String filePath = filePathParam;
      
      if (parts.isNotEmpty) {
        if (parts[0].contains('logo') || parts[0].contains('institution')) {
          bucket = _logosBucket;
        } else if (parts[0].contains('signature')) {
          bucket = _signaturesBucket;
        }
      }
      
      // Asegurar extensión .jpg para mejor compresión
      if (!filePath.toLowerCase().endsWith('.jpg') && !filePath.toLowerCase().endsWith('.jpeg')) {
        final baseName = path.basenameWithoutExtension(filePath);
        final dirName = path.dirname(filePath);
        filePath = dirName == '.' ? '$baseName.jpg' : '$dirName/$baseName.jpg';
      }
      
      print('   Bucket: $bucket');
      print('   Path: $filePath');
      
      // NO requerir autenticación - todas las subidas son públicas
      bool requireAuth = false;
      
      // Subir a Supabase Storage
      final String? downloadUrl = await SupabaseStorageService.uploadFile(
        bucket: bucket,
        path: filePath,
        fileBytes: imageBytes,
        contentType: 'image/jpeg',
        requireAuth: requireAuth,
      );

      if (downloadUrl == null) {
        throw Exception('No se pudo obtener la URL de la imagen subida');
      }

      print('✅ Imagen subida exitosamente: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  // Eliminar imagen
  static Future<void> deleteImage(String imageUrl) async {
    try {
      // Extraer bucket y path de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      if (pathSegments.length < 2) {
        print('⚠️ URL de imagen no válida para eliminar: $imageUrl');
        return;
      }
      
      // El bucket suele estar en el path
      String bucket = _imagesBucket;
      String filePath = pathSegments.last;
      
      // Intentar determinar el bucket desde la URL
      if (imageUrl.contains('institution-logos') || imageUrl.contains('logo')) {
        bucket = _logosBucket;
      } else if (imageUrl.contains('signature')) {
        bucket = _signaturesBucket;
      }
      
      await SupabaseStorageService.deleteFile(
        bucket: bucket,
        path: filePath,
      );
      
      print('✅ Imagen eliminada exitosamente');
    } catch (e) {
      print('⚠️ Error al eliminar imagen: $e');
      // No lanzar excepción, solo loguear el error
    }
  }

  // Obtener URL optimizada para diferentes tamaños
  static String getOptimizedImageUrl(String originalUrl, {
    int width = 200,
    int height = 200,
    String quality = 'auto',
  }) {
    // Supabase Storage no tiene transformaciones automáticas como Firebase
    // Retornar la URL original por ahora
    // En el futuro se podría usar Supabase Edge Functions para redimensionamiento
    return originalUrl;
  }

  // Validar tipo de archivo
  static bool isValidImageType(String fileName) {
    final String extension = path.extension(fileName).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
  }

  // Validar tamaño de archivo (en bytes)
  static bool isValidImageSize(Uint8List imageBytes, {int maxSizeMB = 5}) {
    final int maxSizeBytes = maxSizeMB * 1024 * 1024;
    return imageBytes.length <= maxSizeBytes;
  }

  // Comprimir imagen automáticamente
  static Future<Uint8List> compressImage(
    Uint8List imageBytes, {
    int? maxWidth,
    int? maxHeight,
    int quality = 85,
  }) async {
    try {
      // Decodificar imagen
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('⚠️ No se pudo decodificar la imagen, retornando original');
        return imageBytes;
      }

      // Redimensionar si es necesario
      if (maxWidth != null || maxHeight != null) {
        final currentWidth = image.width;
        final currentHeight = image.height;
        
        int targetWidth = maxWidth ?? currentWidth;
        int targetHeight = maxHeight ?? currentHeight;
        
        // Mantener aspect ratio
        if (maxWidth != null && maxHeight != null) {
          final aspectRatio = currentWidth / currentHeight;
          if (currentWidth > maxWidth || currentHeight > maxHeight) {
            if (currentWidth / maxWidth > currentHeight / maxHeight) {
              targetWidth = maxWidth;
              targetHeight = (maxWidth / aspectRatio).round();
            } else {
              targetHeight = maxHeight;
              targetWidth = (maxHeight * aspectRatio).round();
            }
          } else {
            targetWidth = currentWidth;
            targetHeight = currentHeight;
          }
        } else if (maxWidth != null && currentWidth > maxWidth) {
          targetHeight = (currentHeight * maxWidth / currentWidth).round();
          targetWidth = maxWidth;
        } else if (maxHeight != null && currentHeight > maxHeight) {
          targetWidth = (currentWidth * maxHeight / currentHeight).round();
          targetHeight = maxHeight;
        } else {
          targetWidth = currentWidth;
          targetHeight = currentHeight;
        }
        
        if (targetWidth != currentWidth || targetHeight != currentHeight) {
          print('🔄 Redimensionando imagen: ${currentWidth}x${currentHeight} -> ${targetWidth}x${targetHeight}');
          image = img.copyResize(image, width: targetWidth, height: targetHeight);
        }
      }

      // Comprimir como JPEG (mejor compresión)
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(image, quality: quality),
      );

      print('✅ Imagen comprimida: ${imageBytes.length} bytes -> ${compressedBytes.length} bytes');
      return compressedBytes;
    } catch (e) {
      print('⚠️ Error al comprimir imagen: $e');
      // Retornar original si falla la compresión
      return imageBytes;
    }
  }

  // Comprimir imagen si es necesario (método legacy, ahora usa compressImage)
  static Future<Uint8List> compressImageIfNeeded(Uint8List imageBytes, {
    int maxSizeMB = 2,
  }) async {
    if (imageBytes.length <= maxSizeMB * 1024 * 1024) {
      return imageBytes;
    }

    // Comprimir automáticamente
    return await compressImage(imageBytes, quality: 80);
  }

  // Subir PDF a Supabase Storage (ahora usa Storage en lugar de base64)
  static Future<String> uploadPdfBytes(Uint8List pdfBytes, String filePathParam) async {
    try {
      print('🔄 Procesando PDF para Supabase Storage...');
      print('📊 Tamaño del archivo: ${pdfBytes.length} bytes');
      
      // Límite de Supabase: 50MB en plan gratuito, 5GB en plan Pro
      const int maxSupabaseSize = 50 * 1024 * 1024; // 50MB
      if (pdfBytes.length > maxSupabaseSize) {
        throw Exception('El PDF es demasiado grande (${(pdfBytes.length / 1024 / 1024).toStringAsFixed(1)}MB). El límite es ${(maxSupabaseSize / 1024 / 1024).toStringAsFixed(0)}MB. Por favor, comprime el PDF manualmente.');
      }
      
      // Determinar bucket y path
      final parts = filePathParam.split('/');
      String bucket = _pdfsBucket;
      String filePath = filePathParam;
      
      if (parts.isNotEmpty) {
        if (parts[0].contains('cv') || parts[0].contains('curriculum')) {
          filePath = 'cvs/${path.basename(filePath)}';
        } else if (parts[0].contains('motivation') || parts[0].contains('carta')) {
          filePath = 'motivation-letters/${path.basename(filePath)}';
        } else if (parts[0].contains('program')) {
          filePath = 'programs/${path.basename(filePath)}';
        }
      }
      
      // Asegurar extensión .pdf
      if (!filePath.toLowerCase().endsWith('.pdf')) {
        final baseName = path.basenameWithoutExtension(filePath);
        final dirName = path.dirname(filePath);
        filePath = dirName == '.' ? '$baseName.pdf' : '$dirName/$baseName.pdf';
      }
      
      // Generar nombre único si no tiene timestamp
      if (!filePath.contains(DateTime.now().millisecondsSinceEpoch.toString())) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = path.basename(filePath);
        final dirName = path.dirname(filePath);
        filePath = dirName == '.' ? '${timestamp}_$fileName' : '$dirName/${timestamp}_$fileName';
      }
      
      print('   Bucket: $bucket');
      print('   Path: $filePath');
      
      // NO requerir autenticación - todas las subidas son públicas
      bool requireAuth = false;
      
      // Subir a Supabase Storage
      final String? downloadUrl = await SupabaseStorageService.uploadFile(
        bucket: bucket,
        path: filePath,
        fileBytes: pdfBytes,
        contentType: 'application/pdf',
        requireAuth: requireAuth,
      );

      if (downloadUrl == null) {
        throw Exception('No se pudo obtener la URL del PDF subido');
      }

      print('✅ PDF subido exitosamente: $downloadUrl');
      print('📝 Método: Supabase Storage (no base64)');
      
      // Retornar URL de Supabase Storage
      return downloadUrl;
    } catch (e) {
      print('❌ Error al procesar PDF: $e');
      throw Exception('Error al procesar PDF: $e');
    }
  }

  // Determinar bucket según el folder
  static String _getBucketForFolder(String folder) {
    if (folder.contains('logo') || folder.contains('institution')) {
      return _logosBucket;
    } else if (folder.contains('signature')) {
      return _signaturesBucket;
    } else {
      return _imagesBucket;
    }
  }
}
