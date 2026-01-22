// lib/screens/emisor/emisor_statistics_screen.dart
// Pantalla de estadísticas para emisores

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/user_context_service.dart';
import '../../services/supabase/supabase_certificate_service.dart';
import '../../services/alert_service.dart';

class EmisorStatisticsScreen extends StatefulWidget {
  const EmisorStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<EmisorStatisticsScreen> createState() => _EmisorStatisticsScreenState();
}

class _EmisorStatisticsScreenState extends State<EmisorStatisticsScreen> {
  bool _isLoading = true;
  List<SupabaseCertificate> _certificates = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final userContext = UserContextService.currentContext;
      if (userContext == null) {
        throw Exception('Usuario no autenticado');
      }

      // Obtener todos los certificados emitidos por este emisor
      _certificates = await SupabaseCertificateService.getCertificatesByEmisor(userContext.userId);

      // Calcular estadísticas
      _stats = _calculateStats(_certificates);

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ Error cargando estadísticas: $e');
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _calculateStats(List<SupabaseCertificate> certificates) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last30Days = today.subtract(Duration(days: 30));
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    // Estadísticas por período
    int last30 = 0;
    int thisMonthCount = 0;
    int lastMonthCount = 0;
    int thisWeekCount = 0;
    int lastWeekCount = 0;

    // Por tipo
    Map<String, int> byType = {};

    // Por estado
    Map<String, int> byStatus = {
      'active': 0,
      'revoked': 0,
      'expired': 0,
    };

    // Por carrera
    Map<String, int> byCareer = {};
    Set<String> uniqueStudents = {};
    Map<String, int> certificatesPerStudent = {};

    // Tendencias por mes
    Map<String, int> byMonth = {};

    for (var cert in certificates) {
      final issuedDate = cert.issuedAt;

      // Últimos 30 días
      if (issuedDate.isAfter(last30Days)) {
        last30++;
      }

      // Este mes
      if (issuedDate.year == thisMonth.year && issuedDate.month == thisMonth.month) {
        thisMonthCount++;
      }

      // Mes pasado
      if (issuedDate.year == lastMonth.year && issuedDate.month == lastMonth.month) {
        lastMonthCount++;
      }

      // Esta semana
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      if (issuedDate.isAfter(weekStart)) {
        thisWeekCount++;
      }

      // Semana pasada
      final lastWeekStart = weekStart.subtract(Duration(days: 7));
      final lastWeekEnd = weekStart;
      if (issuedDate.isAfter(lastWeekStart) && issuedDate.isBefore(lastWeekEnd)) {
        lastWeekCount++;
      }

      // Por tipo
      byType[cert.certificateType] = (byType[cert.certificateType] ?? 0) + 1;

      // Por estado
      byStatus[cert.status] = (byStatus[cert.status] ?? 0) + 1;

      // Por carrera
      byCareer[cert.programName] = (byCareer[cert.programName] ?? 0) + 1;

      // Estudiantes únicos
      uniqueStudents.add(cert.studentId);
      certificatesPerStudent[cert.studentId] = (certificatesPerStudent[cert.studentId] ?? 0) + 1;

      // Por mes (formato YYYY-MM)
      final monthKey = '${issuedDate.year}-${issuedDate.month.toString().padLeft(2, '0')}';
      byMonth[monthKey] = (byMonth[monthKey] ?? 0) + 1;
    }

