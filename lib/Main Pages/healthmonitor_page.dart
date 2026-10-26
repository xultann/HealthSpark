// Import statements for Flutter UI components, Firebase services, and app utilities
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Widgets/health_result_card.dart';
import '../Utils/health_recommendations.dart';
import '../Utils/theme_provider.dart';
import 'package:provider/provider.dart';

// Health monitor screen that collects user health data and provides personalized recommendations
// This screen allows users to input their health metrics and lifestyle information
// to receive customized health advice and recommendations
class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});

  @override
  State<HealthMonitorScreen> createState() => _HealthMonitorScreenState();
}

// State class for HealthMonitorScreen that manages health data collection and analysis
class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  // Form validation key
  final _formKey = GlobalKey<FormState>();
  
  // Loading and state management
  bool _isLoading = false; // Loading state indicator
  bool _hasSubmittedForm = false; // Whether user has completed the health questionnaire

  // Text editing controllers for form inputs
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  
  // Dropdown selection variables for lifestyle and health factors
  String? _gender;
  String? _activityLevel;
  String? _medicalConditions;
  String? _sleepQuality;
  String? _stressLevel;
  String? _diet;
  String? _workStatus;

  // Generated health recommendations data
  Map<String, dynamic> _resultData = {};

  @override
  void initState() {
    super.initState();
    // Check if user has existing health data when screen loads
    _checkExistingData();
  }

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bloodSugarController.dispose();
    super.dispose();
  }

  // Check if user has already submitted health data
  // This method loads existing data from Firestore and populates the form
  Future<void> _checkExistingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Fetch user's health profile from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('health_profiles')
            .doc(userId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;

          // Populate form fields with existing data
          setState(() {
            _ageController.text = data['age']?.toString() ?? '';
            _heightController.text = data['height']?.toString() ?? '';
            _weightController.text = data['weight']?.toString() ?? '';
            _bloodSugarController.text = data['bloodSugar']?.toString() ?? '';
            _gender = data['gender'];
            _activityLevel = data['activityLevel'];
            _medicalConditions = data['medicalConditions'];
            _sleepQuality = data['sleepQuality'];
            _stressLevel = data['stressLevel'];
            _diet = data['diet'];
            _workStatus = data['workStatus'];

            _hasSubmittedForm = true;
            _resultData = data['recommendations'] ?? {};
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Submit the health questionnaire and generate personalized recommendations
  // This method validates form data, generates recommendations, and saves to Firestore
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if all required fields are completed
    final missingFields = <String>[];
    
    // Check required text fields
    if (_ageController.text.trim().isEmpty) {
      missingFields.add('Age');
    }
    if (_heightController.text.trim().isEmpty) {
      missingFields.add('Height');
    }
    if (_weightController.text.trim().isEmpty) {
      missingFields.add('Weight');
    }
    if (_bloodSugarController.text.trim().isEmpty) {
      missingFields.add('Blood Sugar');
    }
    
    // Check required dropdown fields
    if (_gender == null || _gender!.isEmpty) {
      missingFields.add('Gender');
    }
    if (_activityLevel == null || _activityLevel!.isEmpty) {
      missingFields.add('Activity Level');
    }
    if (_sleepQuality == null || _sleepQuality!.isEmpty) {
      missingFields.add('Sleep Quality');
    }
    if (_stressLevel == null || _stressLevel!.isEmpty) {
      missingFields.add('Stress Level');
    }
    if (_diet == null || _diet!.isEmpty) {
      missingFields.add('Diet Quality');
    }
    if (_workStatus == null || _workStatus!.isEmpty) {
      missingFields.add('Work Status');
    }
    
    // Show error message if any required fields are missing
    if (missingFields.isNotEmpty) {
      final fieldNames = missingFields.join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please complete all required fields: $fieldNames',
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      return; // Exit early without proceeding
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Parse form data to appropriate data types
      final age = int.parse(_ageController.text);
      final height = double.parse(_heightController.text);
      final weight = double.parse(_weightController.text);
      final bloodSugar = double.parse(_bloodSugarController.text);

      // Generate personalized health recommendations based on user inputs
      final recommendations = generateHealthRecommendations(
        age: age,
        height: height,
        weight: weight,
        bloodSugar: bloodSugar,
        gender: _gender,
        activityLevel: _activityLevel,
        medicalConditions: _medicalConditions,
        sleepQuality: _sleepQuality,
        stressLevel: _stressLevel,
        diet: _diet,
        workStatus: _workStatus,
      );

      // Save complete health profile to Firestore database
      await FirebaseFirestore.instance
          .collection('health_profiles')
          .doc(userId)
          .set({
            'age': age,
            'height': height,
            'weight': weight,
            'bloodSugar': bloodSugar,
            'gender': _gender,
            'activityLevel': _activityLevel,
            'medicalConditions': _medicalConditions,
            'sleepQuality': _sleepQuality,
            'stressLevel': _stressLevel,
            'diet': _diet,
            'workStatus': _workStatus,
            'recommendations': recommendations,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _hasSubmittedForm = true;
        _resultData = recommendations;
      });

      // Show success message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Health profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message if submission fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get theme information for consistent styling
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final orange = isDark
        ? (Colors.deepOrange[700] ?? Colors.deepOrange)
        : const Color(0xFFFF7F27);
    
    // Return only the body content, not a Scaffold
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: orange));
    } else if (_hasSubmittedForm) {
      return _buildResultsView();
    } else {
      return _buildFormView(orange, isDark);
    }
  }

  // Build the health questionnaire form view
  // This view contains all the input fields for collecting user health data
  Widget _buildFormView(Color orange, bool isDark) {
    final greyText = isDark ? Colors.grey[300] : Colors.black;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final padding = width * 0.04;
        final headingFontSize = width * 0.06;
        final labelFontSize = width * 0.045;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form title and description
                Text(
                  'Health Questionnaire',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: orange,
                    fontSize: headingFontSize,
                  ),
                ),
                SizedBox(height: height * 0.01),
                Text(
                  'Please fill out this form to get personalized health recommendations.',
                  style: TextStyle(
                    color: greyText,
                    fontSize: labelFontSize,
                  ),
                ),
                SizedBox(height: height * 0.03),

                // Age input field
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(color: orange),
                    hintText: 'Enter your age',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    final age = int.parse(value);
                    if (age < 1 || age > 120) {
                      return 'Age must be between 1 and 120 years';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Gender selection dropdown
                DropdownButtonFormField<String>(
                  value: _gender,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  dropdownColor: isDark
                      ? Colors.grey[850]
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  items:
                      <String>[
                        'Male',
                        'Female',
                        'Non-binary',
                        'Prefer not to say',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isDark
                                  ? (Colors.deepOrange[700] ??
                                        Colors.deepOrange)
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _gender = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Height input field (in centimeters)
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    labelStyle: TextStyle(color: orange),
                    hintText: 'Enter your height in centimeters',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your height';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    final height = double.parse(value);
                    if (height < 50 || height > 300) {
                      return 'Height must be between 50 and 300 cm';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Weight input field (in kilograms)
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Weight (kg)',
                    labelStyle: TextStyle(color: orange),
                    hintText: 'Enter your weight in kilograms',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your weight';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    final weight = double.parse(value);
                    if (weight < 20 || weight > 500) {
                      return 'Weight must be between 20 and 500 kg';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Blood sugar input field (in mg/dL)
                TextFormField(
                  controller: _bloodSugarController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Blood Sugar (mg/dL)',
                    labelStyle: TextStyle(color: orange),
                    hintText: 'Enter your blood sugar level',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your blood sugar level';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    final bloodSugar = double.parse(value);
                    if (bloodSugar < 20 || bloodSugar > 800) {
                      return 'Blood sugar must be between 20 and 800 mg/dL';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Activity level selection dropdown
                DropdownButtonFormField<String>(
                  value: _activityLevel,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  dropdownColor: isDark
                      ? Colors.grey[850]
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Activity Level',
                    labelStyle: TextStyle(color: orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  items:
                      <String>[
                        'Sedentary',
                        'Light activity',
                        'Moderate activity',
                        'Very active',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isDark
                                  ? (Colors.deepOrange[700] ??
                                        Colors.deepOrange)
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _activityLevel = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your activity level';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Medical conditions selection dropdown
                DropdownButtonFormField<String>(
                  value: _medicalConditions,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  dropdownColor: isDark
                      ? Colors.grey[850]
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Existing Medical Conditions',
                    labelStyle: TextStyle(color: orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  items:
                      <String>[
                        'None',
                        'Diabetes',
                        'Hypertension',
                        'Heart disease',
                        'Asthma',
                        'Arthritis',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isDark
                                  ? (Colors.deepOrange[700] ??
                                        Colors.deepOrange)
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _medicalConditions = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your medical condition';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Sleep quality selection dropdown
                DropdownButtonFormField<String>(
                  value: _sleepQuality,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  dropdownColor: isDark
                      ? Colors.grey[850]
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Sleep Quality',
                    labelStyle: TextStyle(color: orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  items: <String>['Poor', 'Fair', 'Good', 'Excellent']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isDark
                                  ? (Colors.deepOrange[700] ??
                                        Colors.deepOrange)
                                  : Colors.black,
                            ),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _sleepQuality = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your sleep quality';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Stress level selection dropdown
                DropdownButtonFormField<String>(
                  value: _stressLevel,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  dropdownColor: isDark
                      ? Colors.grey[850]
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Stress Level',
                    labelStyle: TextStyle(color: orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  items: <String>['Low', 'Moderate', 'High', 'Severe']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isDark
                                  ? (Colors.deepOrange[700] ??
                                        Colors.deepOrange)
                                  : Colors.black,
                            ),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _stressLevel = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your stress level';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Diet quality selection dropdown
                DropdownButtonFormField<String>(
                  value: _diet,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  dropdownColor: isDark
                      ? Colors.grey[850]
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Diet Quality',
                    labelStyle: TextStyle(color: orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  items: <String>['Poor', 'Fair', 'Good', 'Excellent']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isDark
                                  ? (Colors.deepOrange[700] ??
                                        Colors.deepOrange)
                                  : Colors.black,
                            ),
                          ),
                        );
                      })
                      .toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _diet = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your diet quality';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.02),

                // Work status selection dropdown
                DropdownButtonFormField<String>(
                  value: _workStatus,
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.black,
                  ),
                  dropdownColor: isDark
                      ? Colors.grey[850]
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Work Status',
                    labelStyle: TextStyle(color: orange),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: orange, width: 2),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: orange),
                    ),
                  ),
                  items:
                      <String>[
                        'Full-time sedentary',
                        'Full-time active',
                        'Part-time',
                        'Remote/Work from home',
                        'Student',
                        'Retired',
                        'Unemployed',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(
                              color: isDark
                                  ? (Colors.deepOrange[700] ??
                                        Colors.deepOrange)
                                  : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _workStatus = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your work status';
                    }
                    return null;
                  },
                ),
                SizedBox(height: height * 0.03),

                // Submit button to generate recommendations
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: isDark ? Colors.white : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Get Recommendations',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build the health analysis results view
  // This view displays personalized health recommendations in card format
  Widget _buildResultsView({bool showUpdateButton = true}) {
    // Get theme provider to handle dark/light mode properly
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final orange = isDark
        ? (Colors.deepOrange[700] ?? Colors.deepOrange)
        : const Color(0xFFFF7F27);
    final textColor = isDark ? Colors.deepOrange[200] : Colors.grey[700];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results header with update button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Health Analysis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: orange,
                ),
              ),
              if (showUpdateButton)
                TextButton.icon(
                  icon: Icon(Icons.edit, color: orange),
                  label: Text('Update', style: TextStyle(color: orange)),
                  style: TextButton.styleFrom(foregroundColor: orange),
                  onPressed: () {
                    setState(() {
                      _hasSubmittedForm = false; // Return to form view
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
          
          // BMI analysis card
          HealthResultCard(
            title: 'BMI',
            subtitle: 'Your Body Mass Index',
            value: _resultData['bmi']?['value'] ?? 'N/A',
            category: _resultData['bmi']?['category'] ?? 'N/A',
            recommendation: _resultData['bmi']?['recommendation'] ?? 'N/A',
            icon: Icons.monitor_weight,
            color: orange,
          ),

          // Blood sugar analysis card
          HealthResultCard(
            title: 'Blood Sugar',
            subtitle: 'Your Blood Sugar Level',
            value: '${_resultData['bloodSugar']?['value'] ?? 'N/A'} mg/dL',
            category: _resultData['bloodSugar']?['category'] ?? 'N/A',
            recommendation:
                _resultData['bloodSugar']?['recommendation'] ?? 'N/A',
            icon: Icons.bloodtype,
            color: orange,
          ),

          // Physical activity recommendations card
          HealthResultCard(
            title: 'Physical Activity',
            subtitle: 'Your Activity Level',
            value: _resultData['activity']?['level'] ?? 'N/A',
            category: '',
            recommendation: _resultData['activity']?['recommendation'] ?? 'N/A',
            icon: Icons.directions_run,
            color: orange,
          ),

          // Sleep quality recommendations card
          HealthResultCard(
            title: 'Sleep',
            subtitle: 'Your Sleep Quality',
            value: _resultData['sleep']?['quality'] ?? 'N/A',
            category: '',
            recommendation: _resultData['sleep']?['recommendation'] ?? 'N/A',
            icon: Icons.bedtime,
            color: orange,
          ),

          // Diet quality recommendations card
          HealthResultCard(
            title: 'Diet',
            subtitle: 'Your Diet Quality',
            value: _resultData['diet']?['quality'] ?? 'N/A',
            category: '',
            recommendation: _resultData['diet']?['recommendation'] ?? 'N/A',
            icon: Icons.restaurant,
            color: orange,
          ),

          // Stress management recommendations card
          HealthResultCard(
            title: 'Stress Management',
            subtitle: 'Your Stress Level',
            value: _resultData['stress']?['level'] ?? 'N/A',
            category: '',
            recommendation: _resultData['stress']?['recommendation'] ?? 'N/A',
            icon: Icons.psychology,
            color: orange,
          ),

          // Age-specific recommendations card
          HealthResultCard(
            title: 'Age-Specific Recommendations',
            subtitle:
                'Based on Your Age: ${_resultData['age']?['value'] ?? 'N/A'}',
            value: '',
            category: '',
            recommendation: _resultData['age']?['recommendation'] ?? 'N/A',
            icon: Icons.calendar_today,
            color: orange,
          ),

          // Daily routine recommendations card
          HealthResultCard(
            title: 'Daily Routine',
            subtitle:
                'Based on Your Work: ${_resultData['routine']?['workStatus'] ?? 'N/A'}',
            value: '',
            category: '',
            recommendation: _resultData['routine']?['recommendation'] ?? 'N/A',
            icon: Icons.schedule,
            color: orange,
          ),

          const SizedBox(height: 32),
          
          // Medical disclaimer
          Center(
            child: Text(
              'Disclaimer: These recommendations are for general informational purposes only and do not constitute medical advice.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
