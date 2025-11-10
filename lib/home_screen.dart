import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'GastoScreen.dart';
import 'IngresoScreen.dart';
import 'ListaGastosScreen.dart';
import 'ListaIngresosScreen.dart';
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
  String _periodoActual = 'día';

  CollectionReference get _movimientosRef =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.user.uid)
          .collection('movimientos');

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

    DateTime fechaInicio = _fechaSeleccionada;
    DateTime fechaFin = _fechaSeleccionada;

    if (_periodoActual == 'semana') {
      fechaInicio = _fechaSeleccionada.subtract(Duration(days: _fechaSeleccionada.weekday - 1));
      fechaFin = fechaInicio.add(const Duration(days: 6));
    } else if (_periodoActual == 'mes') {
      fechaInicio = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month, 1);
      fechaFin = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1, 0);
    } else if (_periodoActual == 'año') {
      fechaInicio = DateTime(_fechaSeleccionada.year, 1, 1);
      fechaFin = DateTime(_fechaSeleccionada.year, 12, 31);
    }

    String fechaInicioDia = DateFormat('yyyy-MM-dd').format(fechaInicio);
    String fechaFinDia = DateFormat('yyyy-MM-dd').format(fechaFin);

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final monto = (data['monto'] ?? 0).toDouble();
      saldo += monto;

      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      if (fecha != null) {
        String fechaDoc = DateFormat('yyyy-MM-dd').format(fecha);
        if (fechaDoc.compareTo(fechaInicioDia) >= 0 && fechaDoc.compareTo(fechaFinDia) <= 0) {
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IngresoScreen()),
    );
    _cargarSaldo();
  }

  void _navegarAGasto() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GastoScreen()),
    );
    _cargarSaldo();
  }

  void _deslizarDia(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      setState(() {
        if (_periodoActual == 'día') {
          _fechaSeleccionada = _fechaSeleccionada.subtract(const Duration(days: 1));
        } else if (_periodoActual == 'semana') {
          _fechaSeleccionada = _fechaSeleccionada.subtract(const Duration(days: 7));
        } else if (_periodoActual == 'mes') {
          _fechaSeleccionada = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month - 1);
        } else if (_periodoActual == 'año') {
          _fechaSeleccionada = DateTime(_fechaSeleccionada.year - 1);
        }
      });
      _cargarSaldo();
    } else if (details.primaryVelocity! < 0) {
      DateTime ahora = DateTime.now();
      DateTime proximaFecha;

      if (_periodoActual == 'día') {
        proximaFecha = _fechaSeleccionada.add(const Duration(days: 1));
      } else if (_periodoActual == 'semana') {
        proximaFecha = _fechaSeleccionada.add(const Duration(days: 7));
      } else if (_periodoActual == 'mes') {
        proximaFecha = DateTime(_fechaSeleccionada.year, _fechaSeleccionada.month + 1);
      } else if (_periodoActual == 'año') {
        proximaFecha = DateTime(_fechaSeleccionada.year + 1);
      } else {
        proximaFecha = ahora;
      }

      if (proximaFecha.isBefore(ahora) || proximaFecha.isAtSameMomentAs(ahora)) {
        setState(() {
          _fechaSeleccionada = proximaFecha;
        });
        _cargarSaldo();
      }
    }
  }

  void _cambiarPeriodo(String periodo) {
    setState(() {
      _periodoActual = periodo;
      _fechaSeleccionada = DateTime.now();
    });
    _cargarSaldo();
  }

  String _obtenerTextoFecha() {
    if (_periodoActual == 'día') {
      return DateFormat('EEEE, d MMMM', 'es_ES').format(_fechaSeleccionada);
    } else if (_periodoActual == 'semana') {
      DateTime inicio = _fechaSeleccionada.subtract(Duration(days: _fechaSeleccionada.weekday - 1));
      DateTime fin = inicio.add(const Duration(days: 6));
      return 'Semana: ${DateFormat('d MMM', 'es_ES').format(inicio)} - ${DateFormat('d MMM', 'es_ES').format(fin)}';
    } else if (_periodoActual == 'mes') {
      return DateFormat('MMMM y', 'es_ES').format(_fechaSeleccionada);
    } else {
      return DateFormat('y', 'es_ES').format(_fechaSeleccionada);
    }
  }

  Widget _buildProgressIndicator() {
    const double barraWidth = 250.0;
    const double barraHeight = 250.0;
    const double barraStrokeWidth = 35.0;

    if (_gastosPorCategoria.isEmpty) {
      return Center(
        child: SizedBox(
          width: barraWidth,
          height: barraHeight,
          child: CustomPaint(
            painter: _MultiColorProgressPainter(
              segmentos: [],
              coloresCategorias: coloresCategorias,
              strokeWidth: barraStrokeWidth,
            ),
          ),
        ),
      );
    }

    List<MapEntry<String, double>> segmentos = _gastosPorCategoria.entries.toList();

    return Center(
      child: SizedBox(
        width: barraWidth,
        height: barraHeight,
        child: CustomPaint(
          painter: _MultiColorProgressPainter(
            segmentos: segmentos,
            coloresCategorias: coloresCategorias,
            strokeWidth: barraStrokeWidth,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.purple,
              ),
              child: const Text(
                'Períodos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Día'),
              onTap: () {
                Navigator.pop(context);
                _cambiarPeriodo('día');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('Semana'),
              onTap: () {
                Navigator.pop(context);
                _cambiarPeriodo('semana');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Mes'),
              onTap: () {
                Navigator.pop(context);
                _cambiarPeriodo('mes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Año'),
              onTap: () {
                Navigator.pop(context);
                _cambiarPeriodo('año');
              },
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _deslizarDia,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  _obtenerTextoFecha(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            
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
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Botón izquierdo para ver gastos
                      IconButton(
                        icon: const Icon(Icons.list_alt, size: 32),
                        color: Colors.purple,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListaGastosScreen(
                                fechaSeleccionada: _fechaSeleccionada,
                                periodo: _periodoActual,
                              ),
                            ),
                          );
                          _cargarSaldo();
                        },
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Saldo actual: \$${_saldoActual.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Botón derecho para ver gastos
                      IconButton(
                        icon: const Icon(Icons.list_alt, size: 32),
                        color: Colors.purple,
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListaIngresosScreen(
                                fechaSeleccionada: _fechaSeleccionada,
                                periodo: _periodoActual,
                              ),
                            ),
                          );
                          _cargarSaldo();
                        },
                      ),
                    ],
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
    final List<Map<String, dynamic>> posiciones = [
      {'categoria': 'alimentos', 'left': 157.0, 'top': -5.0},
      {'categoria': 'transporte', 'left': 270.0, 'top': 25.0},
      {'categoria': 'servicios', 'left': 295.0, 'top': 157.0},
      {'categoria': 'automóvil', 'left': 270.0, 'top': 280.0},
      {'categoria': 'facturas', 'left': 157.0, 'top': 305.0},
      {'categoria': 'mascotas', 'left': 40.0, 'top': 280.0},
      {'categoria': 'ropa', 'left': 15.0, 'top': 157.0},
      {'categoria': 'familia', 'left': 40.0, 'top': 25.0},
    ];

    List<Widget> widgets = [];

    for (var pos in posiciones) {
      String categoria = pos['categoria'];
      Color colorCategoria = coloresCategorias[categoria] ?? Colors.grey;
      IconData iconoCategoria = iconosCategorias[categoria] ?? Icons.category;

      widgets.add(
        Positioned(
          left: pos['left'] as double,
          top: pos['top'] as double,
          child: Icon(
            iconoCategoria,
            color: colorCategoria,
            size: 36,
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

    if (segmentos.isEmpty) {
      final bgPaint = Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, bgPaint);
      return;
    }

    double totalGastos = segmentos.fold(0, (sum, entry) => sum + entry.value);

    final List<String> ordenCategorias = [
      'alimentos',
      'transporte',
      'servicios',
      'automóvil',
      'facturas',
      'mascotas',
      'ropa',
      'familia',
    ];

    Map<String, double> gastosMap = {};
    for (var entry in segmentos) {
      gastosMap[entry.key] = entry.value;
    }

    double startAngle = -pi / 2;

    for (String categoria in ordenCategorias) {
      if (gastosMap.containsKey(categoria)) {
        double monto = gastosMap[categoria]!;
        double porcentaje = monto / totalGastos;
        double sweepAngle = porcentaje * 2 * pi;

        Color color = coloresCategorias[categoria] ?? Colors.grey;

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
  }

  @override
  bool shouldRepaint(_MultiColorProgressPainter oldDelegate) => true;
}