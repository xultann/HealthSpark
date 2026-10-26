// Import statements for Flutter core functionality and external packages
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:healthspark/Services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:healthspark/Intro%20Pages/onboarding_screen.dart';
import 'package:healthspark/Auth/main_page.dart';
import 'package:provider/provider.dart';
import 'package:healthspark/Utils/theme_provider.dart';
import 'package:flutter/services.dart';

// Main entry point of the application
// This function initializes the app and sets up necessary configurations
void main() async {
  // Ensure Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred device orientations to portrait only
  // This prevents the app from rotating to landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase services for authentication, database, and storage
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
       androidProvider: AndroidProvider.playIntegrity,
       // or AndroidProvider.debug for development
     );

  // Run the app with Provider pattern for state management
  // MultiProvider allows multiple providers to be available throughout the app
  runApp(
    MultiProvider(
      // Register AuthService as a provider for dependency injection
      providers: [Provider<AuthService>(create: (_) => AuthService())],
      child: const MyApp(),
    ),
  );
}

// Root widget of the application
// This class manages the overall app structure and navigation flow
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Check if the user has seen the onboarding screen before
  // This determines whether to show onboarding or go directly to main app
  Future<bool> _checkOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_seen') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the app with ChangeNotifierProvider for theme management
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MaterialApp(
        // Remove the debug banner that appears in debug mode
        debugShowCheckedModeBanner: false,
        // Use FutureBuilder to handle the onboarding check asynchronously
        home: FutureBuilder<bool>(
          future: _checkOnboardingSeen(),
          builder: (context, snapshot) {
            // Show loading indicator while checking onboarding status
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else {
              // Navigate to appropriate screen based on onboarding status
              final seen = snapshot.data ?? false;
              return seen ? const MainPage() : const OnboardingScreen();
            }
          },
        ),
        // Add onUnknownRoute to handle any unknown routes gracefully
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const MainPage(),
          );
        },
      ),
    );
  }
}
