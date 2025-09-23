import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // IMPORTANTE: tu LoginScreen
import 'GastoScreen.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _saldoActual = 0.0;

  // Referencia a la colección de movimientos en Firestore
  final CollectionReference _movimientosRef =
      FirebaseFirestore.instance.collection('movimientos');

  @override
  void initState() {
    super.initState();
    _cargarSaldo();
  }

  Future<void> _cargarSaldo() async {
    final snapshot = await _movimientosRef.get();
    double saldo = 0.0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final monto = (data['monto'] ?? 0).toDouble();
      saldo += monto;
    }

    if (!mounted) return;

    setState(() {
      _saldoActual = saldo;
    });
  }

  Future<void> _agregarMovimiento(double monto) async {
    await _movimientosRef.add({
      'monto': monto,
      'fecha': FieldValue.serverTimestamp(),
    });
    _cargarSaldo();
  }

  void _mostrarDialogoMovimiento({required bool esIngreso}) {
    final TextEditingController _montoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(esIngreso ? 'Registrar Ingreso' : 'Registrar Gasto'),
          content: TextField(
            controller: _montoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final texto = _montoController.text.trim();
                if (texto.isNotEmpty) {
                  final monto = double.tryParse(texto) ?? 0.0;
                  if (monto > 0) {
                    _agregarMovimiento(esIngreso ? monto : -monto);
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple, // fondo violeta
        title: const Text(
          "Control de Gastos",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Barra circular con saldo
            SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _saldoActual >= 0 ? Colors.green : Colors.red),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Saldo Actual",
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        "\$${_saldoActual.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Botones de gasto (+) e ingreso (−) más grandes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(28),
                  ),
                 onPressed: () async {
    final valor = await Navigator.of(context).push<double>(
      MaterialPageRoute(builder: (_) => const GastoScreen()),
    );

    if (valor != null && valor > 0) {
      _agregarMovimiento(-valor); // guardalo en Firestore como gasto
    }
  },
                  child: const Icon(Icons.remove, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(28),
                  ),
                  onPressed: () => _mostrarDialogoMovimiento(esIngreso: true),
                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
