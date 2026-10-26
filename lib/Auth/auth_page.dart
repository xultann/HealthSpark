// Import statements for Flutter UI components and authentication pages
import 'package:flutter/material.dart';
import 'package:healthspark/Intro%20Pages/register_page.dart';
import 'package:healthspark/Intro%20Pages/login_page.dart';

// Authentication page widget that manages switching between login and register screens
// This widget acts as a container that can toggle between two authentication forms
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

// State class for AuthPage that manages the UI state and screen switching logic
class _AuthPageState extends State<AuthPage> {
  // Boolean flag to control which authentication screen is currently displayed
  // true = Login Page, false = Register Page
  bool showLoginPage = true;

  // Method to toggle between login and register screens
  // This is called when user clicks on "Don't have an account?" or "Already have an account?"
  void toggleScreens(){
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Conditional rendering based on the showLoginPage flag
    if(showLoginPage){
      // Display login page and pass the toggle function to allow switching to register
      return LoginPage(showRegisterPage: toggleScreens);
    } else {
      // Display register page and pass the toggle function to allow switching to login
      return RegisterPage(showLoginPage: toggleScreens,);
    }
  }
}