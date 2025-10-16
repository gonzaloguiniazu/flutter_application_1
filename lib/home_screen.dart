import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'GastoScreen.dart';
import 'IngresoScreen.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _saldoActual = 0.0;
  double _ingresosHoy = 0.0;
  double _gastosHoy = 0.0;
  Map<String, double> _gastosPorCategoria = {};
  late DateTime _fechaSeleccionada;

  final CollectionReference _movimientosRef =
      FirebaseFirestore.instance.collection('movimientos');

  final Map<String, Color> coloresCategorias = {
    "alimentos": Colors.orange,
    "transporte": Colors.blue,
    "servicios": Colors.purple,
    "automóvil": Colors.amber,
    "facturas": Colors.teal,
    "mascotas": Colors.pink,
    "ropa": Colors.indigo,
    "familia": Colors.green,
  };

  final Map<String, IconData> iconosCategorias = {
    "alimentos": Icons.fastfood,
    "transporte": Icons.directions_car,
    "servicios": Icons.home_repair_service,
    "automóvil": Icons.directions_car,
    "facturas": Icons.receipt,
    "mascotas": Icons.pets,
    "ropa": Icons.shopping_bag,
    "familia": Icons.family_restroom,
  };

  @override
  void initState() {
    super.initState();
    _inicializarLocale();
    _fechaSeleccionada = DateTime.now();
    _cargarSaldo();
  }

  Future<void> _inicializarLocale() async {
    await initializeDateFormatting('es_ES', null);
  }

  Future<void> _cargarSaldo() async {
    final snapshot = await _movimientosRef.get();
    double saldo = 0.0;
    double ingresos = 0.0;
    double gastos = 0.0;
    Map<String, double> gastosPorCategoria = {};
    final fechaFormato = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final monto = (data['monto'] ?? 0).toDouble();
      saldo += monto;

      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      if (fecha != null && DateFormat('yyyy-MM-dd').format(fecha) == fechaFormato) {
        if (monto > 0) {
          ingresos += monto;
        } else {
          double montoAbsoluto = monto.abs();
          gastos += montoAbsoluto;

          String categoria = (data['categoria'] ?? 'otro').toString().toLowerCase();
          gastosPorCategoria[categoria] = (gastosPorCategoria[categoria] ?? 0) + montoAbsoluto;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _saldoActual = saldo;
      _ingresosHoy = ingresos;
      _gastosHoy = gastos;
      _gastosPorCategoria = gastosPorCategoria;
    });
  }

  void _navegarAIngreso() async {
    await Navigator.pushNamed(context, '/ingreso');
    _cargarSaldo();
  }

  void _navegarAGasto() async {
    await Navigator.pushNamed(context, '/gasto');
    _cargarSaldo();
  }

  void _deslizarDia(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      setState(() {
        _fechaSeleccionada = _fechaSeleccionada.subtract(const Duration(days: 1));
      });
      _cargarSaldo();
    } else if (details.primaryVelocity! < 0) {
      if (_fechaSeleccionada.isBefore(DateTime.now())) {
        setState(() {
          _fechaSeleccionada = _fechaSeleccionada.add(const Duration(days: 1));
        });
        _cargarSaldo();
      }
    }
  }

  Widget _buildProgressIndicator() {
    if (_gastosPorCategoria.isEmpty) {
      return SizedBox.expand(
        child: CircularProgressIndicator(
          value: 1.0,
          strokeWidth: 20,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      );
    }

    List<MapEntry<String, double>> segmentos = _gastosPorCategoria.entries.toList();

    if (segmentos.length == 1) {
      Color colorGasto = coloresCategorias[segmentos[0].key] ?? Colors.grey;
      return Center(
        child: SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 20,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(colorGasto),
          ),
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: 250,
        height: 250,
        child: CustomPaint(
          painter: _MultiColorProgressPainter(
            segmentos: segmentos,
            coloresCategorias: coloresCategorias,
            strokeWidth: 35,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fechaFormato = DateFormat('MM/dd').format(_fechaSeleccionada);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ControlAR"),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _deslizarDia,
        child: Column(
          children: [
            // Contenedor con la fecha
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  DateFormat('EEEE, d MMMM', 'es_ES').format(_fechaSeleccionada),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            
            // Contenedor de la barra circular
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 350,
                      width: 350,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildProgressIndicator(),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                fechaFormato,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "\$${_ingresosHoy.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                "\$${_gastosHoy.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          ..._buildIconosAlrededor(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Contenedor con saldo y botones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Saldo actual: \$${_saldoActual.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(42),
                        ),
                        onPressed: _navegarAGasto,
                        child: const Icon(Icons.remove, color: Colors.white),
                      ),
                      const SizedBox(width: 90),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(42),
                        ),
                        onPressed: _navegarAIngreso,
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildIconosAlrededor() {
    if (_gastosPorCategoria.isEmpty) return [];

    List<Widget> widgets = [];

    final List<Map<String, dynamic>> posiciones = [
      {'left': 157.0, 'top': -20.0, 'angle': -pi / 2},
      {'left': 285.0, 'top': 15.0, 'angle': -pi / 4},
      {'left': 320.0, 'top': 157.0, 'angle': 0.0},
      {'left': 285.0, 'top': 285.0, 'angle': pi / 4},
      {'left': 157.0, 'top': 320.0, 'angle': pi / 2},
      {'left': 15.0, 'top': 285.0, 'angle': 3 * pi / 4},
      {'left': -20.0, 'top': 157.0, 'angle': pi},
      {'left': 15.0, 'top': 15.0, 'angle': -3 * pi / 4},
    ];

    final List<MapEntry<String, double>> categorias =
        _gastosPorCategoria.entries.toList();

    for (int i = 0; i < categorias.length && i < posiciones.length; i++) {
      Color colorCategoria = coloresCategorias[categorias[i].key] ?? Colors.grey;
      IconData iconoCategoria =
          iconosCategorias[categorias[i].key] ?? Icons.category;
      double angle = posiciones[i]['angle'];

      widgets.add(
        Positioned(
          left: posiciones[i]['left'] as double,
          top: posiciones[i]['top'] as double,
          child: Icon(
            iconoCategoria,
            color: colorCategoria,
            size: 36,
          ),
        ),
      );

      widgets.add(
        Positioned.fill(
          child: CustomPaint(
            painter: _LineaPainter(
              angle: angle,
              color: colorCategoria,
              posicion: posiciones[i],
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _MultiColorProgressPainter extends CustomPainter {
  final List<MapEntry<String, double>> segmentos;
  final Map<String, Color> coloresCategorias;
  final double strokeWidth;

  _MultiColorProgressPainter({
    required this.segmentos,
    required this.coloresCategorias,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - (strokeWidth / 2) - 5;

    double totalGastos = segmentos.fold(0, (sum, entry) => sum + entry.value);

    final bgPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    double startAngle = -pi / 2;

    for (var entry in segmentos) {
      double porcentaje = entry.value / totalGastos;
      double sweepAngle = porcentaje * 2 * pi;

      Color color = coloresCategorias[entry.key] ?? Colors.grey;

      final paint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_MultiColorProgressPainter oldDelegate) => true;
}

class _LineaPainter extends CustomPainter {
  final double angle;
  final Color color;
  final Map<String, dynamic> posicion;

  _LineaPainter({
    required this.angle,
    required this.color,
    required this.posicion,
  });

  @override
  void paint(Canvas canvas, Size size) {
     final center = Offset(size.width / 2, size.height / 2);
    final iconCenterX = posicion['left'] + 10;
    final iconCenterY = posicion['top'] + 10;

    // Mover el punto inicial hacia el borde del icono
    final distance = 2; // MODIFICA AQUÍ: aumenta para línea más corta, reduce para más larga
    final startX = iconCenterX + (distance * cos(angle));
    final startY = iconCenterY + (distance * sin(angle));


    final radioBarraExterior = 125.0;

    final bordeX = center.dx + radioBarraExterior * cos(angle);
    final bordeY = center.dy + radioBarraExterior * sin(angle);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
       Offset(startX, startY),
      Offset(bordeX, bordeY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LineaPainter oldDelegate) => true;
}