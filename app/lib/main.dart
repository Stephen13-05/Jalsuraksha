import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'frontend/ashaworkers/login.dart';
import 'frontend/ashaworkers/signup.dart';
import 'l10n/app_localizations.dart';
import 'locale/locale_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp when locale changes
    return AnimatedBuilder(
      animation: LocaleController.instance,
      builder: (context, _) {
        const primaryMint = Color(0xFF00D09E);
        const primaryMintDark = Color(0xFF00B18A);
        const softMint = Color(0xFFEAFBF6);

        final colorScheme = ColorScheme.fromSeed(
          seedColor: primaryMint,
          primary: primaryMint,
          secondary: primaryMintDark,
          brightness: Brightness.light,
        );

        return MaterialApp(
          title: 'Waterborne - ASHA Worker',
          debugShowCheckedModeBanner: false,
          locale: LocaleController.instance.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ne'),
            Locale('as'),
            Locale('hi'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: softMint,
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryMint,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: softMint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: primaryMint),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryMint,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                elevation: 0,
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryMint,
                side: const BorderSide(color: primaryMint),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: primaryMint,
              unselectedItemColor: Color(0xFF9CA3AF),
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              showUnselectedLabels: true,
            ),
            chipTheme: ChipThemeData(
              backgroundColor: softMint,
              selectedColor: primaryMint,
              labelStyle: const TextStyle(color: Colors.black87),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: primaryMint)),
            ),
            dividerColor: const Color(0xFFE5E7EB),
          ),
          home: const _SplashScreen(),
        );
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen({Key? key}) : super(key: key);

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final isReturning = prefs.getBool('isReturningUser') ?? false;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => isReturning
            ? const AshaWorkerLoginPage()
            : const AshaWorkerSignUpPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const softMint = Color(0xFFEAFBF6);
    return Scaffold(
      backgroundColor: softMint,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            // App Logo
            SizedBox(
              height: 180,
              child: Image(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3.5),
            ),
          ],
        ),
      ),
    );
  }
}
