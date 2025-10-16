import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CategoriaIngreso.dart';

class IngresoScreen extends StatefulWidget {
  const IngresoScreen({super.key});

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen> {
  String _monto = "";

  void _agregarNumero(String numero) {
    setState(() {
      _monto += numero;
    });
  }

  void _borrarUltimo() {
    if (_monto.isNotEmpty) {
      setState(() {
        _monto = _monto.substring(0, _monto.length - 1);
      });
    }
  }

  void _ingresarMonto() {
    if (_monto.isNotEmpty) {
      final double valor = double.parse(_monto);

      // Navega a la pantalla de categorías de ingreso pasando el monto
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoriaIngreso(
            monto: _monto,
            onCategoriaSeleccionada: (categoria) async {
              await FirebaseFirestore.instance.collection('movimientos').add({
                'monto': valor,
                'categoria': categoria.toLowerCase(),
                'fecha': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst); // vuelve al Home
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar Ingreso"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Monto mostrado arriba
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _monto.isEmpty ? "0" : _monto,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),

          // Teclado numérico
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox.shrink();
                if (index == 10) {
                  return _buildButton("0", () => _agregarNumero("0"));
                }
                if (index == 11) {
                  return _buildButton("⌫", _borrarUltimo);
                }
                return _buildButton("${index + 1}", () => _agregarNumero("${index + 1}"));
              },
            ),
          ),

          // Botón ingresar
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _ingresarMonto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Ingresar",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}