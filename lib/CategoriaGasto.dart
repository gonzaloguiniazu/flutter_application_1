import 'package:flutter/material.dart';

class CategoriaGasto extends StatelessWidget {
  const CategoriaGasto({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Categoría"),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // vuelve a GastoScreen
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBoton(context, "Alimentos"),
            _buildBoton(context, "Transporte"),
            _buildBoton(context, "Servicios"),
          ],
        ),
      ),
    );
  }

  Widget _buildBoton(BuildContext context, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop(texto); // retorna categoría a GastoScreen
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }
}
