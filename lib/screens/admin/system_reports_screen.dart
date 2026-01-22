// lib/screens/admin/system_reports_screen.dart
// Pantalla de reportes del sistema para administradores

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/adapters/certificate_adapter.dart';
import '../../services/adapters/institution_adapter.dart';
import '../../services/user_context_service.dart';
import '../../services/alert_service.dart';
import '../../models/certificate.dart';
import '../../models/institution.dart';

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({Key? key}) : super(key: key);

  @override
  _SystemReportsScreenState createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _reports = {};
  List<Map<String, dynamic>> _topEmitters = [];
  List<Map<String, dynamic>> _topStudents = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) {
        throw Exception('Usuario debe tener institución asignada');
      }

      // Cargar todos los certificados de la institución
      final certificates = await CertificateAdapter.getCertificates(
        institutionId: userContext!.institutionId,
      );
      
      // Cargar información de la institución
      final institutions = await InstitutionAdapter.getAllInstitutions();
      Institution? institution;
      try {
        institution = institutions.firstWhere(
          (inst) => inst.id == userContext.institutionId,
        );
      } catch (e) {
        institution = null;
      }
      
      // Procesar datos para reportes
      await _processReportsData(certificates.cast<Certificate>(), institution);
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error cargando reportes: $e');
      AlertService.showError(context, 'Error', 'Error cargando reportes: $e');
    }
  }

  Future<void> _processReportsData(List<Certificate> certificates, Institution? institution) async {
    // Estadísticas generales
    int totalCertificates = certificates.length;
    int activeCertificates = certificates.where((c) => c.status == 'active').length;
    int revokedCertificates = certificates.where((c) => c.status == 'revoked').length;
    int expiredCertificates = certificates.where((c) => c.status == 'expired').length;
    
    // Contar por tipo de certificado
    Map<String, int> certificatesByType = {};
    for (var cert in certificates) {
      certificatesByType[cert.certificateType] = (certificatesByType[cert.certificateType] ?? 0) + 1;
    }
    
    // Contar por emisor
    Map<String, int> certificatesByEmitter = {};
    Map<String, String> emitterNames = {};
    
    for (var cert in certificates) {
      String emitterName = cert.issuedByName ?? 'Emisor Desconocido';
      String emitterId = emitterName; // Usar el nombre como ID único
      
      certificatesByEmitter[emitterId] = (certificatesByEmitter[emitterId] ?? 0) + 1;
      emitterNames[emitterId] = emitterName;
    }
    
    // Top emisores
    _topEmitters = certificatesByEmitter.entries
        .map((entry) => {
          'id': entry.key,
          'name': emitterNames[entry.key] ?? 'Emisor Desconocido',
          'count': entry.value,
        })
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    // Contar por estudiante
    Map<String, int> certificatesByStudent = {};
    Map<String, String> studentNames = {};
    
    for (var cert in certificates) {
      String studentId = cert.studentId;
      String studentName = cert.studentName;
      
      certificatesByStudent[studentId] = (certificatesByStudent[studentId] ?? 0) + 1;
      studentNames[studentId] = studentName;
    }
    
    // Top estudiantes
    _topStudents = certificatesByStudent.entries
        .map((entry) => {
          'id': entry.key,
          'name': studentNames[entry.key] ?? 'Estudiante Desconocido',
          'count': entry.value,
        })
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    // Calcular fechas
    DateTime? firstCertificate;
    DateTime? lastCertificate;
    
    if (certificates.isNotEmpty) {
      firstCertificate = certificates.map((c) => c.issuedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      lastCertificate = certificates.map((c) => c.issuedAt).reduce((a, b) => a.isAfter(b) ? a : b);
    }
    
    _reports = {
      'institution': institution?.name ?? 'Institución Desconocida',
      'totalCertificates': totalCertificates,
      'activeCertificates': activeCertificates,
      'revokedCertificates': revokedCertificates,
      'expiredCertificates': expiredCertificates,
      'certificatesByType': certificatesByType,
      'firstCertificate': firstCertificate,
      'lastCertificate': lastCertificate,
      'totalEmitters': certificatesByEmitter.length,
      'totalStudents': certificatesByStudent.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reportes del Sistema'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _exportToPdf,
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar a PDF',
          ),
          IconButton(
            onPressed: _loadReports,
            icon: Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildGeneralStats(),
                  SizedBox(height: 24),
                  _buildTopEmitters(),
                  SizedBox(height: 24),
                  _buildTopStudents(),
                  SizedBox(height: 24),
                  _buildCertificatesByType(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Color(0xff6C4DDC), Color(0xff6C4DDC).withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.analytics, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reportes de ${_reports['institution']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Estadísticas completas del sistema',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Estadísticas Generales',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Certificados',
                    _reports['totalCertificates'].toString(),
                    Icons.description,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Activos',
                    _reports['activeCertificates'].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Revocados',
                    _reports['revokedCertificates'].toString(),
                    Icons.block,
                    Colors.red,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Expirados',
                    _reports['expiredCertificates'].toString(),
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Emisores',
                    _reports['totalEmitters'].toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Estudiantes',
                    _reports['totalStudents'].toString(),
                    Icons.school,
                    Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmitters() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Top Emisores',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_topEmitters.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay datos de emisores disponibles',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ..._topEmitters.take(5).map((emitter) => _buildEmitterItem(emitter)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmitterItem(Map<String, dynamic> emitter) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xff6C4DDC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person,
              color: Color(0xff6C4DDC),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emitter['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xff2E2F44),
                  ),
                ),
                Text(
                  '${emitter['count']} certificados emitidos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xff6C4DDC).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${emitter['count']}',
              style: TextStyle(
                color: Color(0xff6C4DDC),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStudents() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Estudiantes con Más Certificados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_topStudents.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay datos de estudiantes disponibles',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ..._topStudents.take(5).map((student) => _buildStudentItem(student)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItem(Map<String, dynamic> student) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.school,
              color: Colors.teal,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xff2E2F44),
                  ),
                ),
                Text(
                  '${student['count']} certificados obtenidos',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${student['count']}',
              style: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificatesByType() {
    final certificatesByType = _reports['certificatesByType'] as Map<String, int>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Color(0xff6C4DDC), size: 24),
                SizedBox(width: 12),
                Text(
                  'Certificados por Tipo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (certificatesByType.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No hay datos de tipos de certificados disponibles',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              ...certificatesByType.entries.map((entry) => _buildTypeItem(entry.key, entry.value)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeItem(String type, int count) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(0xff6C4DDC),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xff2E2F44),
              ),
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xff6C4DDC),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    try {
      setState(() => _isLoading = true);
      
      // Crear documento PDF
      final pdf = pw.Document();
      final now = DateTime.now();
      final institutionName = _reports['institution'] ?? 'Institución';
      final certificatesByType = _reports['certificatesByType'] as Map<String, int>;
      
      // Página 1: Portada y Resumen Ejecutivo
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Portada
              pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'REPORTE DE INSTITUCIÓN',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      institutionName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'CertiBlock - Sistema de Certificados Académicos',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      'Generado el: ${_formatDate(now)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              
              // Resumen Ejecutivo
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Resumen Ejecutivo',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Estadísticas principales en tabla
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  _buildTableRow('Total Certificados', '${_reports['totalCertificates'] ?? 0}', true),
                  _buildTableRow('Certificados Activos', '${_reports['activeCertificates'] ?? 0}'),
                  _buildTableRow('Certificados Revocados', '${_reports['revokedCertificates'] ?? 0}'),
                  _buildTableRow('Certificados Expirados', '${_reports['expiredCertificates'] ?? 0}'),
                  _buildTableRow('Total Emisores', '${_reports['totalEmitters'] ?? 0}', true),
                  _buildTableRow('Total Estudiantes', '${_reports['totalStudents'] ?? 0}'),
                  if (_reports['firstCertificate'] != null)
                    _buildTableRow(
                      'Primer Certificado',
                      _formatDate(_reports['firstCertificate'] as DateTime),
                    ),
                  if (_reports['lastCertificate'] != null)
                    _buildTableRow(
                      'Último Certificado',
                      _formatDate(_reports['lastCertificate'] as DateTime),
                    ),
                ],
              ),
            ];
          },
        ),
      );
      
      // Página 2: Top Emisores
      if (_topEmitters.isNotEmpty)
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Top Emisores',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Encabezado
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue100),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Emisor',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Certificados',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Datos
                    ..._topEmitters.take(10).map((emitter) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            emitter['name'] ?? 'Emisor Desconocido',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${emitter['count'] ?? 0}',
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
              ];
            },
          ),
        );
      
      // Página 3: Top Estudiantes
      if (_topStudents.isNotEmpty)
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Estudiantes con Más Certificados',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Encabezado
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue100),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Estudiante',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Certificados',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Datos
                    ..._topStudents.take(10).map((student) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            student['name'] ?? 'Estudiante Desconocido',
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${student['count'] ?? 0}',
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
              ];
            },
          ),
        );
      
      // Página 4: Certificados por Tipo
      if (certificatesByType.isNotEmpty)
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 1,
                  child: pw.Text(
                    'Certificados por Tipo',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Encabezado
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue100),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Tipo de Certificado',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Cantidad',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Datos
                    ...certificatesByType.entries.map((entry) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.key,
                            style: pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            entry.value.toString(),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
              ];
            },
          ),
        );
      
      // Generar bytes del PDF
      final pdfBytes = await pdf.save();
      
      // Descargar el PDF usando el mismo método que PDFGeneratorService
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName = 'reporte_${institutionName.replaceAll(' ', '_')}_${_formatDateForFile(now)}.pdf';
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      setState(() => _isLoading = false);
      AlertService.showSuccess(
        context,
        'Éxito',
        'Reporte exportado exitosamente como PDF',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error exportando PDF: $e');
      AlertService.showError(
        context,
        'Error',
        'Error al exportar reporte: $e',
      );
    }
  }

  pw.TableRow _buildTableRow(String label, String value, [bool isHeader = false]) {
    return pw.TableRow(
      decoration: isHeader 
          ? pw.BoxDecoration(color: PdfColors.blue100)
          : null,
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isHeader ? 12 : 11,
            ),
          ),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isHeader ? 12 : 11,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateForFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }
}
