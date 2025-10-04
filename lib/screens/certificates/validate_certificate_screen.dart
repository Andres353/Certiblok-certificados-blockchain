// lib/screens/certificates/validate_certificate_screen.dart
// Pantalla pública para validar certificados

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/certificate_service.dart';
import 'certificate_detail_screen.dart';

class ValidateCertificateScreen extends StatefulWidget {
  const ValidateCertificateScreen({Key? key}) : super(key: key);

  @override
  _ValidateCertificateScreenState createState() => _ValidateCertificateScreenState();
}

class _ValidateCertificateScreenState extends State<ValidateCertificateScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _certificateIdController = TextEditingController();
  final _qrCodeController = TextEditingController();
  
  bool _isLoading = false;
  CertificateValidationResult? _validationResult;
  
  int _selectedTab = 0; // 0: Búsqueda por ID, 1: Escáner QR

  @override
  void dispose() {
    _certificateIdController.dispose();
    _qrCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validar Certificado'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.grey[50],
            child: TabBar(
              controller: TabController(length: 2, vsync: this, initialIndex: _selectedTab),
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                  _validationResult = null;
                });
              },
              labelColor: Color(0xff6C4DDC),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Color(0xff6C4DDC),
              tabs: [
                Tab(
                  icon: Icon(Icons.search),
                  text: 'Buscar por ID',
                ),
                Tab(
                  icon: Icon(Icons.qr_code_scanner),
                  text: 'Escanear QR',
                ),
              ],
            ),
          ),
          
          // Contenido
          Expanded(
            child: TabBarView(
              children: [
                _buildSearchByIdTab(),
                _buildQRScannerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchByIdTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xff6C4DDC)),
                      SizedBox(width: 8),
                      Text(
                        'Validar Certificado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ingresa el ID del certificado para verificar su autenticidad y estado actual.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Formulario de búsqueda
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID del Certificado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff2E2F44),
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _certificateIdController,
                  decoration: InputDecoration(
                    hintText: 'Ingresa el ID del certificado...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.workspace_premium),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.paste),
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el ID del certificado';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 24),
                
                // Botón de validación
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateById,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Validar Certificado',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Resultado de validación
          if (_validationResult != null)
            _buildValidationResult(),
        ],
      ),
    );
  }

  Widget _buildQRScannerTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: Color(0xff6C4DDC)),
                      SizedBox(width: 8),
                      Text(
                        'Escanear Código QR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Escanea el código QR del certificado para verificar su autenticidad automáticamente.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Simulador de escáner QR (por ahora)
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Escáner QR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Funcionalidad de escáner QR en desarrollo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Campo manual para QR
                  TextFormField(
                    controller: _qrCodeController,
                    decoration: InputDecoration(
                      hintText: 'Pega aquí el código QR...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                    maxLines: 3,
                  ),
                  
                  SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateByQR,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff6C4DDC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Validar QR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Resultado de validación
          if (_validationResult != null)
            _buildValidationResult(),
        ],
      ),
    );
  }

  Widget _buildValidationResult() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _validationResult!.isValid ? Icons.check_circle : Icons.cancel,
                  color: _validationResult!.isValid ? Colors.green : Colors.red,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Resultado de Validación',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2E2F44),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _validationResult!.isValid 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _validationResult!.isValid 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                _validationResult!.message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _validationResult!.isValid ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
            
            if (_validationResult!.certificate != null) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _viewCertificate(_validationResult!.certificate!),
                  icon: Icon(Icons.visibility),
                  label: Text('Ver Detalles del Certificado'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _validateById() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final result = await CertificateService.validateCertificate(
        certificateId: _certificateIdController.text.trim(),
      );
      
      setState(() {
        _validationResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error validando certificado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _validateByQR() async {
    if (_qrCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ingresa un código QR'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final result = await CertificateService.validateCertificate(
        qrCode: _qrCodeController.text.trim(),
      );
      
      setState(() {
        _validationResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error validando certificado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null) {
      _certificateIdController.text = clipboardData!.text!;
    }
  }

  void _viewCertificate(Certificate certificate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertificateDetailScreen(certificate: certificate),
      ),
    );
  }
}
