// lib/screens/certificates/certificate_detail_screen.dart
// Pantalla de detalle del certificado

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../../services/adapters/certificate_adapter.dart';
import '../../models/certificate.dart';
import '../../services/blockchain/blockchain_config.dart';
import '../../services/alert_service.dart';

class CertificateDetailScreen extends StatelessWidget {
  final Certificate certificate;
  final bool isAdminView; // Para distinguir vista de admin vs estudiante

  const CertificateDetailScreen({
    Key? key,
    required this.certificate,
    this.isAdminView = false, // Por defecto es vista de estudiante
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar personalizado con gradiente
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () => _shareCertificate(context),
          ),
        ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Detalle del Certificado',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xff6C4DDC),
                      Color(0xff8B5FBF),
                      Color(0xffA052D6),
                    ],
                  ),
                ),
                child: Center(
        child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
          children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      SizedBox(height: 8),
                      Text(
                        certificate.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      _buildStatusChip(certificate.status),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Contenido principal
          SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Información principal del certificado
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.05), // Color sólido sin degradado
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff6C4DDC).withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Color(0xff6C4DDC).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xff6C4DDC).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.description,
                                color: Color(0xff6C4DDC),
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Información del Certificado',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff2E2F44),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          certificate.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          certificate.description.isNotEmpty 
                              ? certificate.description 
                              : 'Certificado emitido por ${certificate.institutionName}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xff6C4DDC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            certificate.status.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            
                  SizedBox(height: 24),
            
                  // Grid de información principal
                  _buildInfoGrid(context),
                  
                  SizedBox(height: 24),
            
            // Sección de código QR
            _buildQRCodeSection(context),
            
            SizedBox(height: 24),
            
            // Historial de validaciones
            if (certificate.validationHistory?.isNotEmpty == true)
              _buildValidationHistory(),
            
            SizedBox(height: 32),
            
            // Botones de acción
            if (!isAdminView) 
              _buildActionButtons(context)
            else
              _buildRevokeButton(context),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Column(
      children: [
        // Primera fila: Información del estudiante e institucional
        Row(
          children: [
            Expanded(
              child: _buildModernInfoCard(
              'Información del Estudiante',
              Icons.person,
                Color(0xff4CAF50),
                [
                  _buildModernInfoRow('Nombre', certificate.studentName, Icons.badge, context),
                  _buildModernInfoRow('Email', certificate.studentEmail ?? 'No disponible', Icons.email, context),
                  _buildModernInfoRow('ID Institución', certificate.studentIdInInstitution ?? 'No disponible', Icons.credit_card, context),
                  _buildModernInfoRow('Programa', certificate.programName ?? 'No disponible', Icons.school, context),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernInfoCard(
              'Información Institucional',
              Icons.school,
                Color(0xff2196F3),
                [
                  _buildModernInfoRow('Institución', certificate.institutionName, Icons.business, context),
                  _buildModernInfoRow('Código', certificate.institutionCode, Icons.tag, context),
                  _buildModernInfoRow('Tipo', _getCertificateTypeLabel(certificate.certificateType), Icons.workspace_premium, context),
                ],
              ),
            ),
          ],
            ),
            
            SizedBox(height: 16),
            
        // Segunda fila: Información de emisión y validación
        Row(
          children: [
            Expanded(
              child: _buildModernInfoCard(
              'Información de Emisión',
              Icons.workspace_premium,
                Color(0xffFF9800),
                [
                  _buildModernInfoRow('Emitido por', certificate.issuedByName ?? 'No disponible', Icons.person_pin, context),
                  _buildModernInfoRow('Rol', _getRoleLabel(certificate.issuedByRole ?? 'No disponible'), Icons.admin_panel_settings, context),
                  _buildModernInfoRow('Fecha Emisión', _formatDate(certificate.issuedAt), Icons.calendar_today, context),
                if (certificate.expiresAt != null)
                    _buildModernInfoRow('Expiración', _formatDate(certificate.expiresAt!), Icons.schedule, context),
                if (certificate.revokedAt != null)
                    _buildModernInfoRow('Revocación', _formatDate(certificate.revokedAt!), Icons.block, context),
                if (certificate.revokedReason != null)
                    _buildModernInfoRow('Motivo', certificate.revokedReason!, Icons.info, context),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildModernInfoCard(
              'Validación',
              Icons.qr_code,
                Color(0xff9C27B0),
                [
                  _buildModernInfoRow('Código QR', certificate.qrCode, Icons.qr_code, context, isCode: true),
                if (certificate.blockchainHash != null && certificate.blockchainHash!.isNotEmpty) ...[
                    _buildBlockchainHashRow(certificate.blockchainHash!, context),
                    // Solo mostrar el enlace al contrato para admin/emisor
                    if (isAdminView)
                      _buildBlockchainVerificationButton(context),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernInfoCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      height: 300, // Altura fija para todos los cards
      decoration: BoxDecoration(
        color: color.withOpacity(0.05), // Color sólido con opacidad, sin degradado
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                  title,
                  style: TextStyle(
                      fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded( // Usar Expanded para evitar overflow
              child: SingleChildScrollView( // Agregar scroll si el contenido es muy largo
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon, BuildContext context, {bool isCode = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
              style: TextStyle(
                    fontSize: 12,
                fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
              ),
            ),
                SizedBox(height: 2),
                isCode
                ? GestureDetector(
                    onTap: () => _copyToClipboard(value, context),
                    child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                                  value.length > 20 ? '${value.substring(0, 20)}...' : value,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Colors.grey[700],
                              ),
                            ),
                          ),
                              Icon(Icons.copy, size: 12, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  )
                : Text(
                    value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff2E2F44),
                        ),
                      ),
              ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainHashRow(String blockchainHash, BuildContext context) {
    // Obtener el hash de la transacción desde data (no el hash del certificado)
    String? transactionHash = certificate.data['blockchain_transaction_hash'] as String?;
    
    // Si no hay hash de transacción, usar el hash del certificado como fallback
    // pero esto no funcionará en Polygonscan ya que es un hash SHA-256, no un hash de transacción
    if (transactionHash == null || transactionHash.isEmpty) {
      transactionHash = null; // No mostrar enlace si no hay hash de transacción
    } else {
      // Limpiar el hash de transacción (eliminar espacios, saltos de línea, etc.)
      transactionHash = transactionHash.trim().replaceAll(RegExp(r'\s+'), '');
      
      // Asegurar que tenga prefijo 0x
      if (!transactionHash.startsWith('0x')) {
        transactionHash = '0x$transactionHash';
      }
    }
    
    // Construir URL del explorador solo si hay hash de transacción
    final explorerUrl = BlockchainConfig.explorerUrl;
    final transactionUrl = transactionHash != null ? '$explorerUrl/tx/$transactionHash' : null;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.link,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hash Blockchain',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                GestureDetector(
                  onTap: transactionUrl != null ? () async {
                    try {
                      final Uri url = Uri.parse(transactionUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo abrir el explorador de blockchain')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al abrir el explorador: $e')),
                      );
                    }
                  } : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            blockchainHash.length > 20 ? '${blockchainHash.substring(0, 20)}...' : blockchainHash,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xff6C4DDC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 12, color: Color(0xff6C4DDC)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockchainVerificationButton(BuildContext context) {
    // Obtener la dirección del contrato inteligente
    final contractAddress = BlockchainConfig.contractAddress;
    
    // Si no hay dirección del contrato, no mostrar el enlace
    if (contractAddress.isEmpty || contractAddress == '0x0000000000000000000000000000000000000000') {
      return SizedBox.shrink();
    }
    
    // Construir URL del explorador para el contrato (no la transacción)
    final explorerUrl = BlockchainConfig.explorerUrl;
    final contractUrl = '$explorerUrl/address/$contractAddress';
    
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.link,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verificar en Blockchain',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                GestureDetector(
                  onTap: () async {
                    try {
                      final Uri url = Uri.parse(contractUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo abrir el explorador de blockchain')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al abrir el explorador: $e')),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xff6C4DDC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ver Contrato en Polygonscan',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xff6C4DDC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 12, color: Color(0xff6C4DDC)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Activo';
        break;
      case 'revoked':
        color = Colors.red;
        label = 'Revocado';
        break;
      case 'expired':
        color = Colors.orange;
        label = 'Expirado';
        break;
      default:
        color = Colors.grey;
        label = 'Desconocido';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildValidationHistory() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xff6C4DDC).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Color(0xff6C4DDC).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xff6C4DDC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    color: Color(0xff6C4DDC),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Historial de Validaciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (certificate.validationHistory != null)
              ...certificate.validationHistory!.asMap().entries.map((entry) {
              final index = entry.key;
              final validation = entry.value;
              final isValid = validation['isValid'] == true;
              
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isValid 
                        ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                        : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isValid 
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isValid ? Colors.green : Colors.red).withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isValid 
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isValid ? Icons.check_circle : Icons.cancel,
                        color: isValid ? Colors.green[700] : Colors.red[700],
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            validation['message'] ?? 'Validación',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isValid ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                          if (validation['validatedAt'] != null) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                            Text(
                              _formatDate(DateTime.parse(validation['validatedAt'])),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Número de validación
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isValid ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isValid ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xff6C4DDC).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Color(0xff6C4DDC).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Botones principales
            Row(
              children: [
                Expanded(
                  child: _buildModernButton(
                    'Ver Certificado',
                    Icons.visibility,
                    Color(0xff6C4DDC),
                    () => _viewCertificate(context),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildModernButton(
                    'Descargar PDF',
                    Icons.download,
                    Colors.green,
                    () => _downloadCertificate(context),
                  ),
                ),
              ],
            ),
            
            // Botón de actualización si es necesario
            if (certificate.institutionName.isEmpty || certificate.institutionCode.isEmpty) ...[
          SizedBox(height: 12),
              _buildModernButton(
                'Actualizar Información de Institución',
                Icons.refresh,
                Colors.orange,
                () => _updateInstitutionInfo(context),
                isFullWidth: true,
              ),
            ],
            
            SizedBox(height: 16),
            
            // Botones secundarios
        Row(
          children: [
            Expanded(
                  child: _buildModernOutlinedButton(
                    'Copiar QR',
                    Icons.qr_code,
                    Color(0xff6C4DDC),
                    () => _copyQRCode(context),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
                  child: _buildModernOutlinedButton(
                    'Compartir',
                    Icons.share,
                    Color(0xff6C4DDC),
                    () => _shareCertificate(context),
              ),
            ),
          ],
        ),
      ],
        ),
      ),
    );
  }

  Widget _buildModernButton(String text, IconData icon, Color color, VoidCallback onPressed, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: color.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildModernOutlinedButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 2),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildRevokeButton(BuildContext context) {
    // Solo mostrar si el certificado no está ya revocado
    if (certificate.status.toLowerCase() == 'revoked') {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.block, color: Colors.red[700], size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Certificado Revocado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red[900],
                    ),
                  ),
                  if (certificate.revokedReason != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Motivo: ${certificate.revokedReason}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.red.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Revocar Certificado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.red[900],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Esta acción no se puede deshacer. El certificado quedará marcado como revocado.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRevokeDialog(context),
                icon: Icon(Icons.block, size: 20),
                label: Text(
                  'Revocar Certificado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Revocar Certificado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[900],
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Estás seguro de que deseas revocar este certificado?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Esta acción marcará el certificado como revocado y notificará al estudiante. Esta acción no se puede deshacer.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Motivo de revocación *',
                      hintText: 'Ej: Error en los datos, fraude detectado, etc.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.description),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Debes ingresar un motivo para revocar el certificado';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();
                  await _revokeCertificate(context, reasonController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: Text('Revocar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _revokeCertificate(BuildContext context, String reason) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Revocando certificado...'),
            ],
          ),
        ),
      );

      final success = await CertificateAdapter.revokeCertificate(
        certificate.id,
        reason,
      );

      // Cerrar diálogo de carga
      Navigator.of(context).pop();

      if (success) {
        AlertService.showSuccess(
          context,
          'Certificado Revocado',
          'El certificado ha sido revocado exitosamente. El estudiante ha sido notificado por email.',
        );
        
        // Regresar a la pantalla anterior con resultado para recargar la lista
        Navigator.of(context).pop(true);
      } else {
        AlertService.showError(
          context,
          'Error',
          'No se pudo revocar el certificado. Por favor, intenta nuevamente.',
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      AlertService.showError(
        context,
        'Error',
        'Error al revocar el certificado: $e',
      );
    }
  }

  String _getCertificateTypeLabel(String type) {
    switch (type) {
      case 'graduation':
        return 'Certificado de Graduación';
      case 'constancy':
        return 'Constancia de Estudios';
      case 'achievement':
        return 'Certificado de Logro';
      case 'participation':
        return 'Certificado de Participación';
      default:
        return type;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Administrador';
      case 'admin_institution':
        return 'Administrador de Institución';
      case 'emisor':
        return 'Emisor';
      default:
        return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(String text, BuildContext? context) {
    Clipboard.setData(ClipboardData(text: text));
    if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copiado al portapapeles'),
        duration: Duration(seconds: 2),
      ),
    );
    } else {
      print('📋 Texto copiado al portapapeles');
    }
  }

  void _showInfoSnackBar(String message) {
    // Este método se puede usar cuando no hay contexto disponible
    print('ℹ️ $message');
  }

  void _showErrorSnackBar(String message, BuildContext context) {
    print('❌ $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message, BuildContext context) {
    print('✅ $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 3),
      ),
    );
  }


  void _copyQRCode(BuildContext context) {
    _copyToClipboard(certificate.qrCode, context);
  }

  // Mostrar vista previa de la plantilla en un modal
  void _showTemplatePreview(BuildContext context, Map<String, dynamic> templateData, Certificate certificate) {
    final design = templateData['design'] as Map<String, dynamic>;
    final layout = templateData['layout'] as Map<String, dynamic>;
    final studentName = certificate.data['studentName'] ?? 'Juan Pérez';
    final program = certificate.data['program'] ?? 'Programa de Estudios';
    final faculty = certificate.data['faculty'] ?? 'Facultad';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 800,  // Más ancho para proporción de certificado
            height: 600, // Menos alto para proporción horizontal
            decoration: BoxDecoration(
              color: _parseColor(design['backgroundColor']),
              borderRadius: BorderRadius.circular(design['borderRadius']?.toDouble() ?? 8),
              border: Border.all(
                color: _parseColor(design['borderColor']),
                width: design['borderWidth']?.toDouble() ?? 2,
              ),
            ),
            child: Stack(
              children: [
                // Imagen de fondo del certificado
                if (design['certificateBackgroundUrl']?.isNotEmpty == true)
                  _buildBackgroundImage(design['certificateBackgroundUrl']),
                
                // Patrón de fondo
                if (layout['backgroundPattern'] != 'none')
                  _buildBackgroundPattern(design, layout),
                
                // Logo de la institución
                _buildInstitutionLogo(design, layout),
                
                // Contenido principal
                Column(
                  children: [
                    // Header - Solo si está habilitado en el layout
                    if (layout['showHeader'] != false)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: design['titleFontSize']?.toDouble() ?? 25,
                          horizontal: 30,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _parseColor(design['primaryColor']),
                              _parseColor(design['secondaryColor']),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(design['borderRadius']?.toDouble() ?? 8),
                            topRight: Radius.circular(design['borderRadius']?.toDouble() ?? 8),
                          ),
                        ),
                        child: Text(
                          'CERTIFICADO',
                          style: _getTextStyle(
                            design['titleFontFamily'] ?? 'Arial',
                            design['titleFontSize']?.toDouble() ?? 24,
                            _parseColor(design['headerTextColor']),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Línea decorativa
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _parseColor(design['primaryColor']),
                            _parseColor(design['secondaryColor']),
                          ],
                        ),
                      ),
                    ),
                    
                    // Contenido
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Subtítulo
                            Text(
                              'Se certifica que',
                              style: _getTextStyle(
                                design['subtitleFontFamily'] ?? 'Arial',
                                design['subtitleFontSize']?.toDouble() ?? 16,
                                _parseColor(design['textColor']),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Nombre del estudiante
                            Text(
                              studentName,
                              style: _getTextStyle(
                                design['titleFontFamily'] ?? 'Arial',
                                (design['subtitleFontSize']?.toDouble() ?? 16) + 8,
                                _parseColor(design['textColor']),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Descripción
                            Text(
                              'Ha completado exitosamente el programa de estudios',
                              style: _getTextStyle(
                                design['bodyFontFamily'] ?? 'Arial',
                                design['bodyFontSize']?.toDouble() ?? 14,
                                _parseColor(design['textColor']),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 10),
                            
                            Text(
                              program,
                              style: _getTextStyle(
                                design['bodyFontFamily'] ?? 'Arial',
                                design['bodyFontSize']?.toDouble() ?? 14,
                                _parseColor(design['textColor']),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            Text(
                              'en la $faculty',
                              style: _getTextStyle(
                                design['bodyFontFamily'] ?? 'Arial',
                                design['bodyFontSize']?.toDouble() ?? 14,
                                _parseColor(design['textColor']),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 40),
                            
                            // Firmas
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      design['issuerName'] ?? 'Institución',
                                      style: _getTextStyle(
                                        design['smallFontFamily'] ?? 'Arial',
                                        design['smallFontSize']?.toDouble() ?? 12,
                                        _parseColor(design['textColor']),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      design['issuerTitleLabel'] ?? 'Título',
                                      style: _getTextStyle(
                                        design['smallFontFamily'] ?? 'Arial',
                                        design['smallFontSize']?.toDouble() ?? 12,
                                        _parseColor(design['textColor']),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      design['dateLabel'] ?? 'Fecha',
                                      style: _getTextStyle(
                                        design['smallFontFamily'] ?? 'Arial',
                                        design['smallFontSize']?.toDouble() ?? 12,
                                        _parseColor(design['textColor']),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Botón cerrar
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Función auxiliar para parsear colores
  Color _parseColor(dynamic colorValue) {
    if (colorValue == null) return Colors.black;
    if (colorValue is String) {
      // Si es un string, intentar parsearlo como color
      if (colorValue.startsWith('#')) {
        return Color(int.parse(colorValue.substring(1), radix: 16) + 0xFF000000);
      }
      // Si es un nombre de color, usar colores predefinidos
      switch (colorValue.toLowerCase()) {
        case 'red': return Colors.red;
        case 'blue': return Colors.blue;
        case 'green': return Colors.green;
        case 'black': return Colors.black;
        case 'white': return Colors.white;
        default: return Colors.black;
      }
    }
    return Colors.black;
  }

  // Función auxiliar para crear estilos de texto
  TextStyle _getTextStyle(String fontFamily, double fontSize, Color color, {FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
    );
  }

  // Construir imagen de fondo
  Widget _buildBackgroundImage(String? backgroundUrl) {
    if (backgroundUrl == null || backgroundUrl.isEmpty) return SizedBox.shrink();
    
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: backgroundUrl.startsWith('data:')
                ? MemoryImage(base64Decode(backgroundUrl.split(',')[1]))
                : NetworkImage(backgroundUrl) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // Construir patrón de fondo
  Widget _buildBackgroundPattern(Map<String, dynamic> design, Map<String, dynamic> layout) {
    final pattern = layout['backgroundPattern'] ?? 'none';
    if (pattern == 'none') return SizedBox.shrink();
    
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPatternPainter(
          pattern: pattern,
          color: _parseColor(design['primaryColor']).withOpacity(0.1),
        ),
      ),
    );
  }

  // Construir logo de la institución
  Widget _buildInstitutionLogo(Map<String, dynamic> design, Map<String, dynamic> layout) {
    final logoUrl = design['institutionLogoUrl'];
    if (logoUrl == null || logoUrl.isEmpty) return SizedBox.shrink();
    
    final opacity = design['logoOpacity']?.toDouble() ?? 1.0;
    
    Widget logoWidget = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: logoUrl.startsWith('data:')
              ? MemoryImage(base64Decode(logoUrl.split(',')[1]))
              : NetworkImage(logoUrl) as ImageProvider,
          fit: BoxFit.contain,
        ),
      ),
    );
    
    if (opacity < 1.0) {
      logoWidget = Opacity(opacity: opacity, child: logoWidget);
    }
    
    return Positioned(
      top: 20,
      right: 20,
      child: logoWidget,
    );
  }

  void _viewCertificate(BuildContext context) async {
    try {
      print('🔄 Abriendo certificado...');
      print('📊 Estructura de datos del certificado: ${certificate.data.keys.toList()}');
      
      // Verificar si hay PDF del certificado en data.pdfData
      if (certificate.data['pdfData'] != null) {
        final pdfDataValue = certificate.data['pdfData'];
        print('📄 Tipo de pdfData: ${pdfDataValue.runtimeType}');
        
        if (pdfDataValue is String) {
          print('📄 PDF encontrado en data.pdfData (String), abriendo...');
          _openPdf(pdfDataValue, context);
          return;
        } else if (pdfDataValue is Map<String, dynamic>) {
          print('📄 Claves de pdfData: ${pdfDataValue.keys.toList()}');
          // Si es un mapa, buscar el campo 'data' o 'content'
          final pdfString = pdfDataValue['data'] ?? 
                           pdfDataValue['content'] ?? 
                           pdfDataValue['base64'] ??
                           pdfDataValue['fileData'] ??
                           pdfDataValue['certificateData'];
          if (pdfString is String && pdfString.isNotEmpty) {
            print('📄 PDF encontrado en data.pdfData (Map), abriendo...');
            _openPdf(pdfString, context);
            return;
          } else {
            print('❌ No se encontró PDF en pdfData con los campos: data, content, base64, fileData, certificateData');
            // Mostrar todos los valores para debugging
            pdfDataValue.forEach((key, value) {
              if (value is String) {
                print('📄 $key: ${value.length > 100 ? value.substring(0, 100) + '...' : value}');
              } else {
                print('📄 $key: ${value.runtimeType}');
              }
            });
          }
        }
      }
      
      // Verificar si hay PDF en data.customCertificateData
      if (certificate.data['customCertificateData'] != null) {
        final customData = certificate.data['customCertificateData'];
        print('📄 Tipo de customCertificateData: ${customData.runtimeType}');
        
        if (customData is String) {
          print('📄 PDF encontrado en data.customCertificateData (String), abriendo...');
          _openPdf(customData, context);
          return;
        } else if (customData is Map<String, dynamic>) {
          print('📄 Claves de customCertificateData: ${customData.keys.toList()}');
          
          // Buscar en múltiples campos posibles
          final pdfString = customData['data'] ?? 
                           customData['content'] ?? 
                           customData['base64'] ?? 
                           customData['pdfData'] ??
                           customData['fileData'] ??
                           customData['certificateData'];
          
          if (pdfString is String && pdfString.isNotEmpty) {
            print('📄 PDF encontrado en data.customCertificateData (Map), abriendo...');
            _openPdf(pdfString, context);
            return;
          } else {
            print('❌ No se encontró PDF en customCertificateData con los campos: data, content, base64, pdfData, fileData, certificateData');
            // Mostrar todos los valores para debugging
            customData.forEach((key, value) {
              if (value is String) {
                print('📄 $key: ${value.length > 100 ? value.substring(0, 100) + '...' : value}');
              } else {
                print('📄 $key: ${value.runtimeType}');
              }
            });
          }
        }
      }
      
      // Verificar si hay plantilla generada como PDF
      if (certificate.data['templateData'] != null) {
        final templateData = certificate.data['templateData'] as Map<String, dynamic>;
        print('📄 Tipo de templateData: ${templateData.runtimeType}');
        print('📄 Claves de templateData: ${templateData.keys.toList()}');
        
        final templatePdfData = templateData['pdfData'];
        if (templatePdfData != null) {
          print('📄 Tipo de templatePdfData: ${templatePdfData.runtimeType}');
          
          if (templatePdfData is String && templatePdfData.isNotEmpty) {
            print('📄 PDF de plantilla encontrado (String), abriendo...');
            _openPdf(templatePdfData, context);
            return;
          } else if (templatePdfData is Map<String, dynamic>) {
            final pdfString = templatePdfData['data'] ?? templatePdfData['content'] ?? templatePdfData['base64'];
            if (pdfString is String && pdfString.isNotEmpty) {
              print('📄 PDF de plantilla encontrado (Map), abriendo...');
              _openPdf(pdfString, context);
              return;
            }
          }
        }
        
        // Si no hay PDF generado, mostrar vista previa de la plantilla
        print('ℹ️ Plantilla encontrada, mostrando vista previa...');
        _showTemplatePreview(context, templateData, certificate);
        return;
      }
      
      // Si no hay certificado disponible, mostrar mensaje
      print('❌ No se encontró PDF en ninguna ubicación');
      _showInfoSnackBar('No hay certificado disponible para visualizar');
      
    } catch (e) {
      print('❌ Error al abrir certificado: $e');
      _showErrorSnackBar('Error al abrir certificado: $e', context);
    }
  }

  void _openPdf(String pdfContent, BuildContext context) async {
    // Determinar si es base64 puro o data URL
    final String dataUrl = pdfContent.startsWith('data:') 
        ? pdfContent 
        : 'data:application/pdf;base64,$pdfContent';
    
    try {
      print('🔄 Abriendo PDF del certificado automáticamente...');
      print('📄 URL generada: ${dataUrl.substring(0, 100)}...');
      
      // Usar JavaScript para crear blob URL y abrir en nueva pestaña
      await _openPdfWithBlob(dataUrl);
      
    } catch (e) {
      print('❌ Error al abrir PDF: $e');
      // Fallback: copiar al portapapeles y mostrar instrucciones
      _openPdfFallback(dataUrl, context);
    }
  }

  Future<void> _openPdfWithBlob(String dataUrl) async {
    try {
      print('🔄 Creando blob URL con JavaScript...');
      
      // Extraer el base64 del data URL
      final String base64Data = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      print('📊 Base64 extraído: ${base64Data.substring(0, 50)}...');
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Data);
      print('📊 Bytes decodificados: ${bytes.length} bytes');
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      print('📄 Blob URL creada: $blobUrl');
      
      // Abrir en nueva pestaña
      html.window.open(blobUrl, '_blank');
      
      _showInfoSnackBar('Certificado abierto en nueva pestaña');
      print('✅ Certificado abierto exitosamente con blob URL');
      
      // Limpiar la URL del blob después de un tiempo
      Future.delayed(Duration(seconds: 30), () {
        html.Url.revokeObjectUrl(blobUrl);
        print('🧹 Blob URL limpiada');
      });
      
    } catch (e) {
      print('❌ Error con blob URL: $e');
      
      // Fallback: intentar con url_launcher
      try {
        final Uri pdfUri = Uri.parse(dataUrl);
        if (await canLaunchUrl(pdfUri)) {
          await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
          _showInfoSnackBar('Certificado abierto en nueva pestaña');
          print('✅ Certificado abierto con url_launcher fallback');
        } else {
          throw Exception('No se puede abrir con url_launcher');
        }
      } catch (e2) {
        print('❌ Fallback también falló: $e2');
        throw e;
      }
    }
  }

  void _openPdfFallback(String dataUrl, BuildContext context) {
    try {
      _copyToClipboard(dataUrl, null);
      // Nota: showDialog necesita un contexto válido, pero este método se llama desde _openPdf
      // que no tiene acceso directo al contexto. Se manejará con el mensaje de error.
      print('📋 URL del certificado copiada al portapapeles');
      print('📄 URL: ${dataUrl.substring(0, 100)}...');
      print('ℹ️ Para ver el certificado:');
      print('   1. Abre una nueva pestaña en tu navegador');
      print('   2. Pega la URL en la barra de direcciones (Ctrl+V)');
      print('   3. Presiona Enter');
    } catch (e) {
      print('Error al copiar certificado: $e');
      _showErrorSnackBar('Error al copiar URL del certificado: $e', context);
    }
  }

  void _updateInstitutionInfo(BuildContext context) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Actualizando información...'),
            ],
          ),
        ),
      );

      // Actualizar la información de la institución
      await CertificateAdapter.forceUpdateInstitutionInfo(certificate.id);

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Información de institución actualizada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Recargar la pantalla
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CertificateDetailScreen(certificate: certificate),
        ),
      );
    } catch (e) {
      // Cerrar el diálogo de carga si está abierto
      Navigator.of(context).pop();
      
      // Mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _shareCertificate(BuildContext context) {
    // TODO: Implementar compartir certificado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidad de compartir en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _downloadCertificate(BuildContext context) async {
    try {
      print('🔄 Descargando certificado...');
      print('📊 Estructura de datos del certificado: ${certificate.data.keys.toList()}');
      
      // Verificar si hay PDF del certificado en data.pdfData
      if (certificate.data['pdfData'] != null) {
        final pdfDataValue = certificate.data['pdfData'];
        print('📄 Tipo de pdfData: ${pdfDataValue.runtimeType}');
        
        if (pdfDataValue is String) {
          print('📄 PDF encontrado en data.pdfData (String), descargando...');
          await _downloadPdf(pdfDataValue, context);
          return;
        } else if (pdfDataValue is Map<String, dynamic>) {
          print('📄 Claves de pdfData: ${pdfDataValue.keys.toList()}');
          // Si es un mapa, buscar el campo 'data' o 'content'
          final pdfString = pdfDataValue['data'] ?? 
                           pdfDataValue['content'] ?? 
                           pdfDataValue['base64'] ??
                           pdfDataValue['fileData'] ??
                           pdfDataValue['certificateData'];
          if (pdfString is String && pdfString.isNotEmpty) {
            print('📄 PDF encontrado en data.pdfData (Map), descargando...');
            await _downloadPdf(pdfString, context);
            return;
          }
        }
      }
      
      // Verificar si hay PDF en data.customCertificateData
      if (certificate.data['customCertificateData'] != null) {
        final customData = certificate.data['customCertificateData'];
        print('📄 Tipo de customCertificateData: ${customData.runtimeType}');
        
        if (customData is String) {
          print('📄 PDF encontrado en customCertificateData (String), descargando...');
          await _downloadPdf(customData, context);
          return;
        } else if (customData is Map<String, dynamic>) {
          print('📄 Claves de customCertificateData: ${customData.keys.toList()}');
          final pdfString = customData['data'] ?? 
                           customData['content'] ?? 
                           customData['base64'] ??
                           customData['fileData'] ??
                           customData['certificateData'] ??
                           customData['pdfData'];
          if (pdfString is String && pdfString.isNotEmpty) {
            print('📄 PDF encontrado en customCertificateData (Map), descargando...');
            await _downloadPdf(pdfString, context);
            return;
          }
        }
      }
      
      // Si no se encuentra PDF
      _showErrorSnackBar('No se encontró PDF para descargar', context);
      
    } catch (e) {
      print('❌ Error al descargar certificado: $e');
      _showErrorSnackBar('Error al descargar certificado: $e', context);
    }
  }

  Future<void> _downloadPdf(String pdfContent, BuildContext context) async {
    // Determinar si es base64 puro o data URL
    final String dataUrl = pdfContent.startsWith('data:') 
        ? pdfContent 
        : 'data:application/pdf;base64,$pdfContent';
    
    try {
      print('🔄 Descargando PDF del certificado...');
      print('📄 URL generada: ${dataUrl.substring(0, 100)}...');
      
      // Usar JavaScript para crear blob URL y descargar
      await _downloadPdfWithBlob(dataUrl, context);
      
    } catch (e) {
      print('❌ Error al descargar PDF: $e');
      _showErrorSnackBar('Error al descargar PDF: $e', context);
    }
  }

  Future<void> _downloadPdfWithBlob(String dataUrl, BuildContext context) async {
    try {
      print('🔄 Creando blob URL para descarga...');
      
      // Extraer el base64 del data URL
      final String base64Data = dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      print('📊 Base64 extraído: ${base64Data.substring(0, 50)}...');
      
      // Decodificar base64 a bytes
      final List<int> bytes = base64Decode(base64Data);
      print('📊 Bytes decodificados: ${bytes.length} bytes');
      
      // Crear blob usando JavaScript
      final blob = html.Blob([bytes], 'application/pdf');
      
      // Crear URL del blob
      final blobUrl = html.Url.createObjectUrl(blob);
      print('📄 Blob URL creada: $blobUrl');
      
      // Generar nombre de archivo descriptivo
      final fileName = _generateFileName();
      
      // Crear elemento de descarga
      final anchor = html.AnchorElement(href: blobUrl);
      anchor.download = fileName;
      anchor.style.display = 'none';
      
      // Agregar al DOM temporalmente
      html.document.body?.children.add(anchor);
      
      // Simular click para iniciar descarga
      anchor.click();
      
      // Limpiar
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(blobUrl);
      
      _showSuccessSnackBar('Certificado descargado correctamente como: $fileName', context);
      print('✅ Certificado descargado exitosamente como: $fileName');
      
    } catch (e) {
      print('❌ Error con blob URL: $e');
      _showErrorSnackBar('Error al descargar PDF: $e', context);
    }
  }

  String _generateFileName() {
    try {
      // Obtener título del certificado
      String title = certificate.title.isNotEmpty ? certificate.title : 'Certificado';
      
      // Obtener nombre del estudiante
      String studentName = certificate.studentName.isNotEmpty ? certificate.studentName : 'Estudiante';
      
      // Limpiar caracteres especiales que pueden causar problemas en nombres de archivo
      String cleanTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      String cleanStudentName = studentName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
      
      // Generar nombre del archivo
      String fileName = '${cleanTitle}_${cleanStudentName}.pdf';
      
      // Limitar longitud del nombre de archivo (máximo 100 caracteres)
      if (fileName.length > 100) {
        fileName = fileName.substring(0, 100) + '.pdf';
      }
      
      print('📄 Nombre de archivo generado: $fileName');
      return fileName;
      
    } catch (e) {
      print('❌ Error generando nombre de archivo: $e');
      return 'certificado.pdf'; // Fallback
    }
  }

  Widget _buildQRCodeSection(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xff6C4DDC).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xff6C4DDC).withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Color(0xff6C4DDC).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: Color(0xff6C4DDC),
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Código QR de Verificación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Escanea este código QR para verificar la autenticidad del certificado',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            // Código QR visual
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: QrImageView(
                data: certificate.qrCode,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            // Información del QR
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Text(
                    'URL de Verificación:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  SelectableText(
                    certificate.qrCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


}

// Clase para pintar patrones de fondo
class BackgroundPatternPainter extends CustomPainter {
  final String pattern;
  final Color color;

  BackgroundPatternPainter({
    required this.pattern,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (pattern) {
      case 'dots':
        _paintDots(canvas, size, paint);
        break;
      case 'lines':
        _paintLines(canvas, size, paint);
        break;
      case 'grid':
        _paintGrid(canvas, size, paint);
        break;
      case 'diagonal':
        _paintDiagonal(canvas, size, paint);
        break;
      default:
        break;
    }
  }

  void _paintDots(Canvas canvas, Size size, Paint paint) {
    final double spacing = 20.0;
    final double radius = 2.0;
    
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  void _paintLines(Canvas canvas, Size size, Paint paint) {
    final double spacing = 30.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint..strokeWidth = 1.0,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size, Paint paint) {
    final double spacing = 30.0;
    
    // Líneas verticales
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint..strokeWidth = 1.0,
      );
    }
    
    // Líneas horizontales
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint..strokeWidth = 1.0,
      );
    }
  }

  void _paintDiagonal(Canvas canvas, Size size, Paint paint) {
    final double spacing = 40.0;
    
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

