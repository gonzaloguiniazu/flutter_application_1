import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'GastoScreen.dart';

class ListaGastosScreen extends StatefulWidget {
  final DateTime fechaSeleccionada;
  final String periodo;

  const ListaGastosScreen({
    super.key,
    required this.fechaSeleccionada,
    required this.periodo,
  });

  @override
  State<ListaGastosScreen> createState() => _ListaGastosScreenState();
}

class _ListaGastosScreenState extends State<ListaGastosScreen> {
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

  Map<String, List<Map<String, dynamic>>> _gastosPorCategoria = {};
  Set<String> _categoriasExpandidas = {};

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    final snapshot = await FirebaseFirestore.instance.collection('movimientos').get();
    Map<String, List<Map<String, dynamic>>> gastosPorCategoria = {};

    DateTime fechaInicio = widget.fechaSeleccionada;
    DateTime fechaFin = widget.fechaSeleccionada;

    if (widget.periodo == 'semana') {
      fechaInicio = widget.fechaSeleccionada
          .subtract(Duration(days: widget.fechaSeleccionada.weekday - 1));
      fechaFin = fechaInicio.add(const Duration(days: 6));
    } else if (widget.periodo == 'mes') {
      fechaInicio =
          DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month, 1);
      fechaFin = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month + 1, 0);
    } else if (widget.periodo == 'año') {
      fechaInicio = DateTime(widget.fechaSeleccionada.year, 1, 1);
      fechaFin = DateTime(widget.fechaSeleccionada.year, 12, 31);
    }

    String fechaInicioDia = DateFormat('yyyy-MM-dd').format(fechaInicio);
    String fechaFinDia = DateFormat('yyyy-MM-dd').format(fechaFin);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final monto = (data['monto'] ?? 0).toDouble();
      final fecha = (data['fecha'] as Timestamp?)?.toDate();

      if (fecha != null && monto < 0) {
        String fechaDoc = DateFormat('yyyy-MM-dd').format(fecha);
        if (fechaDoc.compareTo(fechaInicioDia) >= 0 &&
            fechaDoc.compareTo(fechaFinDia) <= 0) {
          String categoria = (data['categoria'] ?? 'otro').toString().toLowerCase();

          if (!gastosPorCategoria.containsKey(categoria)) {
            gastosPorCategoria[categoria] = [];
          }

          gastosPorCategoria[categoria]!.add({
            'id': doc.id,
            'monto': monto.abs(),
            'fecha': fecha,
            'categoria': categoria,
          });
        }
      }
    }

    if (!mounted) return;

    setState(() {
      _gastosPorCategoria = gastosPorCategoria;
    });
  }

  void _toggleCategoria(String categoria) {
    setState(() {
      if (_categoriasExpandidas.contains(categoria)) {
        _categoriasExpandidas.remove(categoria);
      } else {
        _categoriasExpandidas.add(categoria);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> categorias = _gastosPorCategoria.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Detallados'),
        backgroundColor: Colors.purple,
      ),
      body: categorias.isEmpty
          ? const Center(
              child: Text(
                'No hay gastos en este período',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                String categoria = categorias[index];
                List<Map<String, dynamic>> gastos = _gastosPorCategoria[categoria]!;
                double totalCategoria = gastos.fold(0, (sum, gasto) => sum + gasto['monto']);
                Color colorCategoria = coloresCategorias[categoria] ?? Colors.grey;
                bool expandida = _categoriasExpandidas.contains(categoria);

                return Column(
                  children: [
                    ListTile(
                      tileColor: expandida ? colorCategoria.withOpacity(0.1) : null,
                      leading: Icon(Icons.category, color: colorCategoria),
                      title: Text(
                        categoria.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorCategoria,
                        ),
                      ),
                      subtitle: Text('${gastos.length} gasto(s)'),
                      trailing: Text(
                        '\$${totalCategoria.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorCategoria,
                        ),
                      ),
                      onTap: () => _toggleCategoria(categoria),
                    ),
                    if (expandida)
                      ...gastos.map((gasto) {
                        return ListTile(
                          contentPadding: const EdgeInsets.only(left: 60, right: 16),
                          title: Text(
                            DateFormat('dd/MM/yyyy').format(gasto['fecha']),
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: Text(
                            '\$${gasto['monto'].toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GastoScreen(
                                  gastoId: gasto['id'],
                                  montoInicial: gasto['monto'],
                                  categoriaInicial: gasto['categoria'],
                                ),
                              ),
                            );
                            _cargarGastos();
                          },
                        );
                      }).toList(),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
    );
  }
}