// lib/services/supabase/supabase_database_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDatabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // 1. OBTENER DOCUMENTO POR ID
  static Future<Map<String, dynamic>?> getDocument(String collection, String id) async {
    try {
      final response = await _client
          .from(collection)
          .select('*')
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      print('Error obteniendo documento $id de $collection: $e');
      return null;
    }
  }

  // 2. OBTENER DOCUMENTOS CON FILTROS (SIN VARIABLES INTERMEDIAS)
  static Future<List<Map<String, dynamic>>> getDocuments(
    String collection, {
    String? whereColumn,
    dynamic whereValue,
    int? limit,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      // Construir consulta directamente sin variables intermedias
      if (whereColumn != null && whereValue != null && orderBy != null && limit != null) {
        final response = await _client
            .from(collection)
            .select('*')
            .eq(whereColumn, whereValue)
            .order(orderBy, ascending: ascending)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else if (whereColumn != null && whereValue != null && orderBy != null) {
        final response = await _client
            .from(collection)
            .select('*')
            .eq(whereColumn, whereValue)
            .order(orderBy, ascending: ascending);
        return List<Map<String, dynamic>>.from(response);
      } else if (whereColumn != null && whereValue != null && limit != null) {
        final response = await _client
            .from(collection)
            .select('*')
            .eq(whereColumn, whereValue)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else if (whereColumn != null && whereValue != null) {
        final response = await _client
            .from(collection)
            .select('*')
            .eq(whereColumn, whereValue);
        return List<Map<String, dynamic>>.from(response);
      } else if (orderBy != null && limit != null) {
        final response = await _client
            .from(collection)
            .select('*')
            .order(orderBy, ascending: ascending)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else if (orderBy != null) {
        final response = await _client
            .from(collection)
            .select('*')
            .order(orderBy, ascending: ascending);
        return List<Map<String, dynamic>>.from(response);
      } else if (limit != null) {
        final response = await _client
            .from(collection)
            .select('*')
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } else {
        final response = await _client
            .from(collection)
            .select('*');
        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      print('Error obteniendo documentos de $collection: $e');
      return [];
    }
  }

  // 3. CREAR DOCUMENTO
  static Future<Map<String, dynamic>?> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from(collection)
          .insert(data)
          .select()
          .single();
      return response;
    } catch (e) {
      print('Error creando documento en $collection: $e');
      return null;
    }
  }

  // 4. ACTUALIZAR DOCUMENTO
  static Future<bool> updateDocument(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client
          .from(collection)
          .update(data)
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error actualizando documento $id en $collection: $e');
      return false;
    }
  }

  // 5. ELIMINAR DOCUMENTO
  static Future<bool> deleteDocument(String collection, String id) async {
    try {
      await _client
          .from(collection)
          .delete()
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error eliminando documento $id de $collection: $e');
      return false;
    }
  }

  // 6. BUSCAR DOCUMENTOS CON MÚLTIPLES FILTROS (SIN VARIABLES INTERMEDIAS)
  static Future<List<Map<String, dynamic>>> searchDocuments(
    String collection, {
    Map<String, dynamic>? filters,
    int? limit,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      if (filters != null && filters.isNotEmpty) {
        // Para múltiples filtros, usar el primer filtro y luego filtrar en memoria
        final firstKey = filters.keys.first;
        final firstValue = filters[firstKey];
        
        if (orderBy != null && limit != null) {
          final response = await _client
              .from(collection)
              .select('*')
              .eq(firstKey, firstValue)
              .order(orderBy, ascending: ascending)
              .limit(limit);
          var results = List<Map<String, dynamic>>.from(response);
          
          // Aplicar filtros adicionales en memoria
          for (int i = 1; i < filters.length; i++) {
            final key = filters.keys.elementAt(i);
            final value = filters[key];
            results = results.where((item) => item[key] == value).toList();
          }
          
          return results;
        } else if (orderBy != null) {
          final response = await _client
              .from(collection)
              .select('*')
              .eq(firstKey, firstValue)
              .order(orderBy, ascending: ascending);
          var results = List<Map<String, dynamic>>.from(response);
          
          // Aplicar filtros adicionales en memoria
          for (int i = 1; i < filters.length; i++) {
            final key = filters.keys.elementAt(i);
            final value = filters[key];
            results = results.where((item) => item[key] == value).toList();
          }
          
          return results;
        } else if (limit != null) {
          final response = await _client
              .from(collection)
              .select('*')
              .eq(firstKey, firstValue)
              .limit(limit);
          var results = List<Map<String, dynamic>>.from(response);
          
          // Aplicar filtros adicionales en memoria
          for (int i = 1; i < filters.length; i++) {
            final key = filters.keys.elementAt(i);
            final value = filters[key];
            results = results.where((item) => item[key] == value).toList();
          }
          
          return results;
        } else {
          final response = await _client
              .from(collection)
              .select('*')
              .eq(firstKey, firstValue);
          var results = List<Map<String, dynamic>>.from(response);
          
          // Aplicar filtros adicionales en memoria
          for (int i = 1; i < filters.length; i++) {
            final key = filters.keys.elementAt(i);
            final value = filters[key];
            results = results.where((item) => item[key] == value).toList();
          }
          
          return results;
        }
      } else {
        // Sin filtros
        if (orderBy != null && limit != null) {
          final response = await _client
              .from(collection)
              .select('*')
              .order(orderBy, ascending: ascending)
              .limit(limit);
          return List<Map<String, dynamic>>.from(response);
        } else if (orderBy != null) {
          final response = await _client
              .from(collection)
              .select('*')
              .order(orderBy, ascending: ascending);
          return List<Map<String, dynamic>>.from(response);
        } else if (limit != null) {
          final response = await _client
              .from(collection)
              .select('*')
              .limit(limit);
          return List<Map<String, dynamic>>.from(response);
        } else {
          final response = await _client
              .from(collection)
              .select('*');
          return List<Map<String, dynamic>>.from(response);
        }
      }
    } catch (e) {
      print('Error buscando documentos en $collection: $e');
      return [];
    }
  }

  // 7. CONTAR DOCUMENTOS (SIN VARIABLES INTERMEDIAS)
  static Future<int> countDocuments(
    String collection, {
    String? whereColumn,
    dynamic whereValue,
  }) async {
    try {
      if (whereColumn != null && whereValue != null) {
        final response = await _client
            .from(collection)
            .select('id')
            .eq(whereColumn, whereValue);
        return response.length;
      } else {
        final response = await _client
            .from(collection)
            .select('id');
        return response.length;
      }
    } catch (e) {
      print('Error contando documentos en $collection: $e');
      return 0;
    }
  }

  // 8. TRANSACCIÓN (BATCH OPERATIONS)
  static Future<bool> batchOperation(List<Map<String, dynamic>> operations) async {
    try {
      // Supabase no tiene transacciones nativas, pero podemos hacer operaciones en lote
      for (final operation in operations) {
        final action = operation['action'] as String;
        final collection = operation['collection'] as String;
        final data = operation['data'] as Map<String, dynamic>;
        
        switch (action) {
          case 'create':
            await _client.from(collection).insert(data);
            break;
          case 'update':
            await _client.from(collection).update(data).eq('id', data['id']);
            break;
          case 'delete':
            await _client.from(collection).delete().eq('id', data['id']);
            break;
        }
      }
      return true;
    } catch (e) {
      print('Error en operación en lote: $e');
      return false;
    }
  }

  // 9. MÉTODOS ESPECÍFICOS PARA EVITAR ERRORES DE TIPOS
  
  // Obtener documentos con filtro simple
  static Future<List<Map<String, dynamic>>> getDocumentsByField(
    String collection,
    String field,
    dynamic value,
  ) async {
    try {
      final response = await _client
          .from(collection)
          .select('*')
          .eq(field, value);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo documentos por $field: $e');
      return [];
    }
  }

  // Obtener documentos ordenados
  static Future<List<Map<String, dynamic>>> getDocumentsOrdered(
    String collection,
    String orderBy,
    {bool ascending = true}
  ) async {
    try {
      final response = await _client
          .from(collection)
          .select('*')
          .order(orderBy, ascending: ascending);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo documentos ordenados: $e');
      return [];
    }
  }

  // Obtener documentos con límite
  static Future<List<Map<String, dynamic>>> getDocumentsLimited(
    String collection,
    int limit,
  ) async {
    try {
      final response = await _client
          .from(collection)
          .select('*')
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo documentos limitados: $e');
      return [];
    }
  }
}