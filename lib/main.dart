import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';
import 'screens/notas_screen.dart';
import 'services/session_controller.dart';

void main() {
  runApp(const NotasApp());
}

class NotasApp extends StatelessWidget {
  const NotasApp({super.key, this.sessionController});

  final SessionController? sessionController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = sessionController ?? SessionController();
        if (sessionController == null) {
          controller.restore();
        }
        return controller;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Notas App',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        routes: {'/registro': (context) => const RegistroScreen()},
        home: const _SessionGate(),
      ),
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionController>(
      builder: (context, session, _) {
        if (session.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return session.isAuthenticated
            ? const NotasScreen()
            : const LoginScreen();
      },
    );
  }
}
