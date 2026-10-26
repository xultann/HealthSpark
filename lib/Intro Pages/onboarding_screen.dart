// Import statements for Flutter UI components, introduction screen package, and shared preferences
import 'package:flutter/material.dart';
import 'package:healthspark/Auth/main_page.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Onboarding screen that introduces new users to the HealthSpark app
// This screen shows multiple pages explaining app features before directing to login
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  // Main brand color used throughout the app (orange theme)
  final Color mainColor = const Color.fromARGB(255, 255, 127, 39);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image that covers the entire screen
        // This provides a visual backdrop for the onboarding content
        Positioned.fill(
          child: Opacity(
            opacity: 0.9, // Reduced opacity to make background less prominent
            child: Image.asset(
              'assets/backgrounds/boardingBG.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Semi-transparent overlay to reduce background opacity and improve text readability
        Positioned.fill(
          child: Container(
            color: Colors.transparent.withOpacity(0.1),
          ),
        ),
        // Introduction screen widget that handles page navigation and transitions
        IntroductionScreen(
          // Transparent background to show the PNG background image
          globalBackgroundColor: Colors.transparent,
          // Array of pages that will be shown during onboarding
          pages: [
            // Page 1: Welcome and app introduction
            PageViewModel(
              title: "Welcome to HealthSpark",
              body:
                  "Your personal health companion that helps you identify health issues early and provides reliable health information.",
              image: Padding(
                padding: const EdgeInsets.only(top: 200.0),
                child: Image.asset(
                  'assets/png/hs_logo.png',
                  height: 300, // Custom size for logo
                  width: 300, // Maintain aspect ratio
                ),
              ),
              decoration: _getPageDecoration(),
            ),
            // Page 2: Health monitoring features
            PageViewModel(
              title: "Monitor Your Health",
              body:
                  "Track symptoms, get personalized health recommendations, and access reliable medical information all in one place.",
              image: _buildImage('assets/opener/OPic1.png'),
              decoration: _getPageDecoration(),
            ),
            // Page 3: Healthcare connectivity features
            PageViewModel(
              title: "Connect with Healthcare",
              body:
                  "Find nearby hospitals, get emergency contacts, and receive reminders for medications and checkups.",
              image: _buildImage('assets/opener/OPic2.png'),
              decoration: _getPageDecoration(),
            ),
            // Page 4: Lifestyle improvement benefits
            PageViewModel(
              title: "Spark with Strength",
              body:
                  "Enjoy a better lifestyle and be one of the many healthy people in the most efficient way.",
              image: _buildImage('assets/opener/OPic3.png'),
              decoration: _getPageDecoration(),
            ),
          ],
          // Callback when user completes onboarding (clicks Done)
          onDone: () => _onIntroEnd(context),
          // Callback when user skips onboarding (clicks Skip)
          onSkip: () => _onIntroEnd(context),
          // Show skip button to allow users to bypass onboarding
          showSkipButton: true,
          // Custom styled buttons for navigation
          skip: _styledButton("Skip"),
          next: _styledButton("Next"),
          done: _styledButton("Done"),
          // Custom dot indicators showing current page position
          dotsDecorator: DotsDecorator(
            size: const Size.square(10.0),
            activeSize: const Size(22.0, 10.0),
            activeColor: mainColor,
            color: Colors.black26,
            spacing: const EdgeInsets.symmetric(horizontal: 4.0),
            activeShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          // Padding for control buttons (Skip, Next, Done)
          controlsPadding: const EdgeInsets.only(top: 16.0, bottom: 60.0), // Increased bottom padding to lift controls up
        ),
      ],
    );
  }

  // Helper method to create styled navigation buttons
  // Returns a container with rounded corners and brand colors
  Widget _styledButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 127, 39),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // Method called when onboarding is completed or skipped
  // Saves the onboarding completion status and navigates to main page
  void _onIntroEnd(BuildContext context) async {
    // Get shared preferences instance to save onboarding status
    final prefs = await SharedPreferences.getInstance();
    // Mark onboarding as seen so it won't show again
    await prefs.setBool('onboarding_seen', true);

    // Check if context is still valid before navigation
    if (context.mounted) {
      // Navigate to main page and clear the stack
      // MainPage will automatically handle authentication state
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
      );
    }
  }

  // Helper method to build and style images for onboarding pages
  // Adds padding and sets consistent height for all images
  Widget _buildImage(String assetName) {
    return Padding(
      padding: const EdgeInsets.only(top: 100.0), // Reduced top padding to bring image closer to text
      child: Image.asset(assetName, height: 270), // Reduced height to bring image and text closer
    );
  }

  // Helper method to define consistent page decoration/styling
  // Sets text styles, background color, and image padding for all pages
  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.black),
      bodyTextStyle: TextStyle(fontSize: 18.0, color: Colors.black, height: 1.5),
      pageColor: Colors.transparent,
      imagePadding: EdgeInsets.zero,
    );
  }
}
