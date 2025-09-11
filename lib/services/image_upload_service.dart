// lib/services/image_upload_service.dart
// Servicio para manejo de imágenes y logos de instituciones

import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

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
      final Uint8List imageBytes = await image.readAsBytes();
      print('📊 Tamaño de imagen: ${imageBytes.length} bytes');
      
      // Validar tamaño
      if (!isValidImageSize(imageBytes)) {
        throw Exception('La imagen es demasiado grande. Máximo 5MB permitido.');
      }
      
      // Generar nombre único
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.name)}';
      print('📁 Nombre de archivo: $fileName');
      
      // Subir a Firebase Storage
      print('⬆️ Subiendo a Firebase Storage...');
      final String downloadUrl = await uploadImageBytes(
        imageBytes, 
        '$folder/$fileName',
      );

      print('✅ Imagen subida exitosamente');
      return downloadUrl;
    } catch (e) {
      print('❌ Error al seleccionar y subir imagen: $e');
      return null;
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

      final Uint8List imageBytes = await image.readAsBytes();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.name)}';
      
      return await uploadImageBytes(imageBytes, '$folder/$fileName');
    } catch (e) {
      print('Error al tomar foto y subir: $e');
      return null;
    }
  }

  // Subir bytes de imagen
  static Future<String> uploadImageBytes(Uint8List imageBytes, String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      
      // Configurar metadatos para mejor compatibilidad con web
      final metadata = SettableMetadata(
        contentType: 'image/png',
        cacheControl: 'public, max-age=31536000',
      );
      
      // Para web, usar putString con base64 como alternativa
      if (kIsWeb) {
        final String base64String = base64Encode(imageBytes);
        final String dataUrl = 'data:image/png;base64,$base64String';
        
        // Guardar la URL base64 en Firestore como alternativa temporal
        await FirebaseFirestore.instance
            .collection('temp_images')
            .add({
          'dataUrl': dataUrl,
          'path': path,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        return dataUrl; // Retornar data URL temporal
      } else {
        // Para móvil, usar el método normal
        final UploadTask uploadTask = ref.putData(
          imageBytes,
          metadata,
        );
        
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        print('✅ Imagen subida exitosamente: $downloadUrl');
        return downloadUrl;
      }
    } catch (e) {
      print('❌ Error al subir imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  // Eliminar imagen
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen: $e');
    }
  }

  // Obtener URL optimizada para diferentes tamaños
  static String getOptimizedImageUrl(String originalUrl, {
    int width = 200,
    int height = 200,
    String quality = 'auto',
  }) {
    // Para Firebase Storage, podemos usar parámetros de consulta
    // o implementar Cloud Functions para redimensionamiento
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

  // Comprimir imagen si es necesario
  static Future<Uint8List> compressImageIfNeeded(Uint8List imageBytes, {
    int maxSizeMB = 2,
  }) async {
    if (imageBytes.length <= maxSizeMB * 1024 * 1024) {
      return imageBytes;
    }

    // Aquí podrías implementar compresión con packages como:
    // - flutter_image_compress
    // - image
    // Por ahora retornamos la imagen original
    return imageBytes;
  }
}
