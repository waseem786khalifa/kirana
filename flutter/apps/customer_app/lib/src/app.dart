import 'package:flutter/material.dart';
import 'package:kirana_core/kirana_core.dart';

import 'customer_controller.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_page.dart';
import 'screens/store_connect_page.dart';

class KiranaCustomerApp extends StatefulWidget {
  const KiranaCustomerApp({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<KiranaCustomerApp> createState() => _KiranaCustomerAppState();
}

class _KiranaCustomerAppState extends State<KiranaCustomerApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color seed = Color(0xFF176B45);
    final ThemeData baseTheme = KiranaTheme.light(seed: seed);
    final ColorScheme colors = baseTheme.colorScheme;

    return MaterialApp(
      title: 'Kirana Saarthi',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF7F6F1),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colors.outlineVariant),
          ),
        ),
        cardTheme: CardThemeData(
          color: colors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colors.outlineVariant),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      darkTheme: KiranaTheme.dark(seed: seed),
      themeMode: ThemeMode.system,
      home: AnimatedBuilder(
        animation: widget.controller,
        builder: (BuildContext context, Widget? child) {
          final CustomerController controller = widget.controller;
          if (controller.booting) return const _LaunchScreen();
          if (controller.profile == null) {
            return OnboardingPage(controller: controller);
          }
          if (controller.selectedStore == null) {
            return StoreConnectPage(controller: controller);
          }
          return HomeShell(controller: controller);
        },
      ),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0F5132), Color(0xFF1C7A50)],
          ),
        ),
        child: Center(
          child: Semantics(
            label: 'Kirana Saarthi loading',
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Color(0xFFFFC94A),
                  child: Icon(
                    Icons.shopping_basket_rounded,
                    size: 38,
                    color: Color(0xFF123B2A),
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Kirana Saarthi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Color(0xFFFFC94A)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
