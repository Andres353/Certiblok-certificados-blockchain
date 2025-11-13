// lib/services/adapters/certificate_template_adapter.dart
import '../certificate_template_service.dart';
import '../supabase/supabase_certificate_template_service.dart';
import '../../models/certificate_template.dart';

class CertificateTemplateAdapter {
  static bool _useSupabase = false; // Flag para cambiar entre Firebase y Supabase

  // Cambiar entre Firebase y Supabase
  static void useSupabase(bool useSupabase) {
    _useSupabase = useSupabase;
    print('🔄 CertificateTemplateAdapter: ${useSupabase ? "Usando Supabase" : "Usando Firebase"}');
  }

  // Crear nueva plantilla
  static Future<String> createTemplate({
    required String name,
    required String description,
    TemplateDesign? design,
    TemplateLayout? layout,
    List<TemplateField>? fields,
  }) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.createTemplate(
        name: name,
        description: description,
        design: design,
        layout: layout,
        fields: fields,
      );
    } else {
      return await CertificateTemplateService.createTemplate(
        name: name,
        description: description,
        design: design,
        layout: layout,
        fields: fields,
      );
    }
  }

  // Obtener plantillas
  static Future<List<CertificateTemplate>> getTemplates({
    String? institutionId,
    bool includeDefault = true,
  }) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.getTemplates(
        institutionId: institutionId,
        includeDefault: includeDefault,
      );
    } else {
      return await CertificateTemplateService.getTemplates(
        institutionId: institutionId,
        includeDefault: includeDefault,
      );
    }
  }

  // Obtener plantilla por ID
  static Future<CertificateTemplate?> getTemplateById(String templateId) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.getTemplateById(templateId);
    } else {
      return await CertificateTemplateService.getTemplateById(templateId);
    }
  }

  // Actualizar plantilla
  static Future<bool> updateTemplate(String templateId, CertificateTemplate template) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.updateTemplate(templateId, template);
    } else {
      return await CertificateTemplateService.updateTemplate(templateId, template);
    }
  }

  // Eliminar plantilla
  static Future<bool> deleteTemplate(String templateId) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.deleteTemplate(templateId);
    } else {
      return await CertificateTemplateService.deleteTemplate(templateId);
    }
  }

  // Duplicar plantilla
  static Future<String> duplicateTemplate(String templateId, String newName) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.duplicateTemplate(templateId, newName);
    } else {
      return await CertificateTemplateService.duplicateTemplate(templateId, newName);
    }
  }

  // Obtener estadísticas de plantillas
  static Future<Map<String, int>> getTemplateStats() async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.getTemplateStats();
    } else {
      // Firebase no tiene método de estadísticas, implementar localmente
      try {
        final templates = await CertificateTemplateService.getTemplates();
        return {
          'total': templates.length,
          'default': templates.where((t) => t.isDefault).length,
          'custom': templates.where((t) => !t.isDefault).length,
        };
      } catch (e) {
        return {'total': 0, 'default': 0, 'custom': 0};
      }
    }
  }

  // Buscar plantillas
  static Future<List<CertificateTemplate>> searchTemplates(String query) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.searchTemplates(query);
    } else {
      // Firebase no tiene método de búsqueda directo, usar getTemplates
      try {
        final templates = await CertificateTemplateService.getTemplates();
        return templates.where((template) => 
          template.name.toLowerCase().contains(query.toLowerCase()) ||
          template.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
      } catch (e) {
        return [];
      }
    }
  }

  // Crear plantilla por defecto
  static Future<String> createDefaultTemplate(String institutionId) async {
    if (_useSupabase) {
      return await SupabaseCertificateTemplateService.createDefaultTemplate(institutionId);
    } else {
      return await CertificateTemplateService.createDefaultTemplate(institutionId);
    }
  }

  // Obtener plantilla por defecto
  static Future<CertificateTemplate?> getDefaultTemplate() async {
    if (_useSupabase) {
      // Buscar plantilla por defecto en Supabase
      try {
        final templates = await SupabaseCertificateTemplateService.getTemplates();
        return templates.firstWhere((template) => template.isDefault);
      } catch (e) {
        return null;
      }
    } else {
      return await CertificateTemplateService.getDefaultTemplate();
    }
  }

  // Establecer plantilla por defecto
  static Future<void> setDefaultTemplate(String templateId) async {
    if (_useSupabase) {
      // Implementar en Supabase si es necesario
      print('⚠️ setDefaultTemplate no implementado en Supabase');
    } else {
      await CertificateTemplateService.setDefaultTemplate(templateId);
    }
  }
}
