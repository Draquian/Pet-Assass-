import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'target_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _zoomController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    // Animación de entrada (fade + scale inicial)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    // Zoom-in suave y continuo durante los 3 s del splash
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );

    _entryController.forward();
    _zoomController.forward();

    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    // Ejecutamos en paralelo: esperar mínimo 3 s y cargar el estado guardado.
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      StorageService.loadState(),
    ]);

    if (!mounted) return;

    final GameState? state = results[1] as GameState?;

    Widget destination;
    if (state != null && state.status != PlayerStatus.none) {
      destination = TargetScreen(initialState: state);
    } else {
      destination = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ──────────────────────────────────────────────────
                Image.asset(
                  'lib/logo/Logo.png',
                  width: 140,
                  height: 140,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(height: 28),

                // ── Nombre de la app ──────────────────────────────────────
                const Text(
                  'Spore Games',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Tagline sutil ─────────────────────────────────────────
                // Text(
                //   'Peto Assassí',
                //   style: TextStyle(
                //     fontSize: 14,
                //     letterSpacing: 1.8,
                //     color: Colors.white.withOpacity(0.45),
                //   ),
                // ),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
