// lib/screens/inicio/login_with_institution.dart
// Pantalla de login con selector de institución para multi-tenant

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/user_context_service.dart';
import '../../models/institution.dart';
import '../../data/sample_institutions.dart';
import 'institution_selector.dart';
import '../home_page.dart';

class LoginWithInstitution extends StatefulWidget {
  @override
  _LoginWithInstitutionState createState() => _LoginWithInstitutionState();
}

class _LoginWithInstitutionState extends State<LoginWithInstitution> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  Institution? _selectedInstitution;

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    final context = await UserContextService.loadUserContext();
    if (context != null && context.currentInstitution != null) {
      setState(() {
        _selectedInstitution = context.currentInstitution;
      });
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userContext = await loginWithContext(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userContext != null) {
        // Verificar si necesita seleccionar institución
        if (UserContextService.needsInstitutionSelection()) {
          _showInstitutionSelector();
        } else {
          _navigateToHome(userContext.userRole);
        }
      } else {
        _showError('Credenciales incorrectas');
      }
    } catch (e) {
      _showError('Error al iniciar sesión: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showInstitutionSelector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionSelector(
          onInstitutionSelected: (institution) async {
            await UserContextService.setCurrentInstitution(institution);
            _navigateToHome(UserContextService.currentContext!.userRole);
          },
          currentInstitutionId: _selectedInstitution?.id,
        ),
      ),
    );
  }

  void _navigateToHome(String role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(role: role),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logodegrado.PNG',
                  width: 200,
                  height: 80,
                  fit: BoxFit.contain,
                ),
              ),
              
              SizedBox(height: 40),
              
              // Título
              Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2E2F44),
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Accede a tu cuenta institucional',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 40),
              
              // Institución seleccionada
              if (_selectedInstitution != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xff6C4DDC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xff6C4DDC).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(int.parse(_selectedInstitution!.colors.primary.replaceAll('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _selectedInstitution!.shortName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
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
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _selectedInstitution!.description,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showInstitutionSelector,
                        icon: Icon(Icons.swap_horiz, color: Color(0xff6C4DDC)),
                        tooltip: 'Cambiar institución',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              // Formulario de login
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              
              SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              
              SizedBox(height: 24),
              
              // Botón de login
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff6C4DDC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Botón para seleccionar institución
              if (_selectedInstitution == null)
                OutlinedButton(
                  onPressed: _showInstitutionSelector,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xff6C4DDC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Seleccionar Institución',
                    style: TextStyle(color: Color(0xff6C4DDC)),
                  ),
                ),
              
              SizedBox(height: 20),
              
              // Enlaces adicionales
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navegar a registro
                      _showError('Registro en desarrollo');
                    },
                    child: Text('Regístrate'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
