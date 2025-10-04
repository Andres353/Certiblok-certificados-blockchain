// lib/screens/inicio/password_reset_screen.dart
import 'package:flutter/material.dart';
import '../../services/password_reset_service.dart';
import '../../services/alert_service.dart';

class PasswordResetScreen extends StatefulWidget {
  @override
  _PasswordResetScreenState createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  int _currentStep = 0; // 0: Email, 1: Code, 2: New Password
  String _userEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (_emailController.text.isEmpty) {
      AlertService.showError(context, 'Error', 'Por favor ingresa tu email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await PasswordResetService.sendResetCode(_emailController.text.trim());
      
      if (result['success']) {
        setState(() {
          _userEmail = _emailController.text.trim();
          _currentStep = 1;
        });
        AlertService.showSuccess(context, 'Éxito', result['message']);
      } else {
        AlertService.showError(context, 'Error', result['message']);
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error inesperado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty) {
      AlertService.showError(context, 'Error', 'Por favor ingresa el código de verificación');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await PasswordResetService.verifyResetCode(
        _userEmail,
        _codeController.text.trim(),
      );
      
      if (result['success']) {
        setState(() => _currentStep = 2);
        AlertService.showSuccess(context, 'Éxito', result['message']);
      } else {
        AlertService.showError(context, 'Error', result['message']);
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error inesperado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      AlertService.showError(context, 'Error', 'Por favor completa todos los campos');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      AlertService.showError(context, 'Error', 'Las contraseñas no coinciden');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      AlertService.showError(context, 'Error', 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await PasswordResetService.resetPassword(
        _userEmail,
        _newPasswordController.text.trim(),
      );
      
      if (result['success']) {
        AlertService.showSuccess(context, 'Éxito', result['message']);
        Navigator.pop(context);
      } else {
        AlertService.showError(context, 'Error', result['message']);
      }
    } catch (e) {
      AlertService.showError(context, 'Error', 'Error inesperado: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Restablecer Contraseña'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff6C4DDC), Color(0xff8B7DDC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.lock_reset, size: 64, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Restablecer Contraseña',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sigue los pasos para restablecer tu contraseña',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              // Progress Indicator
              Row(
                children: [
                  _buildStepIndicator(0, 'Email', _currentStep >= 0),
                  Expanded(child: _buildStepLine(_currentStep > 0)),
                  _buildStepIndicator(1, 'Código', _currentStep >= 1),
                  Expanded(child: _buildStepLine(_currentStep > 1)),
                  _buildStepIndicator(2, 'Nueva Contraseña', _currentStep >= 2),
                ],
              ),
              SizedBox(height: 32),

              // Form Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: _buildCurrentStep(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Color(0xff6C4DDC) : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Color(0xff6C4DDC) : Colors.grey[600],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      height: 2,
      color: isActive ? Color(0xff6C4DDC) : Colors.grey[300],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildCodeStep();
      case 2:
        return _buildPasswordStep();
      default:
        return _buildEmailStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso 1: Ingresa tu Email',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff2E2F44),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Ingresa el email asociado a tu cuenta para enviarte un código de verificación.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email, color: Color(0xff6C4DDC)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendResetCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Enviar Código',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso 2: Verifica el Código',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff2E2F44),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Hemos enviado un código de verificación a $_userEmail. Ingresa el código de 6 dígitos.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: _codeController,
          decoration: InputDecoration(
            labelText: 'Código de Verificación',
            prefixIcon: Icon(Icons.security, color: Color(0xff6C4DDC)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            hintText: '123456',
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _sendResetCode,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xff6C4DDC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Reenviar Código',
                  style: TextStyle(color: Color(0xff6C4DDC)),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff6C4DDC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Verificar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paso 3: Nueva Contraseña',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xff2E2F44),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Ingresa tu nueva contraseña. Asegúrate de que sea segura y fácil de recordar.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24),
        TextFormField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            labelText: 'Nueva Contraseña',
            prefixIcon: Icon(Icons.lock, color: Color(0xff6C4DDC)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          obscureText: _obscureNewPassword,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirmar Contraseña',
            prefixIcon: Icon(Icons.lock_outline, color: Color(0xff6C4DDC)),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          obscureText: _obscureConfirmPassword,
        ),
        SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff6C4DDC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Restablecer Contraseña',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}

