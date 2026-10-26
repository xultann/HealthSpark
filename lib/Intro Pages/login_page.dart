// Import statements for Firebase Auth, Flutter UI components, and authentication service
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:healthspark/Services/auth_service.dart';

// Login page widget that handles user authentication
// This page provides email/password login and Google sign-in options
class LoginPage extends StatefulWidget {
  // Callback function to switch to registration page
  final VoidCallback showRegisterPage;
  const LoginPage({super.key, required this.showRegisterPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// State class for LoginPage that manages form inputs and authentication logic
class _LoginPageState extends State<LoginPage> {
  // Text editing controllers for form inputs
  // These controllers manage the text field values and user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Loading state for authentication process
  bool _isLoading = false;

  // Method to handle email/password sign-in using Firebase Auth
  // This method authenticates the user with provided credentials
  Future signIn() async {
    // Validate email
    if (_emailController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your email address.'), 
            backgroundColor: Colors.red
          ),
        );
      }
      return;
    }
    
    // Validate email format
    if (!_isValidEmail(_emailController.text.trim())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address.'), 
            backgroundColor: Colors.red
          ),
        );
      }
      return;
    }
    
    // Validate password
    if (_passwordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your password.'), 
            backgroundColor: Colors.red
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      // Show user-friendly error message based on Firebase error code
      if (mounted) {
        String errorMessage = _getLoginErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage), 
            backgroundColor: Colors.red
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Helper method to get user-friendly error messages
  String _getLoginErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Login failed. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  // Helper method to get user-friendly Google sign-in error messages
  String _getGoogleSignInErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'invalid-credential':
          return 'Google sign-in failed. Please try again.';
        case 'operation-not-allowed':
          return 'Google sign-in is not enabled. Please contact support.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'user-not-found':
          return 'No account found with this email address.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'popup-closed-by-user':
          return 'Google sign-in was cancelled.';
        default:
          return 'Google sign-in failed. Please try again.';
      }
    }
    return 'Google sign-in failed. Please try again.';
  }

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Prevent screen resize when keyboard appears
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo displayed at the top of the login form
                Image.asset(
                  'assets/png/hs_logo.png', 
                  height: 100,
                ),
                SizedBox(height: 20),
                
                // Welcome message for users
                Text(
                  'Welcome! Proceed to Sign in.',
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),

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
                SizedBox(height: 10),

                // Sign In button with brand colors and custom styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: _isLoading ? null : signIn, // Disable button when loading
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isLoading 
                          ? const Color.fromARGB(255, 255, 127, 39).withOpacity(0.6) // Dimmed when loading
                          : const Color.fromARGB(255, 255, 127, 39), // Brand orange color
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Signing In...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Sign In',
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
                
                // Visual divider with "or" text to separate authentication methods
                Row(
                  children: [
                    Expanded(child: Divider(thickness: 1, indent: 25, endIndent: 10)),
                    Text('or', style: TextStyle(color: Colors.grey)),
                    Expanded(child: Divider(thickness: 1, indent: 10, endIndent: 25)),
                  ],
                ),
                SizedBox(height: 20),
                
                // Google Sign-In button with Google branding and styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: GestureDetector(
                    onTap: _isLoading ? null : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        // Attempt Google sign-in using AuthService from Provider
                        final authService = Provider.of<AuthService>(context, listen: false);
                        await authService.signInWithGoogle();
                      } catch (e) {
                        // Show user-friendly error message for Google sign-in
                        if (mounted) {
                          String errorMessage = _getGoogleSignInErrorMessage(e);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isLoading ? Colors.grey[100] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isLoading)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                              ),
                            )
                          else
                            Image.asset(
                              'assets/png/g_signin.png',
                              height: 28,
                              width: 28,
                            ),
                          SizedBox(width: 12),
                          Text(
                            _isLoading ? 'Signing in...' : 'Sign in with Google', 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              color: _isLoading ? Colors.grey[600] : Colors.black,
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                // Registration link for users who don't have an account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member yet? ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: widget.showRegisterPage, // Switch to registration page
                      child: Text(
                        'Register now!',
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
