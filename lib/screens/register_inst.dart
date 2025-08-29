import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../header/HeaderRegisterStudent.dart'; // Importa tu header

final FirebaseFirestore firestore = FirebaseFirestore.instance;

// Función de registro de institución
Future<void> registerInstitution({
  required String name,
  required String email,
  required String logoUrl,
}) async {
  try {
    final institutionData = {
      'name': name.trim(),
      'email': email.trim(),
      'logoUrl': logoUrl.trim(),
      'role': 'superadministrador',
      'status': 'aprobado',
      'createdAt': FieldValue.serverTimestamp(),
    };

    DocumentReference docRef = await firestore
        .collection('Institucion')
        .add(institutionData);

    print('Institución registrada con ID: ${docRef.id}');
  } catch (e) {
    print('Error al registrar la institución: $e');
    rethrow;
  }
}

// Widget para el formulario
class RegisterInst extends StatefulWidget {
  const RegisterInst({super.key});

  @override
  State<RegisterInst> createState() => _RegisterInstState();
}

class _RegisterInstState extends State<RegisterInst> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _logoUrlController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await registerInstitution(
          name: _nameController.text,
          email: _emailController.text,
          logoUrl: _logoUrlController.text,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Institución registrada exitosamente')),
        );

        Navigator.pop(context); // Vuelve atrás
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Institución')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la institución'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Correo inválido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _logoUrlController,
                decoration: const InputDecoration(labelText: 'URL del logo'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Registrar Institución'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
