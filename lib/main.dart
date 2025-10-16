import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importaciones de tus pantallas
import 'login_screen.dart';
import 'home_screen.dart';
import 'IngresoScreen.dart';
import 'GastoScreen.dart';
import 'CategoriaIngreso.dart';
import 'CategoriaGasto.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control de Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return HomeScreen(user: user);
          } else {
            return const LoginScreen();
          }
        },
        '/ingreso': (context) => const IngresoScreen(),
        '/gasto': (context) => const GastoScreen(),
      },
    );
  }
}

/// Esta clase verifica si hay un usuario autenticado
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostramos pantalla de carga mientras verifica
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si hay usuario logueado, va al Home
        if (snapshot.hasData) {
          return HomeScreen(user: snapshot.data!);
        }

        // Si no hay usuario logueado, va al Login
        return const LoginScreen();
      },
    );
  }
}
