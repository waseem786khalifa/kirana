import 'package:flutter/material.dart';
import 'package:kirana_core/kirana_core.dart';

import 'customer_ui.dart';
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
    final ThemeData baseTheme = KiranaTheme.light(
      seed: CustomerPalette.primary,
    );
    final TextTheme textTheme = baseTheme.textTheme.apply(
      bodyColor: CustomerPalette.textPrimary,
      displayColor: CustomerPalette.textPrimary,
    );

    return MaterialApp(
      title: 'Kirana Saarthi',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: CustomerPalette.background,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: CustomerPalette.primary,
          onPrimary: Colors.white,
          primaryContainer: CustomerPalette.primaryLight,
          onPrimaryContainer: CustomerPalette.primaryDark,
          surface: CustomerPalette.surface,
          onSurface: CustomerPalette.textPrimary,
          outline: CustomerPalette.border,
          outlineVariant: CustomerPalette.border,
          error: CustomerPalette.danger,
        ),
        textTheme: textTheme.copyWith(
          headlineSmall: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.45,
          ),
          titleLarge: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          titleMedium: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          bodyMedium: textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: CustomerPalette.background,
          foregroundColor: CustomerPalette.textPrimary,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: CustomerPalette.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.35,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: CustomerPalette.surface,
          hintStyle: TextStyle(
            color: CustomerPalette.textSecondary,
            fontSize: 13,
          ),
          labelStyle: TextStyle(color: CustomerPalette.textSecondary),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(13)),
            borderSide: BorderSide(color: CustomerPalette.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(13)),
            borderSide: BorderSide(color: CustomerPalette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(13)),
            borderSide: BorderSide(color: CustomerPalette.primary, width: 1.4),
          ),
        ),
        cardTheme: const CardThemeData(
          color: CustomerPalette.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            side: BorderSide(color: CustomerPalette.border),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52),
            backgroundColor: CustomerPalette.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: CustomerPalette.primaryDark,
            side: const BorderSide(color: CustomerPalette.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: CustomerPalette.border,
          thickness: 1,
          space: 1,
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 70,
          elevation: 0,
          backgroundColor: CustomerPalette.surface,
          indicatorColor: CustomerPalette.primaryLight,
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final bool selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected
                  ? CustomerPalette.primaryDark
                  : CustomerPalette.textPrimary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            final bool selected = states.contains(WidgetState.selected);
            return IconThemeData(
              color: selected
                  ? CustomerPalette.primary
                  : CustomerPalette.textPrimary,
              size: 23,
            );
          }),
        ),
      ),
      themeMode: ThemeMode.light,
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
            colors: <Color>[
              CustomerPalette.primaryDark,
              CustomerPalette.primary,
            ],
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
