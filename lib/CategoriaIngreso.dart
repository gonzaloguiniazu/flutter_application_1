import 'package:flutter/material.dart';

class CategoriaIngreso extends StatelessWidget {
  final ValueChanged<String> onCategoriaSeleccionada;
  final String monto;

  const CategoriaIngreso({
    super.key,
    required this.onCategoriaSeleccionada,
    required this.monto,
  });

  static const List<String> categorias = [
    "Ahorros",
    "Depositos",
    "Salario",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Categoría (Ingreso)"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Recuadro mostrando el monto
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              monto.isEmpty ? "0" : monto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),

          // Grilla de categorías centrada
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    return _buildBoton(context, categorias[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoton(BuildContext context, String texto) {
    return ElevatedButton(
      onPressed: () {
        onCategoriaSeleccionada(texto.toLowerCase());
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Colors.green,
            width: 2.5,
          ),
        ),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        ),
      ),
    );
  }
}