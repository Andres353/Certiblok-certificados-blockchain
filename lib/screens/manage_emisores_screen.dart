import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _loadEmisores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('students')
          .where('role', isEqualTo: 'emisor')
          .get();

      setState(() {
        _emisores = querySnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
      });
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
        _institutionController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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

      // Crear nuevo emisor
      await _firestore.collection('students').add({
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'institution': _institutionController.text.trim(),
        'password': _passwordController.text.trim(),
        'role': 'emisor',
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'verificationCode': '000000', // Código por defecto
      });

      // Limpiar campos
      _emailController.clear();
      _fullNameController.clear();
      _institutionController.clear();
      _passwordController.clear();

      // Recargar lista
      await _loadEmisores();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emisor creado exitosamente')),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Crear Nuevo Emisor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _institutionController,
                  decoration: InputDecoration(
                    labelText: 'Institución/Facultad',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createEmisor();
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Emisores'),
        backgroundColor: Color(0xff6C4DDC),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestión de Emisores UV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Administra los usuarios que pueden emitir certificados académicos',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Botón crear emisor
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Emisores Registrados (${_emisores.length})',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff2E2F44),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showCreateEmisorDialog,
                        icon: Icon(Icons.add),
                        label: Text('Crear Emisor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xff6C4DDC),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Lista de emisores
                  Expanded(
                    child: _emisores.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No hay emisores registrados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Crea el primer emisor para comenzar',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _emisores.length,
                            itemBuilder: (context, index) {
                              final emisor = _emisores[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Color(0xff6C4DDC),
                                    child: Text(
                                      emisor['fullName'][0].toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    emisor['fullName'],
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(emisor['email']),
                                      Text('Institución: ${emisor['institution']}'),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
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
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEmisorDialog,
        backgroundColor: Color(0xff6C4DDC),
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear Emisor',
      ),
    );
  }
}
