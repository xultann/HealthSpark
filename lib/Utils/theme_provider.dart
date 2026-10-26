// Import statements for Flutter UI components and shared preferences
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme provider class that manages dark/light mode state throughout the app
// This class extends ChangeNotifier to notify widgets when theme changes
class ThemeProvider extends ChangeNotifier {
  // Private boolean variable to track current theme state
  // false = light mode, true = dark mode
  bool _isDarkMode = false;

  // Getter method to access the current theme state
  // Returns true if dark mode is enabled, false otherwise
  bool get isDarkMode => _isDarkMode;

  // Constructor that initializes the theme provider
  // Automatically loads the saved theme preference when created
  ThemeProvider() {
    _loadTheme();
  }

  // Private method to load the saved theme preference from device storage
  // This method is called during initialization to restore user's theme choice
  Future<void> _loadTheme() async {
    // Get shared preferences instance to access stored settings
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Load the saved theme preference, default to light mode (false) if not found
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    // Notify all listening widgets about the theme change
    notifyListeners();
  }

  // Public method to toggle between dark and light themes
  // This method is called when user switches theme in the app
  Future<void> toggleTheme() async {
    // Get shared preferences instance to save the new theme preference
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Toggle the theme state (true becomes false, false becomes true)
    _isDarkMode = !_isDarkMode;
    // Save the new theme preference to device storage for persistence
    await prefs.setBool('isDarkMode', _isDarkMode);
    // Notify all listening widgets about the theme change
    notifyListeners();
  }
}