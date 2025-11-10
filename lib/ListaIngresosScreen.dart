import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'IngresoScreen.dart';

class ListaIngresosScreen extends StatefulWidget {
  final DateTime fechaSeleccionada;
  final String periodo;

  const ListaIngresosScreen({
    super.key,
    required this.fechaSeleccionada,
    required this.periodo,
  });

  @override
  State<ListaIngresosScreen> createState() => _ListaIngresosScreenState();
}

class _ListaIngresosScreenState extends State<ListaIngresosScreen> {
  List<Map<String, dynamic>> _ingresos = [];

  @override
  void initState() {
    super.initState();
    _cargarIngresos();
  }

  Future<void> _cargarIngresos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('movimientos')
        .get();

    List<Map<String, dynamic>> ingresos = [];

    DateTime fechaInicio = widget.fechaSeleccionada;
    DateTime fechaFin = widget.fechaSeleccionada;

    if (widget.periodo == 'semana') {
      fechaInicio = widget.fechaSeleccionada
          .subtract(Duration(days: widget.fechaSeleccionada.weekday - 1));
      fechaFin = fechaInicio.add(const Duration(days: 6));
    } else if (widget.periodo == 'mes') {
      fechaInicio = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month, 1);
      fechaFin = DateTime(widget.fechaSeleccionada.year, widget.fechaSeleccionada.month + 1, 0);
    } else if (widget.periodo == 'año') {
      fechaInicio = DateTime(widget.fechaSeleccionada.year, 1, 1);
      fechaFin = DateTime(widget.fechaSeleccionada.year, 12, 31);
    }

    String inicio = DateFormat('yyyy-MM-dd').format(fechaInicio);
    String fin = DateFormat('yyyy-MM-dd').format(fechaFin);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final monto = (data['monto'] ?? 0).toDouble();
      final fecha = (data['fecha'] as Timestamp?)?.toDate();

      if (fecha != null && monto > 0) {
        String fechaDoc = DateFormat('yyyy-MM-dd').format(fecha);
        if (fechaDoc.compareTo(inicio) >= 0 && fechaDoc.compareTo(fin) <= 0) {
          ingresos.add({
            'id': doc.id,
            'monto': monto,
            'fecha': fecha,
          });
        }
      }
    }

    if (!mounted) return;
    setState(() => _ingresos = ingresos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ingresos Detallados'),
        backgroundColor: Colors.green,
      ),
      body: _ingresos.isEmpty
          ? const Center(child: Text('No hay ingresos en este período'))
          : ListView.builder(
              itemCount: _ingresos.length,
              itemBuilder: (context, index) {
                final ingreso = _ingresos[index];
                return ListTile(
                  title: Text(DateFormat('dd/MM/yyyy').format(ingreso['fecha'])),
                  trailing: Text('\$${ingreso['monto'].toStringAsFixed(2)}'),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IngresoScreen(
                          ingresoId: ingreso['id'],
                          montoInicial: ingreso['monto'],
                          categoriaInicial: ingreso['categoria'],
                        ),
                      ),
                    );
                    _cargarIngresos();
                  },
                );
              },
            ),
    );
  }
}
