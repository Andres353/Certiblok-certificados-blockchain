import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/user_context_service.dart';
import '../../services/emisor_notification_service.dart';
import '../../services/adapters/emisor_adapter.dart';
import '../../services/alert_service.dart';

class ManageEmisoresScreen extends StatefulWidget {
  @override
  _ManageEmisoresScreenState createState() => _ManageEmisoresScreenState();
}

class _ManageEmisoresScreenState extends State<ManageEmisoresScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _generatePassword = true; // Por defecto generar contraseña automáticamente
  bool _sendEmail = true; // Por defecto enviar email con credenciales
  
  // Variables para tipos de emisores
  Set<String> _selectedCarreraIds = <String>{};
  List<Map<String, dynamic>> _carreras = [];
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _emisores = [];

  @override
  void initState() {
    super.initState();
    _loadEmisores();
    _loadCarreras();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Generar contraseña segura automáticamente (método local para compatibilidad)
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
        AlertService.showError(context, 'Error', 'No se pudo obtener la información de la institución');
        return;
      }

      print('Cargando emisores para institución: ${userContext.institutionId}');

      // Usar EmisorAdapter para cargar emisores
      _emisores = await EmisorAdapter.getEmisoresByInstitution(userContext.institutionId!);

      print('Emisores cargados: ${_emisores.length}');
    } catch (e) {
      print('Error cargando emisores: $e');
      AlertService.showError(context, 'Error', 'Error cargando emisores: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCarreras() async {
    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.institutionId == null) return;

      // Usar EmisorAdapter para cargar carreras
      _carreras = await EmisorAdapter.getCarrerasByInstitution(userContext!.institutionId!);
      
      setState(() {
        _carreras.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      });
    } catch (e) {
      print('Error cargando carreras: $e');
    }
  }


  Future<void> _createEmisor() async {
    if (_emailController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        (!_generatePassword && _passwordController.text.isEmpty)) {
      AlertService.showError(context, 'Error', 'Por favor completa todos los campos');
      return;
    }

    // Validar que se hayan seleccionado carreras
    if (_selectedCarreraIds.isEmpty) {
      AlertService.showError(context, 'Error', 'Por favor selecciona al menos una carrera');
      return;
    }
    
    // Validar formato de email
    final email = _emailController.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      AlertService.showError(context, 'Error', 'Por favor ingresa un email válido (ej: usuario@dominio.com)');
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
        AlertService.showError(context, 'Error', 'No se pudo obtener la información de la institución');
        return;
      }

      print('Creando emisor para institución: ${userContext.institutionId}');

      // Usar EmisorAdapter para crear emisor
      final result = await EmisorAdapter.createEmisor(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        institutionId: userContext.institutionId!,
        institutionName: userContext.currentInstitution?.name ?? 'Institución',
        selectedCarreraIds: _selectedCarreraIds,
        carreras: _carreras,
        generatePassword: _generatePassword,
        customPassword: _generatePassword ? null : _passwordController.text.trim(),
      );

      if (!result['success']) {
        throw Exception(result['message'] ?? 'Error desconocido');
      }

      final password = result['password'] as String;

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
        
        // Mostrar credenciales si están disponibles
        if (emailResult['credentials'] != null) {
          final creds = emailResult['credentials'];
          final credsMessage = 'Credenciales del Emisor:\n\nEmail: ${creds['email']}\nContraseña: ${creds['password']}\nNombre: ${creds['fullName']}';
          AlertService.showSuccess(context, 'Credenciales', credsMessage);
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

      AlertService.showSuccess(context, 'Éxito', message);
    } catch (e) {
      print('Error creando emisor: $e');
      AlertService.showError(context, 'Error', 'Error creando emisor: $e');
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
        await EmisorAdapter.deleteEmisor(emisorId);
        await _loadEmisores();
        AlertService.showSuccess(context, 'Éxito', 'Emisor eliminado exitosamente');
      } catch (e) {
        print('Error eliminando emisor: $e');
        AlertService.showError(context, 'Error', 'Error eliminando emisor: $e');
      }
    }
  }

  Future<void> _toggleEmisorStatus(Map<String, dynamic> emisor) async {
    final isCurrentlyActive = emisor['is_active'] != false;
    final action = isCurrentlyActive ? 'suspender' : 'activar';
    
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar $action'),
          content: Text('¿Estás seguro de que quieres $action este emisor?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action == 'suspender' ? 'Suspender' : 'Activar'),
              style: TextButton.styleFrom(
                foregroundColor: action == 'suspender' ? Colors.orange : Colors.green,
              ),
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        await EmisorAdapter.toggleEmisorStatus(emisor['id'], !isCurrentlyActive);
        
        await _loadEmisores();
        
        AlertService.showSuccess(
          context, 
          'Éxito', 
          'Emisor ${action == 'suspender' ? 'suspendido' : 'activado'} exitosamente'
        );
      } catch (e) {
        print('Error ${action} emisor: $e');
        AlertService.showError(context, 'Error', 'Error ${action} emisor: $e');
      }
    }
  }

  void _editEmisor(Map<String, dynamic> emisor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    // Controladores para el formulario de edición
    final emailController = TextEditingController(text: emisor['email'] ?? '');
    final fullNameController = TextEditingController(
      text: emisor['full_name'] ?? emisor['fullName'] ?? ''
    );
    final passwordController = TextEditingController();
    
    // Variables para el estado del diálogo
    Set<String> selectedCarreraIds = <String>{};
    String passwordOption = 'none'; // 'none', 'generate', 'custom'
    
    // Cargar asignaciones actuales
    final assignments = emisor['assignments'] ?? [];
    if (assignments.isNotEmpty) {
      for (final assignment in assignments) {
        final assignmentData = assignment as Map<String, dynamic>;
        if (assignmentData['type'] == 'general') {
          selectedCarreraIds.add('all');
        } else if (assignmentData['type'] == 'carrera') {
          selectedCarreraIds.add(assignmentData['areaId']);
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                'Editar Emisor',
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
                        controller: emailController,
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
                        controller: fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre Completo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      // Tipo de Emisor
                      Text(
                        'Carreras Asignadas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Opción para seleccionar todas las carreras
                      Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedCarreraIds.contains('all') 
                                ? Color(0xff6C4DDC) 
                                : Colors.grey[300]!,
                            width: selectedCarreraIds.contains('all') ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: selectedCarreraIds.contains('all') 
                              ? Color(0xff6C4DDC).withOpacity(0.1)
                              : Colors.white,
                        ),
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              if (selectedCarreraIds.contains('all')) {
                                selectedCarreraIds.clear();
                              } else {
                                selectedCarreraIds.clear();
                                selectedCarreraIds.add('all');
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectedCarreraIds.contains('all'),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedCarreraIds.clear();
                                        selectedCarreraIds.add('all');
                                      } else {
                                        selectedCarreraIds.remove('all');
                                      }
                                    });
                                  },
                                  activeColor: Color(0xff6C4DDC),
                                ),
                                SizedBox(width: 12),
                                Icon(
                                  Icons.public,
                                  color: selectedCarreraIds.contains('all') 
                                      ? Color(0xff6C4DDC) 
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Todas las carreras',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: selectedCarreraIds.contains('all') 
                                              ? Color(0xff6C4DDC) 
                                              : Colors.black87,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Puede emitir certificados a todos los estudiantes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: selectedCarreraIds.contains('all') 
                                              ? Color(0xff6C4DDC).withOpacity(0.8)
                                              : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Lista de carreras individuales
                      if (!selectedCarreraIds.contains('all')) ...[
                        Text(
                          'Selecciona carreras específicas:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff2E2F44),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _carreras.length,
                            itemBuilder: (context, index) {
                              final carrera = _carreras[index];
                              final carreraId = carrera['id'] as String;
                              final isSelected = selectedCarreraIds.contains(carreraId);
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Color(0xff6C4DDC).withOpacity(0.1)
                                      : Colors.white,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedCarreraIds.add(carreraId);
                                      } else {
                                        selectedCarreraIds.remove(carreraId);
                                      }
                                    });
                                  },
                                  title: Text(
                                    carrera['name'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? Color(0xff6C4DDC) : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Carrera académica',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  activeColor: Color(0xff6C4DDC),
                                  controlAffinity: ListTileControlAffinity.leading,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 16),
                      
                      // Opciones para cambiar contraseña
                      Text(
                        'Cambiar Contraseña',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Opción 1: No cambiar contraseña
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: passwordOption == 'none' 
                                ? Color(0xff6C4DDC) 
                                : Colors.grey[300]!,
                            width: passwordOption == 'none' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: passwordOption == 'none' 
                              ? Color(0xff6C4DDC).withOpacity(0.1)
                              : Colors.white,
                        ),
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              passwordOption = 'none';
                              passwordController.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                        children: [
                                Radio<String>(
                                  value: 'none',
                                  groupValue: passwordOption,
                            onChanged: (value) {
                              setDialogState(() {
                                      passwordOption = value ?? 'none';
                                  passwordController.clear();
                              });
                            },
                                  activeColor: Color(0xff6C4DDC),
                          ),
                                SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                    'Mantener contraseña actual',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: passwordOption == 'none' 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                            ),
                          ),
                        ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Opción 2: Generar contraseña automáticamente
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: passwordOption == 'generate' 
                                ? Color(0xff6C4DDC) 
                                : Colors.grey[300]!,
                            width: passwordOption == 'generate' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: passwordOption == 'generate' 
                              ? Color(0xff6C4DDC).withOpacity(0.1)
                              : Colors.white,
                        ),
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              passwordOption = 'generate';
                              passwordController.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'generate',
                                  groupValue: passwordOption,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      passwordOption = value ?? 'generate';
                                      passwordController.clear();
                                    });
                                  },
                                  activeColor: Color(0xff6C4DDC),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Generar nueva contraseña automáticamente',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: passwordOption == 'generate' 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Opción 3: Contraseña personalizada
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: passwordOption == 'custom' 
                                ? Color(0xff6C4DDC) 
                                : Colors.grey[300]!,
                            width: passwordOption == 'custom' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: passwordOption == 'custom' 
                              ? Color(0xff6C4DDC).withOpacity(0.1)
                              : Colors.white,
                        ),
                        child: InkWell(
                          onTap: () {
                            setDialogState(() {
                              passwordOption = 'custom';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Radio<String>(
                                  value: 'custom',
                                  groupValue: passwordOption,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      passwordOption = value ?? 'custom';
                                    });
                                  },
                                  activeColor: Color(0xff6C4DDC),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ingresar contraseña personalizada',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: passwordOption == 'custom' 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Campo de contraseña manual (solo si se selecciona opción personalizada)
                      if (passwordOption == 'custom') ...[
                        SizedBox(height: 16),
                        TextField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: Icon(Icons.lock),
                            helperText: 'Mínimo 8 caracteres, incluir mayúsculas, minúsculas, números y símbolos',
                          ),
                          obscureText: true,
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
                    _updateEmisor(
                      emisor['id'],
                      emailController.text.trim(),
                      fullNameController.text.trim(),
                      selectedCarreraIds,
                      passwordOption,
                      passwordController.text.trim(),
                    );
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
                    'Actualizar',
                    style: TextStyle(fontSize: isWeb ? 16 : 14),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateEmisor(
    String emisorId,
    String email,
    String fullName,
    Set<String> selectedCarreraIds,
    String passwordOption, // 'none', 'generate', 'custom'
    String password,
  ) async {
    if (email.isEmpty || fullName.isEmpty) {
      AlertService.showError(context, 'Error', 'Por favor completa todos los campos');
      return;
    }

    if (selectedCarreraIds.isEmpty) {
      AlertService.showError(context, 'Error', 'Por favor selecciona al menos una carrera');
      return;
    }

    // Validar contraseña personalizada si se seleccionó esa opción
    if (passwordOption == 'custom' && password.isEmpty) {
      AlertService.showError(context, 'Error', 'Por favor ingresa una contraseña o selecciona otra opción');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar EmisorAdapter para actualizar emisor
      final result = await EmisorAdapter.updateEmisor(
        emisorId: emisorId,
        email: email,
        fullName: fullName,
        selectedCarreraIds: selectedCarreraIds,
        carreras: _carreras,
        generatePassword: passwordOption == 'generate',
        customPassword: passwordOption == 'custom' ? password : null,
        keepPassword: passwordOption == 'none',
      );

      if (!result['success']) {
        throw Exception(result['message'] ?? 'Error desconocido');
      }
      
      await _loadEmisores();
      
      AlertService.showSuccess(context, 'Éxito', 'Emisor actualizado exitosamente');
    } catch (e) {
      print('Error actualizando emisor: $e');
      AlertService.showError(context, 'Error', 'Error actualizando emisor: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateEmisorDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;
    
    // Variables locales para el diálogo
    Set<String> selectedCarreraIds = <String>{};
    bool generatePassword = true;
    bool sendEmail = true;
    
    // Cargar carreras antes de abrir el diálogo
    _loadCarreras();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
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
                  
                  // Tipo de Emisor
                  Text(
                    'Carreras Asignadas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2E2F44),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Opción para seleccionar todas las carreras
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedCarreraIds.contains('all') 
                            ? Color(0xff6C4DDC) 
                            : Colors.grey[300]!,
                        width: selectedCarreraIds.contains('all') ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: selectedCarreraIds.contains('all') 
                          ? Color(0xff6C4DDC).withOpacity(0.1)
                          : Colors.white,
                    ),
                    child: InkWell(
                      onTap: () {
                        setDialogState(() {
                          if (selectedCarreraIds.contains('all')) {
                            selectedCarreraIds.clear();
                          } else {
                            selectedCarreraIds.clear();
                            selectedCarreraIds.add('all');
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Checkbox(
                              value: selectedCarreraIds.contains('all'),
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedCarreraIds.clear();
                                    selectedCarreraIds.add('all');
                                  } else {
                                    selectedCarreraIds.remove('all');
                                  }
                                });
                              },
                              activeColor: Color(0xff6C4DDC),
                            ),
                            SizedBox(width: 12),
                            Icon(
                              Icons.public,
                              color: selectedCarreraIds.contains('all') 
                                  ? Color(0xff6C4DDC) 
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Todas las carreras',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: selectedCarreraIds.contains('all') 
                                          ? Color(0xff6C4DDC) 
                                          : Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Puede emitir certificados a todos los estudiantes',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selectedCarreraIds.contains('all') 
                                          ? Color(0xff6C4DDC).withOpacity(0.8)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Lista de carreras individuales
                  if (!selectedCarreraIds.contains('all')) ...[
                    Text(
                      'Selecciona carreras específicas:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff2E2F44),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: _carreras.length,
                        itemBuilder: (context, index) {
                          final carrera = _carreras[index];
                          final carreraId = carrera['id'] as String;
                          final isSelected = selectedCarreraIds.contains(carreraId);
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Color(0xff6C4DDC).withOpacity(0.1)
                                  : Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedCarreraIds.add(carreraId);
                                  } else {
                                    selectedCarreraIds.remove(carreraId);
                                  }
                                });
                              },
                              title: Text(
                                carrera['name'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? Color(0xff6C4DDC) : Colors.black87,
                                ),
                              ),
                                  subtitle: Text(
                                    'Carrera académica',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              activeColor: Color(0xff6C4DDC),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 16),
                  
                  // Indicador de carreras seleccionadas
                  if (selectedCarreraIds.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xff6C4DDC).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xff6C4DDC),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Carreras seleccionadas:',
                                style: TextStyle(
                                  color: Color(0xff6C4DDC),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ...selectedCarreraIds.map((carreraId) {
                            if (carreraId == 'all') {
                              return Text(
                                '• Todas las carreras',
                                style: TextStyle(
                                  color: Color(0xff6C4DDC),
                                  fontSize: 12,
                                ),
                              );
                            } else {
                              final carrera = _carreras.firstWhere(
                                (c) => c['id'] == carreraId,
                                orElse: () => {'name': 'Carrera no encontrada'},
                              );
                              return Text(
                                '• ${carrera['name']}',
                                style: TextStyle(
                                  color: Color(0xff6C4DDC),
                                  fontSize: 12,
                                ),
                              );
                            }
                          }).toList(),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  
                  // Opción para generar contraseña automáticamente
                  Row(
                    children: [
                      Checkbox(
                        value: generatePassword,
                        onChanged: (value) {
                          setDialogState(() {
                            generatePassword = value ?? true;
                            if (generatePassword) {
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
                        value: sendEmail,
                        onChanged: (value) {
                          setDialogState(() {
                            sendEmail = value ?? true;
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
                  if (!generatePassword) ...[
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
                _createEmisorFromDialog(
                  selectedCarreraIds: selectedCarreraIds,
                  generatePassword: generatePassword,
                  sendEmail: sendEmail,
                );
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
      },
    );
  }

  void _createEmisorFromDialog({
    required Set<String> selectedCarreraIds,
    required bool generatePassword,
    required bool sendEmail,
  }) {
    // Actualizar las variables del estado del widget
    setState(() {
      _selectedCarreraIds = selectedCarreraIds;
      _generatePassword = generatePassword;
      _sendEmail = sendEmail;
    });
    
    // Llamar al método original
    _createEmisor();
  }

  Widget _buildAssignmentsInfo(Map<String, dynamic> emisor, bool isWeb) {
    // Obtener asignaciones del emisor
    final assignments = emisor['assignments'] as List<dynamic>? ?? [];
    
    if (assignments.isEmpty) {
      // Fallback para emisores antiguos sin asignaciones
      return _buildLegacyEmisorInfo(emisor, isWeb);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mostrar asignaciones
        ...assignments.map((assignment) {
          final assignmentData = assignment as Map<String, dynamic>;
          final type = assignmentData['type'] as String;
          final areaName = assignmentData['areaName'] as String;
          
          return Container(
            margin: EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(
                  _getAssignmentIcon(type),
                  size: isWeb ? 12 : 10,
                  color: Color(0xff6C4DDC),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getAssignmentDisplayText(type, areaName),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: isWeb ? 11 : 9,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildLegacyEmisorInfo(Map<String, dynamic> emisor, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información del tipo de emisor
        Row(
          children: [
            Icon(
              _getEmisorTypeIcon(emisor['emisorType']),
              size: isWeb ? 16 : 12,
              color: Color(0xff6C4DDC),
            ),
            SizedBox(width: 4),
            Text(
              _getEmisorTypeDisplayName(emisor['emisorType']),
              style: TextStyle(
                color: Color(0xff6C4DDC),
                fontSize: isWeb ? 12 : 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        // Información del área asignada
        if (emisor['carreraName'] != null) ...[
          SizedBox(height: 2),
          Text(
            'Carrera: ${emisor['carreraName']}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isWeb ? 11 : 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        if (emisor['facultadName'] != null && emisor['carreraName'] == null) ...[
          SizedBox(height: 2),
          Text(
            'Facultad: ${emisor['facultadName']}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: isWeb ? 11 : 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  IconData _getAssignmentIcon(String type) {
    switch (type) {
      case 'general':
        return Icons.public;
      case 'facultad':
        return Icons.account_balance;
      case 'carrera':
        return Icons.menu_book;
      case 'programa':
        return Icons.school;
      default:
        return Icons.assignment;
    }
  }

  String _getAssignmentDisplayText(String type, String areaName) {
    switch (type) {
      case 'general':
        return 'Todos los estudiantes';
      case 'facultad':
        return 'Facultad: $areaName';
      case 'carrera':
        return 'Carrera: $areaName';
      case 'programa':
        return 'Programa: $areaName';
      default:
        return areaName;
    }
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular número de columnas basado en el ancho disponible
        int crossAxisCount;
        double childAspectRatio;
        
        if (constraints.maxWidth > 1600) {
          crossAxisCount = 4;
          childAspectRatio = 2.8;
        } else if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
          childAspectRatio = 2.6;
        } else if (constraints.maxWidth > 900) {
          crossAxisCount = 2;
          childAspectRatio = 2.4;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 3.0;
        }
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _emisores.length,
          itemBuilder: (context, index) {
            final emisor = _emisores[index];
            return _buildEmisorCard(emisor, true);
          },
        );
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
                (emisor['full_name'] ?? emisor['fullName'] ?? 'U')[0].toUpperCase(),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          emisor['full_name'] ?? emisor['fullName'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isWeb ? 18 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Indicador de estado
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (emisor['is_active'] != false) 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (emisor['is_active'] != false) 
                                ? Colors.green 
                                : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: (emisor['is_active'] != false) 
                                    ? Colors.green 
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              (emisor['is_active'] != false) ? 'Activo' : 'Suspendido',
                              style: TextStyle(
                                color: (emisor['is_active'] != false) 
                                    ? Colors.green 
                                    : Colors.orange,
                                fontSize: isWeb ? 11 : 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  SizedBox(height: isWeb ? 4 : 2),
                  
                  // Información de asignaciones múltiples
                  _buildAssignmentsInfo(emisor, isWeb),
                ],
              ),
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'suspend',
                  child: Row(
                    children: [
                      Icon(Icons.pause_circle, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(emisor['is_active'] == false ? 'Activar' : 'Suspender'),
                    ],
                  ),
                ),
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
                switch (value) {
                  case 'edit':
                    _editEmisor(emisor);
                    break;
                  case 'suspend':
                    _toggleEmisorStatus(emisor);
                    break;
                  case 'delete':
                    _deleteEmisor(emisor['id']);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmisorTypeIcon(String? emisorType) {
    switch (emisorType) {
      case 'general':
        return Icons.school;
      case 'carrera':
        return Icons.menu_book;
      case 'facultad':
        return Icons.account_balance;
      default:
        return Icons.school;
    }
  }

  String _getEmisorTypeDisplayName(String? emisorType) {
    switch (emisorType) {
      case 'general':
        return 'General';
      case 'carrera':
        return 'Por Carrera';
      case 'facultad':
        return 'Por Facultad';
      default:
        return 'General';
    }
  }
}
