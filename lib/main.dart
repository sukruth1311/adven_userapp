import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:user_app/features/user/main_navigation.dart';
import 'package:user_app/themes/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'firebase_options.dart';
import 'state/auth_provider.dart';
import 'features/auth/login_screen.dart';

// ══════════════════════════════════════════════════════════════════════
//  MAIN — Firebase Auth persists sessions automatically via Riverpod.
//  User stays logged in after app restart until they explicitly sign out.
// ══════════════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WebViewPlatform.instance = AndroidWebViewPlatform();
  runApp(const ProviderScope(child: UserApp()));
}

class UserApp extends ConsumerWidget {
  const UserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
//  ANIMATED SPLASH SCREEN
// ══════════════════════════════════════════════════════════════════════
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _taglineFade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
          ),
        );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2600), _navigate);
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    final authAsync = ref.read(authStateProvider);
    if (authAsync.hasValue) {
      _doNavigate(authAsync.value);
    } else {
      // Auth still loading — listen once
      ref.listenManual(authStateProvider, (_, next) {
        next.whenData(_doNavigate);
      });
    }
  }

  void _doNavigate(dynamic user) {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user != null ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A6B5A), Color(0xFF0D3D30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo + name
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.28),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.travel_explore_rounded,
                            color: Colors.white,
                            size: 52,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'ADVENTRA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tagline
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Text(
                      'Your Premium Travel Experience',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Progress bar
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => FadeTransition(
                  opacity: _taglineFade,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 130,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withOpacity(0.18),
                            color: Colors.white.withOpacity(0.8),
                            minHeight: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Loading your experience...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
