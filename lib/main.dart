import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF142340),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const BiliardinoApp(),
    ),
  );
}

class BiliardinoApp extends StatelessWidget {
  const BiliardinoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'NTT Biliardino',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const SplashScreen(),
      );
}
