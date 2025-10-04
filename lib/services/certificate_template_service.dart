// lib/services/certificate_template_service.dart
// Servicio para gestionar plantillas de certificados

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/certificate_template.dart';
import 'user_context_service.dart';

class CertificateTemplateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'certificate_templates';

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

      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();

      final template = CertificateTemplate(
        id: docRef.id,
        name: name,
        description: description,
        institutionId: context.institutionId ?? '',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        createdBy: context.userId,
        design: design ?? TemplateDesign(),
        layout: layout ?? TemplateLayout(),
        fields: fields ?? _getDefaultFields(),
      );

      await docRef.set(template.toMap());

      print('✅ Plantilla creada: ${template.id}');
      return template.id;
    } catch (e) {
      print('❌ Error creando plantilla: $e');
      throw Exception('Error al crear plantilla: $e');
    }
  }

  // Obtener plantillas de la institución
  static Future<List<CertificateTemplate>> getTemplates({
    String? institutionId,
    bool includeDefault = true,
  }) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      String targetInstitutionId = institutionId ?? context.institutionId ?? '';
      if (targetInstitutionId.isEmpty) {
        throw Exception('Institución no especificada');
      }

      // Obtener todas las plantillas de la institución y filtrar en memoria
      // para evitar problemas de índice compuesto
      Query query = _firestore.collection(_collection)
          .where('institutionId', isEqualTo: targetInstitutionId);

      final querySnapshot = await query.get();
      
      List<CertificateTemplate> templates = querySnapshot.docs
          .map((doc) => CertificateTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Filtrar por isDefault si es necesario
      if (!includeDefault) {
        templates = templates.where((template) => !template.isDefault).toList();
      }

      // Ordenar por fecha de creación (descendente)
      templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return templates;
    } catch (e) {
      print('❌ Error obteniendo plantillas: $e');
      throw Exception('Error al obtener plantillas: $e');
    }
  }

  // Obtener plantilla por ID
  static Future<CertificateTemplate?> getTemplateById(String templateId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(templateId).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return CertificateTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id);
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

      await _firestore.collection(_collection).doc(templateId).update({
        ...template.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
        throw Exception('No se puede eliminar la plantilla por defecto');
      }

      await _firestore.collection(_collection).doc(templateId).delete();

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
      final originalTemplate = await getTemplateById(templateId);
      if (originalTemplate == null) {
        throw Exception('Plantilla original no encontrada');
      }

      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();

      final duplicatedTemplate = CertificateTemplate(
        id: docRef.id,
        name: newName,
        description: '${originalTemplate.description} (Copia)',
        institutionId: context.institutionId ?? '',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        createdBy: context.userId,
        design: originalTemplate.design,
        layout: originalTemplate.layout,
        fields: originalTemplate.fields.map((field) => TemplateField(
          id: '${field.id}_copy',
          type: field.type,
          label: field.label,
          value: field.value,
          position: field.position,
          style: field.style,
          isVisible: field.isVisible,
          order: field.order,
        )).toList(),
      );

      await docRef.set(duplicatedTemplate.toMap());

      print('✅ Plantilla duplicada: ${duplicatedTemplate.id}');
      return duplicatedTemplate.id;
    } catch (e) {
      print('❌ Error duplicando plantilla: $e');
      throw Exception('Error al duplicar plantilla: $e');
    }
  }

  // Establecer plantilla por defecto
  static Future<bool> setDefaultTemplate(String templateId) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      final template = await getTemplateById(templateId);
      if (template == null) {
        throw Exception('Plantilla no encontrada');
      }

      if (template.institutionId != context.institutionId && !context.isSuperAdmin) {
        throw Exception('No tienes permisos para modificar esta plantilla');
      }

      // Quitar el estado de plantilla por defecto de todas las plantillas de la institución
      final batch = _firestore.batch();
      final querySnapshot = await _firestore.collection(_collection)
          .where('institutionId', isEqualTo: template.institutionId)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isDefault': false});
      }

      // Establecer la nueva plantilla por defecto
      batch.update(_firestore.collection(_collection).doc(templateId), {
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      print('✅ Plantilla por defecto establecida: $templateId');
      return true;
    } catch (e) {
      print('❌ Error estableciendo plantilla por defecto: $e');
      return false;
    }
  }

  // Obtener plantilla por defecto de la institución
  static Future<CertificateTemplate?> getDefaultTemplate({String? institutionId}) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      String targetInstitutionId = institutionId ?? context.institutionId ?? '';
      if (targetInstitutionId.isEmpty) {
        throw Exception('Institución no especificada');
      }

      final querySnapshot = await _firestore.collection(_collection)
          .where('institutionId', isEqualTo: targetInstitutionId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return CertificateTemplate.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      print('❌ Error obteniendo plantilla por defecto: $e');
      return null;
    }
  }

  // Crear plantilla por defecto para una institución
  static Future<String> createDefaultTemplate(String institutionId) async {
    try {
      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();

      final defaultTemplate = CertificateTemplate(
        id: docRef.id,
        name: 'Plantilla por Defecto',
        description: 'Plantilla básica para certificados',
        institutionId: institutionId,
        isDefault: true,
        createdAt: now,
        updatedAt: now,
        createdBy: 'system',
        design: TemplateDesign(),
        layout: TemplateLayout(),
        fields: _getDefaultFields(),
      );

      await docRef.set(defaultTemplate.toMap());

      print('✅ Plantilla por defecto creada para institución: $institutionId');
      return defaultTemplate.id;
    } catch (e) {
      print('❌ Error creando plantilla por defecto: $e');
      throw Exception('Error al crear plantilla por defecto: $e');
    }
  }

  // Obtener campos por defecto
  static List<TemplateField> _getDefaultFields() {
    return [
      // Título del certificado
      TemplateField(
        id: 'certificate_title',
        type: 'text',
        label: 'Título del Certificado',
        value: 'CERTIFICADO',
        position: FieldPosition(x: 0, y: 50, width: 800, height: 60, alignment: 'center'),
        style: FieldStyle(
          fontSize: 32,
          fontWeight: 'bold',
          color: '#6C4DDC',
          textAlign: 'center',
          isBold: true,
        ),
        order: 1,
      ),
      // Nombre del estudiante
      TemplateField(
        id: 'student_name',
        type: 'text',
        label: 'Nombre del Estudiante',
        value: '{{studentName}}',
        position: FieldPosition(x: 0, y: 150, width: 800, height: 80, alignment: 'center'),
        style: FieldStyle(
          fontSize: 28,
          fontWeight: 'bold',
          color: '#000000',
          textAlign: 'center',
          isBold: true,
        ),
        order: 2,
      ),
      // Descripción
      TemplateField(
        id: 'certificate_description',
        type: 'text',
        label: 'Descripción',
        value: '{{description}}',
        position: FieldPosition(x: 50, y: 250, width: 700, height: 100, alignment: 'center'),
        style: FieldStyle(
          fontSize: 16,
          fontWeight: 'normal',
          color: '#000000',
          textAlign: 'center',
        ),
        order: 3,
      ),
      // Fecha de emisión
      TemplateField(
        id: 'issue_date',
        type: 'date',
        label: 'Fecha de Emisión',
        value: '{{issuedAt}}',
        position: FieldPosition(x: 500, y: 400, width: 200, height: 30, alignment: 'right'),
        style: FieldStyle(
          fontSize: 14,
          fontWeight: 'normal',
          color: '#666666',
          textAlign: 'right',
        ),
        order: 4,
      ),
      // Firma del emisor
      TemplateField(
        id: 'issuer_signature',
        type: 'signature',
        label: 'Firma del Emisor',
        value: '{{issuedByName}}',
        position: FieldPosition(x: 100, y: 450, width: 200, height: 50, alignment: 'left'),
        style: FieldStyle(
          fontSize: 14,
          fontWeight: 'normal',
          color: '#000000',
          textAlign: 'left',
        ),
        order: 5,
      ),
      // ID del certificado
      TemplateField(
        id: 'certificate_id',
        type: 'text',
        label: 'ID del Certificado',
        value: '{{id}}',
        position: FieldPosition(x: 0, y: 550, width: 800, height: 20, alignment: 'center'),
        style: FieldStyle(
          fontSize: 10,
          fontWeight: 'normal',
          color: '#999999',
          textAlign: 'center',
        ),
        order: 6,
      ),
    ];
  }

  // Exportar plantilla como JSON
  static Map<String, dynamic> exportTemplate(CertificateTemplate template) {
    return {
      'name': template.name,
      'description': template.description,
      'design': template.design.toMap(),
      'layout': template.layout.toMap(),
      'fields': template.fields.map((field) => field.toMap()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  // Importar plantilla desde JSON
  static Future<String> importTemplate(Map<String, dynamic> templateData, String name) async {
    try {
      final context = UserContextService.currentContext;
      if (context == null) {
        throw Exception('Usuario no autenticado');
      }

      final now = DateTime.now();
      final docRef = _firestore.collection(_collection).doc();

      final template = CertificateTemplate(
        id: docRef.id,
        name: name,
        description: templateData['description'] ?? 'Plantilla importada',
        institutionId: context.institutionId ?? '',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
        createdBy: context.userId,
        design: TemplateDesign.fromMap(templateData['design'] ?? {}),
        layout: TemplateLayout.fromMap(templateData['layout'] ?? {}),
        fields: (templateData['fields'] as List<dynamic>?)
            ?.map((field) => TemplateField.fromMap(field))
            .toList() ?? [],
      );

      await docRef.set(template.toMap());

      print('✅ Plantilla importada: ${template.id}');
      return template.id;
    } catch (e) {
      print('❌ Error importando plantilla: $e');
      throw Exception('Error al importar plantilla: $e');
    }
  }
}
