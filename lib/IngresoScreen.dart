import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class IngresoScreen extends StatefulWidget {
  final String? ingresoId;
  final double? montoInicial;
  final String? categoriaInicial;

  const IngresoScreen({
    super.key,
    this.ingresoId,
    this.montoInicial,
    this.categoriaInicial,
  });

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen> {
  final TextEditingController _montoController = TextEditingController();
  String? _categoriaSeleccionada;

  final List<String> _categorias = [
    "sueldo",
    "negocio",
    "regalo",
    "intereses",
    "otro",
  ];

  @override
  void initState() {
    super.initState();

    if (widget.montoInicial != null) {
      _montoController.text = widget.montoInicial!.toStringAsFixed(2);
    }

    if (widget.categoriaInicial != null) {
      _categoriaSeleccionada = widget.categoriaInicial;
    }
  }

  Future<void> _guardarIngreso() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    double? monto = double.tryParse(_montoController.text.replaceAll(',', '.'));
    if (monto == null || monto <= 0) return;

    String categoria = _categoriaSeleccionada ?? "otro";

    if (widget.ingresoId != null) {
      // EDITAR
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('movimientos')
          .doc(widget.ingresoId)
          .update({
        'monto': monto, // positivo porque es ingreso
        'categoria': categoria.toLowerCase(),
      });
    } else {
      // CREAR
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('movimientos')
          .add({
        'monto': monto,
        'categoria': categoria.toLowerCase(),
        'fecha': Timestamp.now(),
      });
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ingresoId == null ? 'Nuevo Ingreso' : 'Editar Ingreso'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Monto:", style: TextStyle(fontSize: 18)),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Ej: 1500.00",
              ),
            ),
            const SizedBox(height: 20),

            const Text("Categoría:", style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: _categoriaSeleccionada,
              hint: const Text("Seleccionar categoría"),
              isExpanded: true,
              items: _categorias.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.toUpperCase()),
                );
              }).toList(),
              onChanged: (valor) {
                setState(() {
                  _categoriaSeleccionada = valor;
                });
              },
            ),

            const Spacer(),

            Center(
              child: ElevatedButton(
                onPressed: _guardarIngreso,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                ),
                child: Text(
                  widget.ingresoId == null ? "Guardar" : "Actualizar",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
