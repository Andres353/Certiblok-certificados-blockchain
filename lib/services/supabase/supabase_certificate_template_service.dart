// lib/services/supabase/supabase_certificate_template_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/certificate_template.dart';
import '../user_context_service.dart';
import 'supabase_config.dart';

class SupabaseCertificateTemplateService {
  static SupabaseClient get _client => SupabaseConfig.client;

  // Crear nueva plantilla
  static Future<String> createTemplate({
    required String name,
    required String description,
    TemplateDesign? design,
    TemplateLayout? layout,
    List<TemplateField>? fields,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      if (context.institutionId == null || context.institutionId!.isEmpty) {
        throw Exception('Institución no especificada');
      }

      final now = DateTime.now();
      final templateData = {
        'name': name,
        'description': description,
        'institution_id': context.institutionId!,
        'is_active': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'created_by': context.userId,
        'template_design': design?.toMap() ?? TemplateDesign().toMap(),
        'template_layout': layout?.toMap() ?? TemplateLayout().toMap(),
        'template_fields': fields?.map((f) => f.toMap()).toList() ?? _getDefaultFields(),
      };

      final response = await _client
          .from('certificate_templates')
          .insert(templateData)
          .select()
          .single();

      print('✅ Plantilla creada: ${response['id']}');
      return response['id'].toString();
    } catch (e) {
      print('❌ Error creando plantilla: $e');
      throw Exception('Error al crear plantilla: $e');
    }
  }

  // Obtener plantillas
  static Future<List<CertificateTemplate>> getTemplates({
    String? institutionId,
    bool includeDefault = true,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      String targetInstitutionId = institutionId ?? context.institutionId!;
      if (targetInstitutionId.isEmpty) {
        throw Exception('Institución no especificada');
      }

      var query = _client
          .from('certificate_templates')
          .select('*')
          .eq('institution_id', targetInstitutionId);

      if (!includeDefault) {
        query = query.eq('is_active', false);
      }

      final response = await query.order('created_at', ascending: false);

      List<CertificateTemplate> templates = response.map((data) {
        return CertificateTemplate.fromSupabase(data);
      }).toList();

      return templates;
    } catch (e) {
      print('❌ Error obteniendo plantillas: $e');
      throw Exception('Error al obtener plantillas: $e');
    }
  }

  // Obtener plantilla por ID
  static Future<CertificateTemplate?> getTemplateById(String templateId) async {
    try {
      final response = await _client
          .from('certificate_templates')
          .select('*')
          .eq('id', templateId)
          .single();

      if (response.isNotEmpty) {
        return CertificateTemplate.fromSupabase(response);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo plantilla por ID: $e');
      return null;
    }
  }

  // Actualizar plantilla
  static Future<bool> updateTemplate(String templateId, CertificateTemplate template) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos
      final existingTemplate = await getTemplateById(templateId);
      if (existingTemplate == null) {
        throw Exception('Plantilla no encontrada');
      }

      if (existingTemplate.institutionId != context.institutionId && !context.isSuperAdmin) {
        throw Exception('No tienes permisos para editar esta plantilla');
      }

      await _client
          .from('certificate_templates')
          .update({
            'name': template.name,
            'description': template.description,
            'template_design': template.design.toMap(),
            'template_layout': template.layout.toMap(),
            'template_fields': template.fields.map((f) => f.toMap()).toList(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', templateId);

      print('✅ Plantilla actualizada: $templateId');
      return true;
    } catch (e) {
      print('❌ Error actualizando plantilla: $e');
      return false;
    }
  }

  // Eliminar plantilla
  static Future<bool> deleteTemplate(String templateId) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar permisos
      final template = await getTemplateById(templateId);
      if (template == null) {
        throw Exception('Plantilla no encontrada');
      }

      if (template.institutionId != context.institutionId && !context.isSuperAdmin) {
        throw Exception('No tienes permisos para eliminar esta plantilla');
      }

      if (template.isDefault) {
        throw Exception('No se puede eliminar la plantilla activa');
      }

      await _client
          .from('certificate_templates')
          .delete()
          .eq('id', templateId);

      print('✅ Plantilla eliminada: $templateId');
      return true;
    } catch (e) {
      print('❌ Error eliminando plantilla: $e');
      return false;
    }
  }

  // Duplicar plantilla
  static Future<String> duplicateTemplate(String templateId, String newName) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      final originalTemplate = await getTemplateById(templateId);
      if (originalTemplate == null) {
        throw Exception('Plantilla original no encontrada');
      }

      final now = DateTime.now();
      final duplicatedData = {
        'name': newName,
        'description': '${originalTemplate.description} (Copia)',
        'institution_id': originalTemplate.institutionId,
        'is_active': false,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'created_by': context.userId,
        'template_design': originalTemplate.design.toMap(),
        'template_layout': originalTemplate.layout.toMap(),
        'template_fields': originalTemplate.fields.map((f) => f.toMap()).toList(),
      };

      final response = await _client
          .from('certificate_templates')
          .insert(duplicatedData)
          .select()
          .single();

