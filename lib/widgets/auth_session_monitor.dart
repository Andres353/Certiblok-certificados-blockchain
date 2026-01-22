// lib/widgets/auth_session_monitor.dart
// Widget para monitorear la sesión de autenticación automáticamente

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_security_service.dart';
import '../services/adapters/auth_adapter.dart';

class AuthSessionMonitor extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSessionExpired;

  const AuthSessionMonitor({
    Key? key,
    required this.child,
    this.onSessionExpired,
  }) : super(key: key);

  @override
  _AuthSessionMonitorState createState() => _AuthSessionMonitorState();
}

class _AuthSessionMonitorState extends State<AuthSessionMonitor>
    with WidgetsBindingObserver {
  Timer? _activityTimer;
  Timer? _validationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Registrar actividad cuando la app vuelve al estado activo
    if (state == AppLifecycleState.resumed) {
      AuthSecurityService.recordUserActivity();
      _validateSession();
    }
  }

  void _startMonitoring() {
    // Registrar actividad inicial
    AuthSecurityService.recordUserActivity();

    // Registrar actividad cada vez que el usuario interactúa
    _activityTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {
        await AuthSecurityService.recordUserActivity();
      },
    );

    // Validar sesión periódicamente
    _validationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) async {
        await _validateSession();
      },
    );

    // Iniciar monitoreo en el servicio
    AuthSecurityService.startSessionMonitoring();
  }

  void _stopMonitoring() {
    _activityTimer?.cancel();
    _validationTimer?.cancel();
    AuthSecurityService.stopSessionMonitoring();
  }

  Future<void> _validateSession() async {
    final isValid = await AuthSecurityService.validateSession();
    if (!isValid && mounted) {
      // Sesión expirada
      _stopMonitoring();
      
      if (widget.onSessionExpired != null) {
        widget.onSessionExpired!();
      } else {
        // Mostrar diálogo y cerrar sesión
        _showSessionExpiredDialog();
      }
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('Sesión Expirada'),
          ],
        ),
        content: const Text(
          'Tu sesión ha expirado por inactividad. Por favor, inicia sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthAdapter.logout();
              // El sistema redirigirá automáticamente al login
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar Listener para detectar cualquier interacción del usuario
    return Listener(
      onPointerDown: (_) {
        AuthSecurityService.recordUserActivity();
      },
      child: widget.child,
    );
  }
}
