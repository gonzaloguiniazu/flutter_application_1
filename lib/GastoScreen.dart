import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CategoriaGasto.dart';

class GastoScreen extends StatefulWidget {
  final String? gastoId;
  final double? montoInicial;
  final String? categoriaInicial;

  const GastoScreen({
    super.key,
    this.gastoId,
    this.montoInicial,
    this.categoriaInicial,
  });

  @override
  State<GastoScreen> createState() => _GastoScreenState();
}

class _GastoScreenState extends State<GastoScreen> {
  String _monto = "";

  @override
  void initState() {
    super.initState();
    if (widget.montoInicial != null) {
      _monto = widget.montoInicial!.toInt().toString();
    }
  }

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

  void _registrarGasto() {
    if (_monto.isNotEmpty) {
      final double valor = double.parse(_monto);

      // Navega a la pantalla de categorías de gasto pasando el monto
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoriaGasto(
            monto: _monto,
            onCategoriaSeleccionada: (categoria) async {
              if (widget.gastoId != null) {
                // Editar gasto existente
                await FirebaseFirestore.instance
                    .collection('movimientos')
                    .doc(widget.gastoId)
                    .update({
                  'monto': -valor,
                  'categoria': categoria.toLowerCase(),
                });
              } else {
                // Crear nuevo gasto
                await FirebaseFirestore.instance.collection('movimientos').add({
                  'monto': -valor,
                  'categoria': categoria.toLowerCase(),
                  'fecha': FieldValue.serverTimestamp(),
                });
              }

              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
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
        title: Text(widget.gastoId != null ? "Editar Gasto" : "Registrar Gasto"),
        backgroundColor: const Color.fromARGB(255, 216, 124, 233),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: widget.gastoId != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () async {
                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: const Text('¿Estás seguro de que deseas eliminar este gasto?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmar == true && context.mounted) {
                      await FirebaseFirestore.instance
                          .collection('movimientos')
                          .doc(widget.gastoId)
                          .delete();

                      if (context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    }
                  },
                ),
              ]
            : null,
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
              color: Colors.red.shade100,
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

          // Botón registrar
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _registrarGasto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Registrar Gasto",
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
        backgroundColor: Colors.red.shade300,
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