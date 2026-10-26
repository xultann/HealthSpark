// Import statements for Firebase services and file handling
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// Authentication service class that handles all user authentication operations
// This class provides methods for sign-in, sign-up, profile management, and account operations
class AuthService {
  // Firebase Auth instance for handling authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign out the current user from Firebase Auth
  // This will clear the user session and return to login screen
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update user's display name or email in Firebase Auth
  // This method allows users to change their profile information
  Future<void> updateUserProfile({String? username, String? email}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Update display name if provided and different from current
      if (username != null && username != user.displayName) {
        await user.updateDisplayName(username);
      }
      // Update email if provided and different from current
      // This requires email verification before the change takes effect
      if (email != null && email != user.email) {
        await user.verifyBeforeUpdateEmail(email);
      }
      // Reload user data to reflect changes
      await user.reload();
    }
  }

  // Update user's password with current password verification
  // This method requires re-authentication for security
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      // Create credential with current email and password for re-authentication
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Re-authenticate user before allowing password change
      await user.reauthenticateWithCredential(credential);
      // Update to new password
      await user.updatePassword(newPassword);
    } else {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }
  }

  // Delete user account permanently
  // This requires password verification and will remove all user data
  Future<void> deleteAccount(String password) async {
    User? user = _auth.currentUser;
    if (user != null && user.email != null) {
      // Create credential for re-authentication
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Re-authenticate user before account deletion
      await user.reauthenticateWithCredential(credential);
      // Permanently delete the user account
      await user.delete();
    } else {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }
  }

  // Delete Google account permanently
  // This method handles Google account deletion without password requirement
  Future<void> deleteGoogleAccount() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // For Google accounts, we need to re-authenticate using Google
      // Get the current Google sign-in instance
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Check if user is signed in with Google
      if (await googleSignIn.isSignedIn()) {
        // Re-authenticate with Google
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          
          // Re-authenticate user with Google credential
          await user.reauthenticateWithCredential(credential);
          
          // Delete user data from Firestore first
          await FirebaseFirestore.instance
              .collection('hsUsers')
              .doc(user.uid)
              .delete();
          
          // Permanently delete the user account
          await user.delete();
          
          // Sign out from Google
          await googleSignIn.signOut();
        } else {
          throw FirebaseAuthException(
            code: 'google-signin-cancelled',
            message: 'Google sign-in was cancelled.',
          );
        }
      } else {
        // If not signed in with Google, try to delete directly
        // This might work if the user was recently authenticated
        try {
          // Delete user data from Firestore first
          await FirebaseFirestore.instance
              .collection('hsUsers')
              .doc(user.uid)
              .delete();
          
          // Permanently delete the user account
          await user.delete();
        } catch (e) {
          throw FirebaseAuthException(
            code: 'reauthentication-required',
            message: 'Re-authentication is required to delete your account. Please sign in again.',
          );
        }
      }
    } else {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No user is currently signed in.',
      );
    }
  }

  // Sign in with Google account using Google Sign-In SDK
  // This method handles the OAuth flow for Google authentication
  Future<User?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    // Trigger Google Sign-In flow
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    
    // Get authentication tokens from Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    // Create Firebase credential from Google tokens
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    
    // Sign in to Firebase with Google credential
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;
    
    if (user != null) {
      // Parse first and last name from Google display name
      String firstName = '';
      String lastName = '';
      if (user.displayName != null) {
        final parts = user.displayName!.split(' ');
        firstName = parts.isNotEmpty ? parts[0] : '';
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      // Save user information to Firestore database
      await _saveUserToFirestore(user, isGoogle: true, firstName: firstName, lastName: lastName);
    }
    return user;
  }

  // Save user information to Firestore database
  // This method stores user profile data for app functionality
  Future<void> _saveUserToFirestore(
    User user, {
    bool isGoogle = false,
    String? firstName,
    String? lastName,
  }) async {
    // Reference to the users collection in Firestore
    final usersRef = FirebaseFirestore.instance.collection('hsUsers');
    final doc = usersRef.doc(user.uid);
    
    // Determine display name based on authentication method
    final displayName = isGoogle
        ? user.displayName
        : (firstName != null && lastName != null
              ? '$firstName $lastName'
              : user.displayName);
    
    // Save user data to Firestore with merge option to update existing records
    await doc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'photoURL': user.photoURL ?? '',
      'provider': isGoogle ? 'google' : 'email',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Register new user with email and password
  // This method creates a new Firebase Auth account and saves user data
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // Create new user account in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCredential.user;
    
    if (user != null) {
      // Update display name with full name
      await user.updateDisplayName('$firstName $lastName');
      // Save user information to Firestore
      await _saveUserToFirestore(
        user,
        firstName: firstName,
        lastName: lastName,
      );
    }
  }

  // Upload profile picture to Firebase Storage
  // This method handles image upload and updates user profile
  Future<String?> uploadProfilePicture(String uid, File imageFile) async {
    // Create reference to storage location for user's profile picture
    final ref = FirebaseStorage.instance.ref().child(
      'profile_pictures/$uid.jpg',
    );
    
    // Upload the image file to Firebase Storage
    await ref.putFile(imageFile);
    // Get the download URL for the uploaded image
    final url = await ref.getDownloadURL();
    
    // Update user document in Firestore with new profile picture URL
    await FirebaseFirestore.instance.collection('hsUsers').doc(uid).update({
      'photoURL': url,
    });
    return url;
  }

  // Update user's first and last name
  // This method updates both Firebase Auth and Firestore
  Future<void> updateUserName(
    String uid,
    String firstName,
    String lastName,
  ) async {
    // Create full display name
    final displayName = '$firstName $lastName';
    // Update display name in Firebase Auth
    await _auth.currentUser!.updateDisplayName(displayName);

    // Update user information in Firestore database
    await FirebaseFirestore.instance.collection('hsUsers').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
      'displayName': displayName,
    });
  }
}
