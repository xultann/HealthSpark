// Import statements for Flutter UI components and authentication service
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:healthspark/Services/auth_service.dart';

// Registration page widget that handles new user account creation
// This page collects user information and creates a new Firebase Auth account
class RegisterPage extends StatefulWidget {
  // Callback function to switch back to login page
  final VoidCallback showLoginPage;
  const RegisterPage({super.key, required this.showLoginPage});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// State class for RegisterPage that manages form inputs and registration logic
class _RegisterPageState extends State<RegisterPage> {
  // Text editing controllers for all form inputs
  // These controllers manage the text field values and user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmpassowrdController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Method to handle user registration using Firebase Auth
  // This method creates a new user account with provided information
  Future signUp() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmpassowrdController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields.'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (passwordConfirmed()) {
      await AuthService().registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
    }
  }

  // Method to validate that password and confirm password match
  // Returns true if passwords match, false otherwise
  bool passwordConfirmed() {
    if (_passwordController.text.trim() == _confirmpassowrdController.text.trim()){
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent screen resize when keyboard appears
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white70,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo displayed at the top of the registration form
                Image.asset(
                  'assets/png/hs_logo.png', 
                  height: 100,
                ),
                SizedBox(height: 20),
                
                // Registration instruction message
                Text(
                  'Register below with your details!',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),

                // First Name input field with custom styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'First Name',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                
                // Last Name input field with custom styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Last Name',
                        ),
                      ),
                    ),
                  ),
                ),

                // Email input field with custom styling
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Email',
                        ),
                      ),
                    ),
                  ),
                ),

                // Password input field with custom styling and obscured text
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: true, // Hide password characters
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Password',
                        ),
                      ),
                    ),
                  ),
                ),

                // Confirm Password input field for password verification
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: _confirmpassowrdController,
                        obscureText: true, // Hide password characters
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Confirm Password',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Sign Up button with brand colors and custom styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: signUp, // Trigger user registration
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 127, 39), // Brand orange color
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Login link for users who already have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'I am a member. ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: widget.showLoginPage, // Switch to login page
                      child: Text(
                        'Login now!',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
