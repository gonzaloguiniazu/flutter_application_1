import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final CollectionReference _usuariosRef = FirebaseFirestore.instance
      .collection('usuarios');

  // ===================
  // FUNCIONES CRUD
  // ===================

  Future<void> _alta() async {
    final datos = await _pedirDatosUsuario(context, title: 'Alta de usuario');
    if (datos == null) return; // cancelado

    await _usuariosRef.add({
      'nombre': datos['nombre'],
      'apellido': datos['apellido'],
      'dni': datos['dni'],
      'email': datos['email'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _baja(String docId) async {
    await _usuariosRef.doc(docId).delete();
  }

  Future<void> _modificacion(String docId, Map<String, dynamic> oldData) async {
    final datos = await _pedirDatosUsuario(
      context,
      title: 'Modificar usuario',
      initial: oldData,
    );
    if (datos == null) return;

    await _usuariosRef.doc(docId).update({
      'nombre': datos['nombre'],
      'apellido': datos['apellido'],
      'dni': datos['dni'],
      'email': datos['email'],
    });
  }

  // ===================
  // DIALOGO DE FORMULARIO
  // ===================

  Future<Map<String, String>?> _pedirDatosUsuario(
    BuildContext context, {
    required String title,
    Map<String, dynamic>? initial,
  }) async {
    final nombreController = TextEditingController(
      text: initial?['nombre'] ?? '',
    );
    final apellidoController = TextEditingController(
      text: initial?['apellido'] ?? '',
    );
    final dniController = TextEditingController(text: initial?['dni'] ?? '');
    final emailController = TextEditingController(
      text: initial?['email'] ?? '',
    );

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: apellidoController,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextField(
                  controller: dniController,
                  decoration: const InputDecoration(labelText: 'DNI'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'nombre': nombreController.text.trim(),
                  'apellido': apellidoController.text.trim(),
                  'dni': dniController.text.trim(),
                  'email': emailController.text.trim(),
                });
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // ===================
  // UI
  // ===================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // BOTÓN DE ALTA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _alta, child: const Text('Alta')),
              ],
            ),

            const SizedBox(height: 16),

            // BUSCADOR
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o DNI',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16),

            // LISTADO
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _usuariosRef
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No hay datos.'));
                  }

                  final filteredDocs =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        final nombre =
                            (data['nombre'] ?? '').toString().toLowerCase();
                        final dni =
                            (data.containsKey('dni') ? data['dni'] ?? '' : '')
                                .toString()
                                .toLowerCase();

                        return nombre.contains(_searchQuery) ||
                            dni.contains(_searchQuery);
                      }).toList();

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DNI: ${data['dni'] ?? ''}'),
                              Text('Email: ${data['email'] ?? ''}'),
                              Text('ID: ${doc.id}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _modificacion(doc.id, data),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () => _confirmarBaja(context, doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarBaja(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar usuario'),
          content: const Text('¿Estás seguro de eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _baja(docId);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