    // Ordenar meses
    final sortedMonths = byMonth.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Encontrar estudiante con más certificados
    final topStudentEntry = certificatesPerStudent.entries.isEmpty
        ? null
        : certificatesPerStudent.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );

    return {
      'total': certificates.length,
      'last30Days': last30,
      'thisMonth': thisMonthCount,
      'lastMonth': lastMonthCount,
      'thisWeek': thisWeekCount,
      'lastWeek': lastWeekCount,
      'byType': byType,
      'byStatus': byStatus,
      'byCareer': byCareer,
      'uniqueStudents': uniqueStudents.length,
      'avgCertificatesPerStudent': certificates.length / (uniqueStudents.isEmpty ? 1 : uniqueStudents.length),
      'topStudentId': topStudentEntry?.key,
      'topStudentCertificates': topStudentEntry?.value ?? 0,
      'byMonth': byMonth,
      'sortedMonths': sortedMonths,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estadísticas'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exportToPdf,
            tooltip: 'Exportar a PDF',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStatistics,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _certificates.isEmpty
              ? _buildEmptyState()
              : _buildStatistics(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'No hay certificados emitidos aún',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Las estadísticas aparecerán aquí cuando emitas certificados',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen general
          _buildGeneralSummaryCard(),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

          // Estadísticas por período
          _buildPeriodStatsCard(),
          SizedBox(height: 16),

          // Por tipo de certificado
          _buildByTypeCard(),
          SizedBox(height: 16),

          // Por estado
          _buildByStatusCard(),
          SizedBox(height: 16),

          // Por carrera
          _buildByCareerCard(),
          SizedBox(height: 16),

          // Estudiantes
          _buildStudentsStatsCard(),
          SizedBox(height: 16),

          // Actividad reciente
          _buildRecentActivityCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSummaryCard() {
    final total = _stats['total'] ?? 0;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.analytics, color: Colors.white, size: 64),
          SizedBox(height: 16),
          Text(
            'Total de Certificados Emitidos',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '$total',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodStatsCard() {
    final last30 = _stats['last30Days'] ?? 0;
    final thisMonth = _stats['thisMonth'] ?? 0;
    final lastMonth = _stats['lastMonth'] ?? 0;
    final thisWeek = _stats['thisWeek'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas por Período',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(Icons.calendar_today, 'Últimos 30 días', last30.toString(), Color(0xff2196F3)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(Icons.today, 'Este mes', thisMonth.toString(), Color(0xff4CAF50)),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatBox(Icons.calendar_month, 'Mes pasado', lastMonth.toString(), Color(0xffFF9800)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatBox(Icons.weekend, 'Esta semana', thisWeek.toString(), Color(0xff9C27B0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildByTypeCard() {
    final byType = _stats['byType'] as Map<String, int>? ?? {};
    
    if (byType.isEmpty) return SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificados por Tipo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            ...byType.entries.map((entry) => _buildStatRow(
              _getTypeIcon(entry.key),
              _getTypeName(entry.key),
              entry.value.toString(),
              Colors.grey[300]!,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildByStatusCard() {
    final byStatus = _stats['byStatus'] as Map<String, int>? ?? {};

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado de Certificados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            if (byStatus['active'] != null && byStatus['active']! > 0)
              _buildStatRow(
                Icons.check_circle,
                'Activos',
                byStatus['active'].toString(),
                Colors.green[300]!,
              ),
            if (byStatus['revoked'] != null && byStatus['revoked']! > 0)
              _buildStatRow(
                Icons.cancel,
                'Revocados',
                byStatus['revoked'].toString(),
                Colors.red[300]!,
              ),
            if (byStatus['expired'] != null && byStatus['expired']! > 0)
              _buildStatRow(
                Icons.timer_off,
                'Expirados',
                byStatus['expired'].toString(),
                Colors.orange[300]!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildByCareerCard() {
    final byCareer = _stats['byCareer'] as Map<String, int>? ?? {};
    
    if (byCareer.isEmpty) return SizedBox();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Certificados por Carrera',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            ...byCareer.entries.take(5).map((entry) => _buildStatRow(
              Icons.school,
              entry.key,
              entry.value.toString(),
              Colors.grey[300]!,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsStatsCard() {
    final uniqueStudents = _stats['uniqueStudents'] ?? 0;
    final avgCertificates = _stats['avgCertificatesPerStudent'] ?? 0.0;
    final topStudentCertificates = _stats['topStudentCertificates'] ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estudiantes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            _buildStatRow(
              Icons.people,
              'Estudiantes únicos atendidos',
              uniqueStudents.toString(),
              Colors.grey[300]!,
            ),
            SizedBox(height: 12),
            _buildStatRow(
              Icons.trending_up,
              'Promedio de certificados por estudiante',
              avgCertificates.toStringAsFixed(1),
              Colors.grey[300]!,
            ),
            if (topStudentCertificates > 0) ...[
              SizedBox(height: 12),
              _buildStatRow(
                Icons.emoji_events,
                'Máximo certificados a un estudiante',
                topStudentCertificates.toString(),
                Colors.grey[300]!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentCertificates = _certificates.take(10).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad Reciente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 16),
            ...recentCertificates.map((cert) => _buildRecentCertificateRow(cert)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCertificateRow(SupabaseCertificate cert) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xff6C4DDC).withOpacity(0.1),
            child: Icon(
              _getTypeIcon(cert.certificateType),
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
                  cert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${cert.studentName} - ${_formatDate(cert.issuedAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff2E2F44),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'graduation':
        return Icons.school;
      case 'constancy':
        return Icons.description;
      case 'achievement':
        return Icons.emoji_events;
      case 'participation':
        return Icons.group;
      default:
        return Icons.description;
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'graduation':
        return 'Graduación';
      case 'constancy':
        return 'Constancia';
      case 'achievement':
        return 'Logro';
      case 'participation':
        return 'Participación';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference < 7) {
      return 'Hace $difference días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDateFull(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateForFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _exportToPdf() async {
    try {
      setState(() => _isLoading = true);
      
      final userContext = UserContextService.currentContext;
      final emisorName = userContext?.userName ?? 'Emisor';
      final institutionName = userContext?.institutionName ?? 'Institución';
      
      // Crear documento PDF
      final pdf = pw.Document();
      final now = DateTime.now();
      final byType = _stats['byType'] as Map<String, int>? ?? {};
      final byStatus = _stats['byStatus'] as Map<String, int>? ?? {};
      final byCareer = _stats['byCareer'] as Map<String, int>? ?? {};
      final sortedMonths = _stats['sortedMonths'] as List<MapEntry<String, int>>? ?? [];
      
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
                      'REPORTE DE EMISOR',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      emisorName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue700,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      institutionName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.grey700,
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
                      'Generado el: ${_formatDateFull(now)}',
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
                  _buildTableRow('Total Certificados Emitidos', '${_stats['total'] ?? 0}', true),
                  _buildTableRow('Últimos 30 días', '${_stats['last30Days'] ?? 0}'),
                  _buildTableRow('Este mes', '${_stats['thisMonth'] ?? 0}'),
                  _buildTableRow('Mes pasado', '${_stats['lastMonth'] ?? 0}'),
                  _buildTableRow('Esta semana', '${_stats['thisWeek'] ?? 0}'),
                  _buildTableRow('Estudiantes únicos atendidos', '${_stats['uniqueStudents'] ?? 0}', true),
                  _buildTableRow(
                    'Promedio certificados/estudiante',
                    '${(_stats['avgCertificatesPerStudent'] ?? 0.0).toStringAsFixed(1)}',
                  ),
                  if ((_stats['topStudentCertificates'] ?? 0) > 0)
                    _buildTableRow(
                      'Máximo certificados a un estudiante',
                      '${_stats['topStudentCertificates'] ?? 0}',
                    ),
                ],
              ),
            ];
          },
        ),
      );
      
      // Página 2: Por Tipo y Estado
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Certificados por Tipo
              if (byType.isNotEmpty) ...[
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
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.blue100),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Tipo',
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
                    ...byType.entries.map((entry) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            _getTypeName(entry.key),
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
                pw.SizedBox(height: 30),
              ],
              
              // Estado de Certificados
              pw.Header(
                level: 1,
                child: pw.Text(
                  'Estado de Certificados',
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
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Estado',
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
                  if (byStatus['active'] != null && byStatus['active']! > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Activos', style: pw.TextStyle(fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            byStatus['active'].toString(),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  if (byStatus['revoked'] != null && byStatus['revoked']! > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Revocados', style: pw.TextStyle(fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            byStatus['revoked'].toString(),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  if (byStatus['expired'] != null && byStatus['expired']! > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text('Expirados', style: pw.TextStyle(fontSize: 11)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8),
                          child: pw.Text(
                            byStatus['expired'].toString(),
                            style: pw.TextStyle(fontSize: 11),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ];
          },
        ),
      );
      
      // Página 3: Por Carrera y Actividad Mensual
      if (byCareer.isNotEmpty || sortedMonths.isNotEmpty)
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(40),
            build: (pw.Context context) {
              return [
                // Certificados por Carrera
                if (byCareer.isNotEmpty) ...[
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      'Certificados por Carrera',
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
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.blue100),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Carrera',
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
                      ...byCareer.entries.take(10).map((entry) => pw.TableRow(
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
                  pw.SizedBox(height: 30),
                ],
                
                // Actividad Mensual
                if (sortedMonths.isNotEmpty) ...[
                  pw.Header(
                    level: 1,
                    child: pw.Text(
                      'Actividad Mensual',
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
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.blue100),
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Mes',
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
                      ...sortedMonths.map((entry) {
                        final monthParts = entry.key.split('-');
                        final monthName = _getMonthName(int.parse(monthParts[1]));
                        final year = monthParts[0];
                        return pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8),
                              child: pw.Text(
                                '$monthName $year',
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
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ];
            },
          ),
        );
      
      // Generar bytes del PDF
      final pdfBytes = await pdf.save();
      
      // Descargar el PDF
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final fileName = 'reporte_emisor_${emisorName.replaceAll(' ', '_')}_${_formatDateForFile(now)}.pdf';
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

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }
}

