// lib/screens/student/join_institution_screen.dart
// Pantalla simple para que estudiantes se vinculen a una institución usando código

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/institution.dart';
import '../../services/institution_service.dart';
import '../../services/user_context_service.dart';

class JoinInstitutionScreen extends StatefulWidget {
  @override
  _JoinInstitutionScreenState createState() => _JoinInstitutionScreenState();
}

class _JoinInstitutionScreenState extends State<JoinInstitutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isValidatingCode = false;
  Institution? _selectedInstitution;
  String? _codeError;
  String? _selectedCarreraId;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateCareerCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _codeError = 'Ingresa el código de la carrera';
        _selectedInstitution = null;
      });
      return;
    }

    setState(() {
      _isValidatingCode = true;
      _codeError = null;
    });

    try {
      final career = await InstitutionService.getCareerByCode(
        _codeController.text.trim(),
      );

      if (career != null) {
        // Obtener información de la institución
        final institution = await InstitutionService.getInstitution(career['institutionId']);
        
        if (institution != null) {
          setState(() {
            _selectedInstitution = institution;
            _selectedCarreraId = career['id'];
            _codeError = null;
          });
        } else {
          setState(() {
            _codeError = 'Institución no encontrada';
            _selectedInstitution = null;
          });
        }
      } else {
        setState(() {
          _codeError = 'Código de carrera no válido o carrera inactiva';
          _selectedInstitution = null;
        });
      }
    } catch (e) {
      setState(() {
        _codeError = 'Error al validar el código: $e';
        _selectedInstitution = null;
      });
    } finally {
      setState(() => _isValidatingCode = false);
    }
  }


  Future<void> _joinInstitution() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInstitution == null || _selectedCarreraId == null) {
      setState(() {
        _codeError = 'Debes validar el código de carrera primero';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userContext = UserContextService.currentContext;
      if (userContext?.userId == null) {
        throw Exception('No se pudo obtener el contexto del usuario');
      }

      // Verificar si ya está registrado en esta institución
      if (userContext?.institutionId == _selectedInstitution!.id || 
          userContext?.institutionName == _selectedInstitution!.name ||
          userContext?.institution == _selectedInstitution!.name) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya estás registrado en esta institución'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Obtener información de la carrera desde el código
      final career = await InstitutionService.getCareerByCode(_codeController.text.trim());
      if (career == null) {
        throw Exception('Carrera no encontrada');
      }

      // Actualizar estudiante en la colección users
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userContext!.userId)
          .update({
        'institutionId': _selectedInstitution!.id,
        'institutionName': _selectedInstitution!.name,
        'program': career['name'],
        'faculty': career['facultyName'],
        'programId': _selectedCarreraId,
        'facultyId': career['facultyId'],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Te has vinculado exitosamente a ${career['name']} en ${_selectedInstitution!.name}'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Regresar con éxito
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vincularse con Carrera'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Vincularse con Carrera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ingresa el código de tu carrera para vincular tu cuenta',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Código de Carrera
              Text(
                'Código de Carrera',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        hintText: 'Ej: UVA-SISTEMAS-123',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: _codeError,
                      ),
                      onChanged: (value) {
                        if (_codeError != null) {
                          setState(() => _codeError = null);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isValidatingCode ? null : _validateCareerCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isValidatingCode
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Validar'),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Carrera Seleccionada
              if (_selectedInstitution != null && _selectedCarreraId != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xff6C4DDC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedInstitution!.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Carrera validada correctamente',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 24,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
              ],

              // Botón de Vinculación
              if (_selectedInstitution != null && _selectedCarreraId != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _joinInstitution,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6C4DDC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Vinculando...'),
                            ],
                          )
                        : Text(
                            'Vincularme con la Carrera',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
