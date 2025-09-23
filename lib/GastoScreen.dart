import 'package:flutter/material.dart';

class GastoScreen extends StatefulWidget {
  const GastoScreen({super.key});

  @override
  State<GastoScreen> createState() => _GastoScreenState();
}

class _GastoScreenState extends State<GastoScreen> {
  String _monto = '';

  void _agregarDigito(String digito) {
    setState(() {
      if (_monto.length < 10) _monto += digito;
    });
  }

  void _borrarDigito() {
    setState(() {
      if (_monto.isNotEmpty) {
        _monto = _monto.substring(0, _monto.length - 1);
      }
    });
  }

  void _ingresarMonto() {
    if (_monto.isNotEmpty) {
      final double valor = double.parse(_monto);
      // Aquí podés enviar el valor a Firestore o retornar a la pantalla anterior
      Navigator.of(context).pop(valor);
    }
  }

  Widget _buildTecla(String texto, {VoidCallback? onTap}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          onPressed: onTap ?? () => _agregarDigito(texto),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // botones rojos
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Registrar gasto"),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Recuadro rojo con monto
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            child: Text(
              _monto.isEmpty ? "0" : _monto,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Teclado numérico
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    _buildTecla('1'),
                    _buildTecla('2'),
                    _buildTecla('3'),
                  ],
                ),
                Row(
                  children: [
                    _buildTecla('4'),
                    _buildTecla('5'),
                    _buildTecla('6'),
                  ],
                ),
                Row(
                  children: [
                    _buildTecla('7'),
                    _buildTecla('8'),
                    _buildTecla('9'),
                  ],
                ),
                Row(
                  children: [
                    _buildTecla('←', onTap: _borrarDigito),
                    _buildTecla('0'),
                    Expanded(child: Container()), // espacio vacío
                  ],
                ),
              ],
            ),
          ),

          // Botón ingresar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _ingresarMonto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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
          ),
        ],
      ),
    );
  }
}
