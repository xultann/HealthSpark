// Import statements for Firebase services, Flutter UI components, and app pages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthspark/Main%20Pages/profile_page.dart';
import 'package:healthspark/Main%20Pages/healthmonitor_page.dart';
import 'package:provider/provider.dart';
import 'package:healthspark/Utils/theme_provider.dart';
import 'package:healthspark/Main%20Pages/nearby_hospitals_screen.dart';
import 'package:healthspark/Main%20Pages/symptom_tracker_screen.dart';
import 'package:healthspark/Main%20Pages/medical_info_screen.dart';
import 'package:healthspark/Main Pages/add_medical_info_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthspark/Utils/pdf_exporter.dart';

// Main home page widget that serves as the central navigation hub
// This widget manages the bottom navigation bar and displays different app sections
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State class for HomePage that manages navigation and dashboard functionality
class _HomePageState extends State<HomePage> {
  // Current authenticated user from Firebase Auth
  final user = FirebaseAuth.instance.currentUser!;
  // Index of the currently selected tab in bottom navigation
  int _selectedIndex = 0;

  // Dashboard page widget that displays user's health data and recommendations
  // This is the main landing page when the app opens
  Widget _dashboardPage(BuildContext context) {
    // Get theme provider to handle dark/light mode
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final orange =
        (isDark ? Colors.deepOrange[700] : const Color(0xFFFF7F27)) ??
        Colors.deepOrange;
    final userId = user.uid;
    final firstName = user.displayName?.split(' ').first ?? 'User';

    // Fetch user's health profile data from Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('health_profiles')
          .doc(userId)
          .get(),
      builder: (context, snapshot) {
        // Show loading indicator while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: orange));
        }

        // Check if health data exists
        final hasHealthData = snapshot.hasData && snapshot.data!.exists;

        // If no health data exists, show a message but still allow symptom results to display
        if (!hasHealthData) {
          // We'll handle this in the main content area instead of returning early
        }

        // Extract health data from Firestore document (if exists)
        Map<String, dynamic>? data;
        String age = '-';
        String weight = '-';
        String bloodSugar = '-';
        String activityLevel = '-';
        Map<String, dynamic>? recommendations;

        if (hasHealthData) {
          data = snapshot.data!.data() as Map<String, dynamic>;
          age = data['age']?.toString() ?? '-';
          weight = data['weight']?.toString() ?? '-';
          bloodSugar = data['bloodSugar']?.toString() ?? '-';
          activityLevel = data['activityLevel']?.toString() ?? '-';
          recommendations = data['recommendations'] as Map<String, dynamic>?;
        }

        // Fetch symptom assessment results as a separate future
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('symptoms_result')
              .doc(userId)
              .get(),
          builder: (context, symptomSnapshot) {
            final width = MediaQuery.of(context).size.width;
            final verticalSpacing = width * 0.03;

            // Build list of widgets for the dashboard
            List<Widget> children = [SizedBox(height: verticalSpacing)];

            // Only show health recommendations if user has completed health assessment
            if (hasHealthData) {
              children.addAll([
                // Health recommendations section title
                Text(
                  "$firstName's Health Recommendation",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: orange,
                  ),
                ),
                SizedBox(height: 5),
                // Health summary card with key metrics
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: orange, width: 2),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _summaryItem('Age', age, orange, isDark),
                        _summaryItem('Weight', weight, orange, isDark),
                        _summaryItem('Blood Sugar', bloodSugar, orange, isDark),
                        _summaryItem('Activity', activityLevel, orange, isDark),
                      ],
                    ),
                  ),
                ),
                // "More" button to show detailed recommendations
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Show detailed recommendations in a bottom sheet
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return DraggableScrollableSheet(
                            initialChildSize: 0.9,
                            minChildSize: 0.5,
                            maxChildSize: 0.9,
                            expand: false,
                            builder: (context, scrollController) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: ListView(
                                  controller: scrollController,
                                  children: [
                                    Text(
                                      "$firstName's Full Health Recommendations",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    ..._buildFullRecommendations(
                                      recommendations,
                                      isDark,
                                      orange,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: Text(
                      'More >>',
                      style: TextStyle(
                        color: orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ]);
            } else {
              // Show message to complete health assessment
              children.addAll([
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: orange, width: 2),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.monitor_heart, size: 40, color: orange),
                        SizedBox(height: 10),
                        Text(
                          'Complete Health Assessment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: orange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Get personalized health recommendations by completing your health profile.',
                          style: TextStyle(
                            color: isDark
                                ? Colors.deepOrange[200]
                                : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to Health Monitor page (index 1)
                            setState(() {
                              _selectedIndex = 1;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Start Health Assessment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ]);
            }

            // Add spacing between sections if both exist
            if (hasHealthData &&
                symptomSnapshot.hasData &&
                symptomSnapshot.data!.exists) {
              children.add(SizedBox(height: verticalSpacing));
            }

            // Add symptom result section if available
            if (symptomSnapshot.hasData && symptomSnapshot.data!.exists) {
              final symptomData =
                  symptomSnapshot.data!.data() as Map<String, dynamic>;
              final symptom = symptomData['symptom'] ?? '-';
              final definition = symptomData['definition'] ?? '';
              children.addAll([
                SizedBox(height: verticalSpacing),
                // Symptom result section title
                Text(
                  "$firstName's Symptom Result",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: orange,
                  ),
                ),
                SizedBox(height: 5),
                // Symptom result card
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: orange, width: 2),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symptom,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: orange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          definition,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.deepOrange[200]
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: 16),
                        // Retake quiz button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to Symptom Tracker page (index 2)
                              setState(() {
                                _selectedIndex = 2;
                              });
                            },
                            child: Text(
                              'Retake Quiz >>',
                              style: TextStyle(
                                color: orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]);
            } else {
              // Show message to complete symptom assessment
              children.addAll([
                SizedBox(height: verticalSpacing),
                Card(
                  color: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: orange, width: 2),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.healing, size: 40, color: orange),
                        SizedBox(height: 10),
                        Text(
                          'Complete Symptom Assessment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: orange,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Get symptom analysis and health insights by taking the symptom assessment.',
                          style: TextStyle(
                            color: isDark
                                ? Colors.deepOrange[200]
                                : Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to Symptom Tracker page (index 2)
                            setState(() {
                              _selectedIndex = 2;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Start Symptom Assessment'),
                        ),
                      ],
                    ),
                  ),
                ),
              ]);
            }

            // Return scrollable dashboard content
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to create summary items for health metrics
  // Displays a label and value in a column format
  Widget _summaryItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.deepOrange[200] : Colors.black,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Helper method to build full health recommendations list
  // Converts recommendation data into styled card widgets
  List<Widget> _buildFullRecommendations(
    Map<String, dynamic>? recs,
    bool isDark,
    Color orange,
  ) {
    if (recs == null) {
      return [
        Text('No recommendations available.', style: TextStyle(color: orange)),
      ];
    }
    final List<Widget> widgets = [];
    recs.forEach((key, value) {
      widgets.add(
        Card(
          color: isDark ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: orange, width: 2),
          ),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key[0].toUpperCase() + key.substring(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: orange,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                if (value is Map<String, dynamic>)
                  ...value.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        "${e.key[0].toUpperCase() + e.key.substring(1)}: ${e.value}",
                        style: TextStyle(
                          color: isDark ? Colors.deepOrange[200] : Colors.black,
                        ),
                      ),
                    ),
                  ),
                if (value is String)
                  Text(
                    value,
                    style: TextStyle(
                      color: isDark ? Colors.deepOrange[200] : Colors.black,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
    return widgets;
  }

  // List of all app pages/screens accessible through bottom navigation
  List<Widget> get _pages => <Widget>[
    _dashboardPage(context), // Dashboard (index 0)
    const HealthMonitorScreen(), // Health Monitor (index 1)
    const SymptomTrackerScreen(), // Symptom Tracker (index 2)
    const NearbyHospitalsScreen(), // Nearby Hospitals (index 3)
    const MedicalInfoScreen(), // Medical Info (index 4)
  ];

  // List of page titles for the app bar
  final List<String> _titles = [
    'Dashboard',
    'Health Monitor',
    'Symptom Tracker',
    'Nearby Hospitals',
    'Medical Info',
  ];

  // Method to handle bottom navigation tab changes
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider for dark/light mode support
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final themeColor = isDark ? Colors.grey[900] : Colors.white;
    final appBarColor = isDark
        ? Colors.deepOrange[700]
        : const Color.fromARGB(255, 255, 127, 39);
    final iconColor = isDark ? Colors.white : Colors.white;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      // Prevent screen resize when keyboard appears
      resizeToAvoidBottomInset: false,
      backgroundColor: themeColor,
      // App bar with title, menu button, and profile button
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // Menu button that opens the drawer
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: iconColor, size: 32),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        // Profile button that navigates to profile page
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: iconColor, size: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      // Side drawer with additional options and settings
      drawer: Drawer(
        child: Container(
          color: themeColor,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme toggle switch
                ListTile(
                  leading: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: appBarColor,
                  ),
                  title: Text(
                    'Theme',
                    style: TextStyle(
                      color: appBarColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Switch(
                    value: isDark,
                    activeColor: appBarColor,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                ),
                // Add Medical Info button
                ListTile(
                  leading: Icon(Icons.add, color: appBarColor),
                  title: Text(
                    'Add Medical Info',
                    style: TextStyle(
                      color: appBarColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddMedicalInfoScreen(),
                      ),
                    );
                  },
                ),
                // Export PDF button for health recommendations
                ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: appBarColor),
                  title: Text(
                    'Export Health Recommendations',
                    style: TextStyle(
                      color: appBarColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await exportHealthRecommendationsAsPdf(context);
                  },
                ),
                // Add more menu options here if needed
                // Example:
                // ListTile(
                //   leading: Icon(Icons.settings, color: appBarColor),
                //   title: Text('Settings', style: TextStyle(color: appBarColor)),
                //   onTap: () {},
                // ),
              ],
            ),
          ),
        ),
      ),
      // Main content area that displays the selected page
      body: _pages[_selectedIndex],
      // Bottom navigation bar with app sections
      bottomNavigationBar: isKeyboardOpen
          ? null // Hide bottom navigation when keyboard is open
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              iconSize: 32,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.monitor_heart),
                  label: 'Health Monitor',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.healing),
                  label: 'Symptom Tracker',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_hospital),
                  label: 'Nearby Hospitals',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'Medical Info',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: appBarColor,
              unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
              backgroundColor: themeColor,
              onTap: _onItemTapped,
              showSelectedLabels: false,
              showUnselectedLabels: false,
            ),
    );
  }
}
