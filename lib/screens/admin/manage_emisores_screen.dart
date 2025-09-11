import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../../services/user_context_service.dart';
import '../../services/emisor_notification_service.dart';

class ManageEmisoresScreen extends StatefulWidget {
  @override
  _ManageEmisoresScreenState createState() => _ManageEmisoresScreenState();
}

class _ManageEmisoresScreenState extends State<ManageEmisoresScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _generatePassword = true; // Por defecto generar contraseña automáticamente
  bool _sendEmail = true; // Por defecto enviar email con credenciales
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _emisores = [];

  @override
  void initState() {
    super.initState();
    _loadEmisores();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Generar contraseña segura automáticamente
  String _generateSecurePassword() {
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    String allChars = lowerCase + upperCase + numbers + symbols;
    Random random = Random.secure();
    
    String password = '';
    
    // Asegurar al menos un carácter de cada tipo
    password += lowerCase[random.nextInt(lowerCase.length)];
    password += upperCase[random.nextInt(upperCase.length)];
    password += numbers[random.nextInt(numbers.length)];
    password += symbols[random.nextInt(symbols.length)];
    
    // Completar con caracteres aleatorios
    for (int i = 4; i < 12; i++) {
      password += allChars[random.nextInt(allChars.length)];
    }
    
    // Mezclar la contraseña
    List<String> passwordList = password.split('');
    passwordList.shuffle(random);
    return passwordList.join('');
  }

  Future<void> _loadEmisores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el contexto del usuario actual
      final userContext = UserContextService.currentContext;
      if (userContext == null || userContext.institutionId == null) {
        print('Error: No se pudo obtener el contexto de usuario o institución');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo obtener la información de la institución')),
        );
        return;
      }

      print('Cargando emisores para institución: ${userContext.institutionId}');

      QuerySnapshot querySnapshot = await _firestore
          .collection('students')
          .where('role', isEqualTo: 'emisor')
          .where('institutionId', isEqualTo: userContext.institutionId)
          .get();

      setState(() {
        _emisores = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      });

      print('Emisores cargados: ${_emisores.length}');
    } catch (e) {
      print('Error cargando emisores: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando emisores: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createEmisor() async {
    if (_emailController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        (!_generatePassword && _passwordController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }
    
    // Validar formato de email
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa un email válido (ej: usuario@dominio.com)')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el contexto del usuario actual
      final userContext = UserContextService.currentContext;
      if (userContext == null || userContext.institutionId == null) {
        print('Error: No se pudo obtener el contexto de usuario o institución');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: No se pudo obtener la información de la institución')),
        );
        return;
      }

      // Verificar si el email ya existe
      QuerySnapshot existingUser = await _firestore
          .collection('students')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (existingUser.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El email ya está registrado')),
        );
        return;
      }

      print('Creando emisor para institución: ${userContext.institutionId}');

      // Generar o usar contraseña
      String password = _generatePassword 
          ? _generateSecurePassword() 
          : _passwordController.text.trim();

      // Crear nuevo emisor
      await _firestore.collection('students').add({
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'password': password,
        'role': 'emisor',
        'institutionId': userContext.institutionId,
        'institutionName': userContext.currentInstitution?.name ?? 'Institución',
        'isVerified': true,
        'mustChangePassword': true, // SIEMPRE debe cambiar contraseña en el primer login
        'isTemporaryPassword': _generatePassword, // Solo es temporal si se generó automáticamente
        'createdAt': FieldValue.serverTimestamp(),
        'verificationCode': '000000', // Código por defecto
      });

      // Enviar email con credenciales si está habilitado (ANTES de limpiar campos)
      if (_sendEmail) {
        print('📧 Enviando email con credenciales...');
        print('📧 Email del controlador: "${_emailController.text}"');
        print('📧 Email trim: "${_emailController.text.trim()}"');
        print('📧 Email vacío: ${_emailController.text.trim().isEmpty}');
        print('📧 FullName: "${_fullNameController.text.trim()}"');
        print('📧 Password: "$password"');
        print('📧 Institution: "${userContext.currentInstitution?.name ?? 'Institución'}"');
        print('📧 Admin: "${userContext.userName}"');
        
        final emailResult = await EmisorNotificationService.sendEmisorCredentials(
          email: _emailController.text.trim(),
          fullName: _fullNameController.text.trim(),
          password: password,
          institutionName: userContext.currentInstitution?.name ?? 'Institución',
          adminName: userContext.userName,
        );
        
        if (emailResult['success']) {
          print('✅ Email enviado exitosamente');
        } else {
          print('❌ Error enviando email: ${emailResult['message']}');
        }
        
        // Mostrar credenciales en SnackBar si están disponibles
        if (emailResult['credentials'] != null) {
          final creds = emailResult['credentials'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Credenciales del Emisor:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Email: ${creds['email']}'),
                  Text('Contraseña: ${creds['password']}'),
                  Text('Nombre: ${creds['fullName']}'),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 10),
            ),
          );
        }
      }

      // Limpiar campos DESPUÉS de enviar email
      _emailController.clear();
      _fullNameController.clear();
      _passwordController.clear();

      // Recargar lista
      await _loadEmisores();

      // Mostrar mensaje con contraseña si se generó automáticamente
      String message = _generatePassword 
          ? 'Emisor creado exitosamente. Contraseña temporal: $password'
          : 'Emisor creado exitosamente';

      if (_sendEmail) {
        message += _generatePassword 
            ? '\nLas credenciales han sido enviadas por email.'
            : '\nNotificación enviada por email.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 8), // Más tiempo para leer la contraseña
        ),
      );
    } catch (e) {
      print('Error creando emisor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creando emisor: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmisor(String emisorId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar este emisor?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        await _firestore.collection('students').doc(emisorId).delete();
        await _loadEmisores();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emisor eliminado exitosamente')),
        );
      } catch (e) {
        print('Error eliminando emisor: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando emisor: $e')),
        );
      }
    }
  }

  void _showCreateEmisorDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Crear Nuevo Emisor',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: isWeb ? 500 : double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Opción para generar contraseña automáticamente
                  Row(
                    children: [
                      Checkbox(
                        value: _generatePassword,
                        onChanged: (value) {
                          setState(() {
                            _generatePassword = value ?? true;
                            if (_generatePassword) {
                              _passwordController.clear();
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Generar contraseña automáticamente (recomendado)',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Opción para enviar email
                  Row(
                    children: [
                      Checkbox(
                        value: _sendEmail,
                        onChanged: (value) {
                          setState(() {
                            _sendEmail = value ?? true;
                          });
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Enviar credenciales por email',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  
                  // Campo de contraseña manual (solo si no se genera automáticamente)
                  if (!_generatePassword) ...[
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.lock),
                        helperText: 'Mínimo 8 caracteres, incluir mayúsculas, minúsculas, números y símbolos',
                      ),
                      obscureText: true,
                    ),
                  ] else ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Se generará una contraseña segura de 12 caracteres que el emisor deberá cambiar en su primer inicio de sesión.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: isWeb ? 16 : 14),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createEmisor();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff6C4DDC),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 24 : 20,
                  vertical: isWeb ? 12 : 10,
                ),
              ),
              child: Text(
                'Crear Emisor',
                style: TextStyle(fontSize: isWeb ? 16 : 14),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    final userContext = UserContextService.currentContext;
    final institutionName = userContext?.currentInstitution?.name ?? 'Institución';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Emisores - $institutionName'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header responsive
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isWeb ? 24 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestión de Emisores',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWeb ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Administra los usuarios que pueden emitir certificados académicos',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isWeb ? 18 : 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Sección de controles responsive
                        _buildControlsSection(isWeb),
                        
                        SizedBox(height: 16),
                        
                        // Lista de emisores responsive
                        _buildEmisoresList(constraints, isWeb),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: screenWidth <= 800 ? FloatingActionButton(
        onPressed: _showCreateEmisorDialog,
        backgroundColor: Color(0xff6C4DDC),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear Emisor',
      ) : null,
    );
  }

  Widget _buildControlsSection(bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWeb) ...[
            // Layout para web: título y botón en la misma fila
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Emisores Registrados (${_emisores.length})',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showCreateEmisorDialog,
                  icon: Icon(Icons.add),
                  label: Text('Crear Emisor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Layout para móvil: título arriba, botón abajo
            Text(
              'Emisores Registrados (${_emisores.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff2E2F44),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showCreateEmisorDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  minimumSize: Size(0, 40),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 8),
                    Text('Crear Emisor', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmisoresList(BoxConstraints constraints, bool isWeb) {
    if (_emisores.isEmpty) {
      return Container(
        height: constraints.maxHeight * 0.4,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: isWeb ? 80 : 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay emisores registrados',
                style: TextStyle(
                  fontSize: isWeb ? 20 : 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Crea el primer emisor para comenzar',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isWeb ? 16 : 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: constraints.maxHeight * 0.5,
      child: isWeb ? _buildWebEmisoresList() : _buildMobileEmisoresList(),
    );
  }

  Widget _buildWebEmisoresList() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: _emisores.length,
      itemBuilder: (context, index) {
        final emisor = _emisores[index];
        return _buildEmisorCard(emisor, true);
      },
    );
  }

  Widget _buildMobileEmisoresList() {
    return ListView.builder(
      itemCount: _emisores.length,
      itemBuilder: (context, index) {
        final emisor = _emisores[index];
        return _buildEmisorCard(emisor, false);
      },
    );
  }

  Widget _buildEmisorCard(Map<String, dynamic> emisor, bool isWeb) {
    return Card(
      margin: EdgeInsets.only(bottom: isWeb ? 0 : 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(isWeb ? 20 : 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: isWeb ? 30 : 20,
              backgroundColor: Color(0xff6C4DDC),
              child: Text(
                emisor['fullName'][0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isWeb ? 18 : 14,
                ),
              ),
            ),
            SizedBox(width: isWeb ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emisor['fullName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 18 : 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isWeb ? 4 : 2),
                  Text(
                    emisor['email'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isWeb ? 14 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteEmisor(emisor['id']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
