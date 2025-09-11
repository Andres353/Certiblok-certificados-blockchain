import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetPasswordPage extends StatefulWidget {
  final String userId;
  const SetPasswordPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SetPasswordPageState createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSaving = false;

  Future<void> _savePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        // Actualiza la contraseña en Firestore (puedes cambiar la lógica si usas Firebase Auth)
        await FirebaseFirestore.instance
            .collection('students')
            .doc(widget.userId)
            .update({
          'password': _passwordController.text.trim(),
          'isVerified': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña creada con éxito')),
        );

        Navigator.of(context).pop(); // o navega a login, etc.
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }

      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text('Usuario ID: ${widget.userId}'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa una contraseña';
                  if (value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _savePassword,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
