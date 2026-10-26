// Import statements for Flutter UI components, Firebase services, and app utilities
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:healthspark/Services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Utils/theme_provider.dart';
import '../Auth/auth_page.dart';

// Profile screen widget that allows users to manage their account settings
// This screen provides functionality for updating profile information, changing passwords,
// uploading profile pictures, and managing account settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// State class for ProfileScreen that manages user profile data and interactions
class _ProfileScreenState extends State<ProfileScreen> {
  // Form key for validation of profile update form
  final _formKey = GlobalKey<FormState>();
  
  // Text editing controllers for form inputs
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Profile picture management
  File? _imageFile; // Selected image file for upload
  bool _isLoading = false; // Loading state indicator
  String _errorMessage = ''; // Error message display
  String _successMessage = ''; // Success message display
  bool _isEditingName = false; // Toggle for name editing mode
  String _displayName = ''; // Current display name

  @override
  void initState() {
    super.initState();
    // Load user data when the screen initializes
    _loadUserData();
  }

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Load user data from Firebase Auth and Firestore
  // This method populates the form fields with current user information
  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      // Load user data from Firestore database
      try {
        final doc = await FirebaseFirestore.instance
            .collection('hsUsers')
            .doc(user.uid)
            .get();
        final data = doc.data();
        if (data != null) {
          // Populate form fields with Firestore data
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          setState(() {
            _displayName =
                ((data['firstName'] ?? '') + ' ' + (data['lastName'] ?? '')).trim();
          });
        } else if (user.displayName != null) {
          // Fallback to Firebase Auth display name if Firestore data is not available
          final parts = user.displayName!.split(' ');
          _firstNameController.text = parts.isNotEmpty ? parts[0] : '';
          _lastNameController.text = parts.length > 1
              ? parts.sublist(1).join(' ')
              : '';
          setState(() {
            _displayName = user.displayName!;
          });
        }
      } catch (e) {
        _showError('Failed to load user data');
        // If Firestore fails, fallback to displayName if available
        if (user.displayName != null) {
          final parts = user.displayName!.split(' ');
          _firstNameController.text = parts.isNotEmpty ? parts[0] : '';
          _lastNameController.text = parts.length > 1
              ? parts.sublist(1).join(' ')
              : '';
          setState(() {
            _displayName = user.displayName!;
          });
        }
      }
    }
  }

  // Display error message to user
  // Shows error in both state and as a snackbar notification
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = '';
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Display success message to user
  // Shows success in both state and as a snackbar notification
  void _showSuccess(String message) {
    setState(() {
      _errorMessage = '';
      _successMessage = message;
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Update user profile information
  // This method handles updating name, email, and profile picture
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Update display name in Firebase Auth
        final displayName =
            '${_firstNameController.text} ${_lastNameController.text}'.trim();
        await authService.updateUserProfile(username: displayName);
        
        // Update user data in Firestore
        await FirebaseFirestore.instance
            .collection('hsUsers')
            .doc(currentUser.uid)
            .update({
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'displayName': displayName,
            });
      }
      
      // Handle email update if changed
      if (_emailController.text != currentUser?.email &&
          _emailController.text.isNotEmpty) {
        await authService.updateUserProfile(email: _emailController.text);
        _showSuccess('Verification email sent to your new email address.');
        return;
      }
      
      // Handle profile picture upload if selected
      if (_imageFile != null && currentUser != null) {
        final url = await authService.uploadProfilePicture(
          currentUser.uid,
          _imageFile!,
        );
        await currentUser.updatePhotoURL(url);
        await FirebaseFirestore.instance
            .collection('hsUsers')
            .doc(currentUser.uid)
            .update({'photoURL': url});
      }
      _showSuccess('Profile updated successfully!');
    } catch (e) {
      _showError('Failed to update profile: ${e.toString()}');
    }
  }

  // Update user password with current password verification
  // This method requires the current password for security
  Future<void> _updatePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('All password fields are required');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError('New passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // Clear password fields after successful update
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      _showSuccess('Password updated successfully!');
    } catch (e) {
      _showError('Failed to update password: ${e.toString()}');
    }
  }

  // Update user's first and last name
  // This method provides a quick way to update just the name fields
  Future<void> _updateName() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final authService = Provider.of<AuthService>(context, listen: false);
      if (currentUser != null) {
        final displayName =
            '${_firstNameController.text} ${_lastNameController.text}'.trim();
        await authService.updateUserProfile(username: displayName);
        await FirebaseFirestore.instance
            .collection('hsUsers')
            .doc(currentUser.uid)
            .update({
              'firstName': _firstNameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'displayName': displayName,
            });
        setState(() {
          _displayName = displayName;
          _isEditingName = false;
        });
        _showSuccess('Name updated successfully!');
      }
    } catch (e) {
      _showError('Failed to update name: ${e.toString()}');
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Pick image from device gallery for profile picture
  // This method opens the image picker and sets the selected image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Check if current user is a Google account
  Future<bool> _isGoogleAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('hsUsers')
            .doc(user.uid)
            .get();
        final data = doc.data();
        return data?['provider'] == 'google';
      } catch (e) {
        // If we can't determine the provider, check if user has password-based auth
        return user.providerData.any((provider) => provider.providerId == 'google.com');
      }
    }
    return false;
  }

  // Delete user account with appropriate confirmation
  // For Google accounts: shows simple confirmation dialog
  // For regular accounts: requires password verification
  Future<void> _deleteAccount({
    required Color bgColor,
    required Color textColor,
    required Color textFieldTextColor,
    required Color orange,
  }) async {
    final isGoogle = await _isGoogleAccount();
    
    if (isGoogle) {
      // For Google accounts, show simple confirmation dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: bgColor,
            title: Text('Delete Account', style: TextStyle(color: textColor)),
            content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: TextStyle(color: textFieldTextColor),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: orange)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performAccountDeletion();
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    } else {
      // For regular accounts, require password confirmation
      showDialog(
        context: context,
        builder: (context) {
          final passwordController = TextEditingController();
          return AlertDialog(
            backgroundColor: bgColor,
            title: Text('Delete Account', style: TextStyle(color: textColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'This action cannot be undone. Please enter your password to confirm.',
                  style: TextStyle(color: textFieldTextColor),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: TextStyle(color: textFieldTextColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: textColor),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: orange)),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  if (passwordController.text.isEmpty) {
                    _showError('Password is required to delete your account');
                    return;
                  }

                  await _performAccountDeletion(password: passwordController.text);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    }
  }

  // Perform the actual account deletion
  Future<void> _performAccountDeletion({String? password}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (password != null) {
        // For regular accounts, use password-based deletion
        await authService.deleteAccount(password);
      } else {
        // For Google accounts, use Google-specific deletion
        await authService.deleteGoogleAccount();
      }

      if (!mounted) return;

      // Navigate to auth screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      _showError('Failed to delete account: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user and theme information
    final User? user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final orange = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = orange;
    final outlineColor = orange;
    final hintColor = Colors.grey;
    final appBarTextColor = Colors.white;
    final displayNameColor = isDark ? orange : Colors.black;
    final textFieldTextColor = isDark ? orange : Colors.black;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: orange,
        title: Text('Profile', style: TextStyle(color: appBarTextColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final avatarRadius = width * 0.18;
          final padding = width * 0.04;
          final displayNameFontSize = width * 0.055;
          
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture section with edit functionality
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: orange.withOpacity(0.2),
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (user?.photoURL != null
                                        ? NetworkImage(user!.photoURL!)
                                        : null)
                                    as ImageProvider?,
                          child: _imageFile == null && (user?.photoURL == null)
                              ? Icon(
                                  Icons.person,
                                  size: avatarRadius,
                                  color: orange,
                                )
                              : null,
                        ),
                        // Edit icon overlay on profile picture
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: orange,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(avatarRadius * 0.18),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: avatarRadius * 0.33,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  
                  // Display name section
                  Text(
                    _displayName.isNotEmpty ? _displayName : 'No name set',
                    style: TextStyle(
                      fontSize: displayNameFontSize,
                      fontWeight: FontWeight.bold,
                      color: displayNameColor,
                    ),
                  ),
                  SizedBox(height: height * 0.01),
                  
                  // Name editing section with toggle functionality
                  !_isEditingName
                      ? _ProfileActionButton(
                          label: 'Change Name',
                          onTap: () {
                            setState(() {
                              _isEditingName = true;
                            });
                          },
                          color: orange,
                        )
                      : Column(
                          children: [
                            // First name input field
                            TextFormField(
                              controller: _firstNameController,
                              style: TextStyle(color: textFieldTextColor),
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: TextStyle(color: textColor),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: outlineColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: outlineColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: outlineColor, width: 2),
                                ),
                                hintStyle: TextStyle(color: hintColor),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            // Last name input field
                            TextFormField(
                              controller: _lastNameController,
                              style: TextStyle(color: textFieldTextColor),
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: TextStyle(color: textColor),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: outlineColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: outlineColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: outlineColor, width: 2),
                                ),
                                hintStyle: TextStyle(color: hintColor),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            // Update and cancel buttons for name editing
                            Row(
                              children: [
                                Expanded(
                                  child: _ProfileActionButton(
                                    label: 'Update',
                                    onTap: _updateName,
                                    color: orange,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ProfileActionButton(
                                    label: 'Cancel',
                                    onTap: () {
                                      setState(() {
                                        _isEditingName = false;
                                      });
                                    },
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  
                  // Email input field
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: textFieldTextColor),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: outlineColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: outlineColor, width: 2),
                      ),
                      hintStyle: TextStyle(color: hintColor),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons for profile management
                  _ProfileActionButton(
                    label: 'Update Profile',
                    onTap: _updateProfile,
                    color: orange,
                  ),
                  const SizedBox(height: 16),
                  
                  // Change password button with dialog
                  _ProfileActionButton(
                    label: 'Change Password',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: bgColor,
                          title: Text('Change Password', style: TextStyle(color: textColor)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Current password field
                              TextField(
                                controller: _currentPasswordController,
                                obscureText: true,
                                style: TextStyle(color: textFieldTextColor),
                                decoration: InputDecoration(
                                  labelText: 'Current Password',
                                  labelStyle: TextStyle(color: textColor),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor, width: 2),
                                  ),
                                  hintStyle: TextStyle(color: hintColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // New password field
                              TextField(
                                controller: _newPasswordController,
                                obscureText: true,
                                style: TextStyle(color: textFieldTextColor),
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  labelStyle: TextStyle(color: textColor),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor, width: 2),
                                  ),
                                  hintStyle: TextStyle(color: hintColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Confirm new password field
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: TextStyle(color: textFieldTextColor),
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password',
                                  labelStyle: TextStyle(color: textColor),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: outlineColor, width: 2),
                                  ),
                                  hintStyle: TextStyle(color: hintColor),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cancel', style: TextStyle(color: orange)),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _updatePassword();
                              },
                              child: Text('Update', style: TextStyle(color: orange)),
                            ),
                          ],
                        ),
                      );
                    },
                    color: orange,
                  ),
                  const SizedBox(height: 16),
                  
                  // Sign out button
                  _ProfileActionButton(
                    label: 'Sign Out',
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        // Navigate to auth page and clear all previous routes
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const AuthPage(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    color: orange,
                  ),
                  const SizedBox(height: 16),
                  
                  // Delete account button
                  _ProfileActionButton(
                    label: 'Delete Account',
                    onTap: () => _deleteAccount(
                      bgColor: bgColor ?? Colors.white,
                      textColor: textColor,
                      textFieldTextColor: textFieldTextColor,
                      orange: orange,
                    ),
                    color: Colors.redAccent,
                  ),
                  
                  // Loading indicator
                  if (_isLoading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                  
                  // Error message display
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  ],
                  
                  // Success message display
                  if (_successMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _successMessage,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom widget for profile action buttons
// Provides consistent styling for all action buttons in the profile screen
class _ProfileActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  
  const _ProfileActionButton({
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: MaterialButton(
        color: color ?? const Color.fromARGB(255, 255, 127, 39),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
