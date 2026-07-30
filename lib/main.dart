import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  setupServiceLocator();
  runApp(const ConsultaPlacasApp());
}

class ConsultaPlacasApp extends StatelessWidget {
  const ConsultaPlacasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Fipe Valor',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
