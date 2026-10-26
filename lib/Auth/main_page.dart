// Import statements for Firebase Auth and Flutter UI components
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthspark/Auth/auth_page.dart';
import 'package:healthspark/Main%20Pages/home_page.dart';

// Main page that handles authentication state and navigation
// This widget acts as a router between authenticated and non-authenticated states
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Listen to Firebase Auth state changes in real-time
        // This automatically updates when user signs in or out
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          // Show loading indicator while checking authentication state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          // If user is authenticated (has data), show the main app (HomePage)
          if (snapshot.hasData && snapshot.data != null){
            print('User authenticated: ${snapshot.data!.email}'); // Debug log
            return const HomePage();
          } else {
            // If user is not authenticated, show the authentication page
            print('User not authenticated, showing AuthPage'); // Debug log
            return const AuthPage();
          }
        },
      ),
    );
  }
}