      print('✅ Plantilla duplicada: ${response['id']}');
      return response['id'].toString();
    } catch (e) {
      print('❌ Error duplicando plantilla: $e');
      throw Exception('Error al duplicar plantilla: $e');
    }
  }

  // Obtener estadísticas de plantillas
  static Future<Map<String, int>> getTemplateStats() async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que institutionId no esté vacío
      if (context.institutionId == null || context.institutionId!.isEmpty) {
        throw Exception('Institución no especificada');
      }

      final response = await _client
          .from('certificate_templates')
          .select('is_active')
          .eq('institution_id', context.institutionId!);

      int total = response.length;
      int defaultTemplates = 0;
      int customTemplates = 0;

      for (var template in response) {
        if (template['is_active'] == true) {
          defaultTemplates++;
        } else {
          customTemplates++;
        }
      }

      return {
        'total': total,
        'default': defaultTemplates,
        'custom': customTemplates,
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas: $e');
      return {'total': 0, 'default': 0, 'custom': 0};
    }
  }

  // Buscar plantillas
  static Future<List<CertificateTemplate>> searchTemplates(String query) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      if (context.institutionId == null || context.institutionId!.isEmpty) {
        throw Exception('Institución no especificada');
      }

      final response = await _client
          .from('certificate_templates')
          .select('*')
          .eq('institution_id', context.institutionId!)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((data) {
        return CertificateTemplate.fromSupabase(data);
      }).toList();
    } catch (e) {
      print('❌ Error buscando plantillas: $e');
      return [];
    }
  }

  // Crear plantilla por defecto
  static Future<String> createDefaultTemplate(String institutionId) async {
    try {
      final now = DateTime.now();
      final defaultTemplateData = {
        'name': 'Plantilla por Defecto',
        'description': 'Plantilla básica para certificados',
        'institution_id': institutionId,
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'created_by': null,
        'template_design': {
          'background': '#FFFFFF',
          'border': '#E0E0E0',
          'borderRadius': 8,
        },
        'template_layout': {
          'width': 800,
          'height': 600,
          'orientation': 'landscape',
        },
        'template_fields': _getDefaultFields(),
      };

      final response = await _client
          .from('certificate_templates')
          .insert(defaultTemplateData)
          .select()
          .single();

      print('✅ Plantilla por defecto creada: ${response['id']}');
      return response['id'].toString();
    } catch (e) {
      print('❌ Error creando plantilla por defecto: $e');
      throw Exception('Error al crear plantilla por defecto: $e');
    }
  }

  // Obtener campos por defecto
  static List<Map<String, dynamic>> _getDefaultFields() {
    return [
      {
        'id': 'student_name',
        'label': 'Nombre del Estudiante',
        'type': 'text',
        'position': {
          'x': 0.5,
          'y': 0.4,
          'width': 0.8,
          'height': 0.1,
        },
        'style': {
          'fontSize': 24,
          'fontWeight': 'bold',
          'color': '#2E2F44',
          'textAlign': 'center',
        },
        'value': '',
        'order': 1,
      },
      {
        'id': 'certificate_title',
        'label': 'Título del Certificado',
        'type': 'text',
        'position': {
          'x': 0.5,
          'y': 0.2,
          'width': 0.8,
          'height': 0.08,
        },
        'style': {
          'fontSize': 20,
          'fontWeight': 'w600',
          'color': '#6C4DDC',
          'textAlign': 'center',
        },
        'value': '',
        'order': 2,
      },
      {
        'id': 'institution_name',
        'label': 'Nombre de la Institución',
        'type': 'text',
        'position': {
          'x': 0.5,
          'y': 0.6,
          'width': 0.8,
          'height': 0.06,
        },
        'style': {
          'fontSize': 16,
          'fontWeight': 'w500',
          'color': '#666666',
          'textAlign': 'center',
        },
        'value': '',
        'order': 3,
      },
      {
        'id': 'issue_date',
        'label': 'Fecha de Emisión',
        'type': 'date',
        'position': {
          'x': 0.5,
          'y': 0.8,
          'width': 0.4,
          'height': 0.05,
        },
        'style': {
          'fontSize': 14,
          'fontWeight': 'normal',
          'color': '#888888',
          'textAlign': 'center',
        },
        'value': '',
        'order': 4,
      },
    ];
  }

  // Obtener plantilla por defecto
  static Future<CertificateTemplate?> getDefaultTemplate() async {
    try {
      final response = await _client
          .from('certificate_templates')
          .select('*')
          .eq('is_active', true)
          .limit(1)
          .single();

      return CertificateTemplate.fromSupabase(response);
    } catch (e) {
      print('Error obteniendo plantilla por defecto: $e');
      return null;
    }
  }

  // Establecer plantilla por defecto
  static Future<void> setDefaultTemplate(String templateId) async {
    try {
      // Primero desactivar todas las plantillas
      await _client
          .from('certificate_templates')
          .update({'is_active': false})
          .neq('id', templateId);

      // Luego activar la plantilla seleccionada
      await _client
          .from('certificate_templates')
          .update({'is_active': true})
          .eq('id', templateId);
    } catch (e) {
      print('Error estableciendo plantilla por defecto: $e');
      throw Exception('Error estableciendo plantilla por defecto: $e');
    }
  }
}
