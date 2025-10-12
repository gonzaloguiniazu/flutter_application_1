import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // IMPORTANTE: tu LoginScreen
import 'GastoScreen.dart';
import 'IngresoScreen.dart';
import 'CategoriaIngreso.dart';
import 'CategoriaGasto.dart';
import 'dart:math';


class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _saldoActual = 0.0;

  final CollectionReference _movimientosRef =
      FirebaseFirestore.instance.collection('movimientos');

  // ===== CONFIGURACIÓN DEL CÍRCULO =====
  double diametro = 340; // tamaño total del círculo
  double anchoBarra = 40; // grosor del anillo
  double distanciaIconos = 120; // distancia del centro a los íconos

  // ===== CATEGORÍAS DE GASTOS =====
  final Map<String, Map<String, dynamic>> categorias = {
    'Alimentación': {'color': Colors.red, 'icon': Icons.restaurant},
    'Transporte': {'color': Colors.blue, 'icon': Icons.directions_car},
    'Entretenimiento': {'color': Colors.purple, 'icon': Icons.movie},
    'Salud': {'color': Colors.pink, 'icon': Icons.local_hospital},
    'Automóvil': {'color': Colors.grey, 'icon': Icons.directions_car_filled},
    'Facturas': {'color': Colors.yellow, 'icon': Icons.receipt_long},
    'Mascotas': {'color': Colors.green.shade800, 'icon': Icons.pets},
    'Ropa': {'color': Colors.lightBlue, 'icon': Icons.checkroom},
    'Familia': {'color': Colors.green.shade400, 'icon': Icons.family_restroom},
  };

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
    setState(() => _saldoActual = saldo);
  }

  @override
  Widget build(BuildContext context) {
    final categoriasList = categorias.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Control de Gastos"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ===== GRÁFICO CIRCULAR DE CATEGORÍAS =====
            SizedBox(
              height: diametro,
              width: diametro,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Círculo colorido de categorías
                  CustomPaint(
                    size: Size(diametro, diametro),
                    painter: CategoriaCirclePainter(
                      categoriasList,
                      anchoBarra: anchoBarra,
                    ),
                  ),

                  // Íconos distribuidos alrededor
                  ...List.generate(categoriasList.length, (index) {
                    final angle =
                        (2 * pi / categoriasList.length) * index - pi / 2;
                    final offset = Offset(
                      (diametro / 2) + distanciaIconos * cos(angle),
                      (diametro / 2) + distanciaIconos * sin(angle),
                    );
                    return Positioned(
                      left: offset.dx - 14,
                      top: offset.dy - 14,
                      child: Icon(
                        categoriasList[index].value['icon'],
                        color: categoriasList[index].value['color'],
                        size: 30,
                      ),
                    );
                  }),

                  // Texto del saldo actual
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
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ===== BOTONES DE INGRESO Y GASTO =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(26),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/gasto');
                  },
                  child: const Icon(Icons.remove, color: Colors.white, size: 34),
                ),
                const SizedBox(width: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(26),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/ingreso');
                  },
                  child: const Icon(Icons.add, color: Colors.white, size: 34),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== PINTOR PERSONALIZADO DEL CÍRCULO =====
class CategoriaCirclePainter extends CustomPainter {
  final List<MapEntry<String, Map<String, dynamic>>> categorias;
  final double anchoBarra;

  CategoriaCirclePainter(this.categorias, {required this.anchoBarra});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = anchoBarra;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const double startAngleOffset = -pi / 2;
    final total = categorias.length;
    final sweepAngle = (2 * pi) / total;

    for (int i = 0; i < total; i++) {
      paint.color = categorias[i].value['color'];
      canvas.drawArc(
        rect,
        startAngleOffset + (i * sweepAngle),
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}