// lib/services/alert_service.dart
// Servicio centralizado para manejar alertas estilo SweetAlert

import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class AlertService {
  // Alerta de éxito
  static void showSuccess(BuildContext context, String title, String message, {VoidCallback? onOk}) {
    Alert(
      context: context,
      type: AlertType.success,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () {
            Navigator.pop(context);
            onOk?.call();
          },
          color: Color(0xff6C4DDC),
        ),
      ],
    ).show();
  }

  // Alerta de error
  static void showError(BuildContext context, String title, String message, {VoidCallback? onOk}) {
    Alert(
      context: context,
      type: AlertType.error,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () {
            Navigator.pop(context);
            onOk?.call();
          },
          color: Colors.red,
        ),
      ],
    ).show();
  }

  // Alerta de advertencia
  static void showWarning(BuildContext context, String title, String message, {VoidCallback? onOk}) {
    Alert(
      context: context,
      type: AlertType.warning,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () {
            Navigator.pop(context);
            onOk?.call();
          },
          color: Colors.orange,
        ),
      ],
    ).show();
  }

  // Alerta informativa
  static void showInfo(BuildContext context, String title, String message, {VoidCallback? onOk}) {
    Alert(
      context: context,
      type: AlertType.info,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: Text(
            "OK",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () {
            Navigator.pop(context);
            onOk?.call();
          },
          color: Colors.blue,
        ),
      ],
    ).show();
  }

  // Alerta de confirmación
  static void showConfirmation(BuildContext context, String title, String message, {
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = "Confirmar",
    String cancelText = "Cancelar",
  }) {
    Alert(
      context: context,
      type: AlertType.info,
      title: title,
      desc: message,
      buttons: [
        DialogButton(
          child: Text(
            cancelText,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () {
            Navigator.pop(context);
            onCancel?.call();
          },
          color: Colors.grey,
        ),
        DialogButton(
          child: Text(
            confirmText,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirm.call();
          },
          color: Color(0xff6C4DDC),
        ),
      ],
    ).show();
  }

  // Alerta de carga
  static void showLoading(BuildContext context, String message) {
    Alert(
      context: context,
      type: AlertType.none,
      title: "Cargando...",
      desc: message,
      buttons: [],
    ).show();
  }

  // Cerrar alerta actual
  static void close(BuildContext context) {
    Navigator.pop(context);
  }

  // Alerta con opciones personalizadas
  static void showCustom(BuildContext context, String title, String message, {
    required List<DialogButton> buttons,
    AlertType type = AlertType.none,
  }) {
    Alert(
      context: context,
      type: type,
      title: title,
      desc: message,
      buttons: buttons,
    ).show();
  }
}
