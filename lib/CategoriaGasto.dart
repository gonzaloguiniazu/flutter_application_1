import 'package:flutter/material.dart';

class CategoriaGasto extends StatelessWidget {
  final ValueChanged<String> onCategoriaSeleccionada;
  final String monto;

  const CategoriaGasto({
    super.key,
    required this.onCategoriaSeleccionada,
    required this.monto,
  });

  static const Map<String, Color> coloresCategorias = {
    "Alimentos": Colors.orange,
    "Transporte": Colors.blue,
    "Servicios": Colors.purple,
    "Automóvil": Colors.amber,
    "Facturas": Colors.teal,
    "Mascotas": Colors.pink,
    "Ropa": Colors.indigo,
    "Familia": Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Categoría (Gasto)"),
        backgroundColor: Colors.red,
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
              color: Colors.red.shade100,
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
                  itemCount: coloresCategorias.length,
                  itemBuilder: (context, index) {
                    String categoria = coloresCategorias.keys.toList()[index];
                    Color color = coloresCategorias[categoria]!;
                    return _buildBoton(context, categoria, color);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoton(BuildContext context, String texto, Color color) {
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
          side: BorderSide(
            color: color,
            width: 2.5,
          ),
        ),
      ),
      child: Text(
        texto,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}