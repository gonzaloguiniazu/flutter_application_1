import 'package:flutter/material.dart';

class CategoriaIngresoScreen extends StatelessWidget {
  const CategoriaIngresoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar Categoría"),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // vuelve a IngresoScreen
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón Ahorros
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop("Ahorros");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Ahorros",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),

            // Botón Depósitos
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop("Depositos");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Depósitos",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),

            // Botón Salario
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop("Salario");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Salario",
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
