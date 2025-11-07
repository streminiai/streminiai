import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'features/chat_provider.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'core/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const StreminiApp());
}

class StreminiApp extends StatelessWidget {
  const StreminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        // Add more providers here as we build them
      ],
      child: MaterialApp(
        title: 'Stremini AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          primaryColor: const Color(0xFF00D9FF),
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00D9FF),
            secondary: const Color(0xFF00D9FF),
            surface: const Color(0xFF1C1C1E),
            background: const Color(0xFF000000),
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF1C1C1E),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2C2C2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintStyle: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

/// Handles initial app setup and routing
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndNavigate();
  }

  Future<void> _checkPermissionsAndNavigate() async {
    // Check if permissions are granted
    final permissionService = PermissionService();
    final hasOverlayPermission = await permissionService.hasOverlayPermission();
    final hasAccessibilityPermission = await permissionService.hasAccessibilityPermission();
    
    // If all permissions granted, go to home, else show onboarding
    setState(() {
      _hasCompletedOnboarding = hasOverlayPermission && hasAccessibilityPermission;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF00D9FF),
          ),
        ),
      );
    }

    return _hasCompletedOnboarding 
        ? const HomeScreen() 
        : const OnboardingScreen();
  }
}
