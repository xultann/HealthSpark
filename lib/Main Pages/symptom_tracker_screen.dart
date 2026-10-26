// Import statements for Flutter UI components, Firebase services, and app utilities
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:healthspark/Utils/symptom_algorithm.dart';
import '../Utils/theme_provider.dart'; // For ThemeProvider
import 'package:provider/provider.dart'; // For Provider
import 'dart:convert';
import 'package:flutter/services.dart';

// Symptom tracker screen that provides interactive health assessment
// This screen guides users through a series of questions to identify potential health issues
// and provides preliminary symptom analysis using the symptom algorithm
class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

// State class for SymptomTrackerScreen that manages the quiz flow and results
class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  // Quiz state management variables
  bool _quizStarted = false; // Whether the quiz has been initiated
  bool _quizCompleted = false; // Whether the current round is finished
  bool _showNextRound = false; // Whether to show option for additional questions
  int _currentQuestionIndex = 0; // Current question being displayed
  bool _isSecondRound = false; // Whether user is on the second set of questions
  
  // Question data management
  List<Map<String, dynamic>> _allQuestions = []; // All available questions from JSON
  List<Map<String, dynamic>> _currentQuestions = []; // Current set of questions (15 questions)
  List<Map<String, dynamic>> _nextQuestions = []; // Next set of questions for second round
  
  // User responses and results
  final List<String> _answers = []; // User's answers to questions
  String? _result; // Calculated symptom result

  @override
  void initState() {
    super.initState();
    // Load questions from JSON file when screen initializes
    _loadQuestions();
  }

  // Load symptom questions from the JSON asset file
  // This method reads the questions, shuffles them, and prepares two sets
  Future<void> _loadQuestions() async {
    final String data = await rootBundle.loadString(
      'assets/symptom_questions.json',
    );
    final List<dynamic> jsonResult = json.decode(data);
    _allQuestions = jsonResult.cast<Map<String, dynamic>>();
    _allQuestions.shuffle(); // Randomize question order for variety
    
    setState(() {
      // Split questions into two sets of 15 questions each
      _currentQuestions = _allQuestions.take(15).toList();
      _nextQuestions = _allQuestions.skip(15).take(15).toList();
    });
  }

  // Start the symptom assessment quiz
  // This method resets all quiz state and begins the assessment
  void _startQuiz() {
    setState(() {
      _quizStarted = true;
      _quizCompleted = false;
      _showNextRound = false;
      _currentQuestionIndex = 0;
      _answers.clear(); // Clear previous answers
      _isSecondRound = false; // Reset round state
    });
  }

  // Handle user's answer to a question
  // This method records the answer and progresses to the next question or completes the round
  void _answerQuestion(int optionIndex) {
    // Add the selected answer to the answers list
    _answers.add(
      _currentQuestions[_currentQuestionIndex]['options'][optionIndex],
    );
    
    // Check if there are more questions in the current round
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++; // Move to next question
      });
    } else {
      // Current round is complete
      setState(() {
        _quizCompleted = true;
        _showNextRound = _nextQuestions.isNotEmpty; // Show continue option if more questions available
      });
      _saveResult(); // Save the assessment result
    }
  }

  // Continue to the second round of questions for more accurate assessment
  // This method switches to the next set of questions while preserving first round answers
  void _continueToNextRound() {
    setState(() {
      _currentQuestions = _nextQuestions; // Switch to next question set
      _currentQuestionIndex = 0; // Reset question index
      _quizCompleted = false; // Reset completion state
      _showNextRound = false; // Hide continue option
      _isSecondRound = true; // Mark as second round
      // Keep the first 15 answers, and add 15 more
      // So don't clear `_answers`
    });
  }

  // Save the assessment result to Firestore database
  // This method calculates the symptom result and stores it with user data
  Future<void> _saveResult() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Calculate symptom result using the symptom algorithm
    final resultData = calculateSymptomResult(_answers);

    setState(() {
      _result = resultData['symptom']; // Set for UI display
    });

    // Save result to Firestore for user's health profile
    await FirebaseFirestore.instance
        .collection('symptoms_result')
        .doc(userId)
        .set({
          'answers': _answers, // Store all user answers
          'symptom': resultData['symptom'], // Calculated symptom
          'definition': resultData['definition'], // Symptom explanation
          'timestamp': FieldValue.serverTimestamp(), // When assessment was taken
        });
  }

  @override
  Widget build(BuildContext context) {
    // Get theme information for consistent styling
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final orange = isDark
        ? (Colors.deepOrange[700] ?? Colors.deepOrange)
        : const Color(0xFFFF7F27);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final padding = width * 0.04;
        
        return Scaffold(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          body: Padding(
            padding: EdgeInsets.all(padding),
            child: _quizStarted
                ? _quizCompleted
                      ? _buildResultView(orange, isDark, width, height) // Show results
                      : _buildQuizView(orange, isDark, width, height) // Show current question
                : _buildWelcomeView(orange, isDark, width, height), // Show welcome screen
          ),
        );
      },
    );
  }

  // Build the welcome screen that introduces the symptom assessment
  // This view explains the purpose and provides the start button
  Widget _buildWelcomeView(
    Color orange,
    bool isDark,
    double width,
    double height,
  ) {
    final imageHeight = height * 0.28;
    final headingFontSize = width * 0.06;
    final bodyFontSize = width * 0.042;
    final noteFontSize = width * 0.037;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Health monitoring illustration
        Image.asset('assets/opener/OPic1.png', height: imageHeight),
        SizedBox(height: height * 0.03),
        
        // Screen title
        Text(
          'Symptom Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: headingFontSize,
            color: orange,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: height * 0.02),
        
        // Description of the assessment tool
        Text(
          'This interactive tool will help you identify possible health issues based on your symptoms. Please answer a series of questions to get a preliminary assessment.',
          style: TextStyle(fontSize: bodyFontSize, color: orange),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: height * 0.02),
        
        // Important disclaimer about medical advice
        Text(
          'Note: This tool is for informational purposes only and is not a substitute for professional medical advice.',
          style: TextStyle(
            fontSize: noteFontSize,
            fontStyle: FontStyle.italic,
            color: orange,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: height * 0.04),
        
        // Start assessment button
        ElevatedButton(
          onPressed: _startQuiz,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: height * 0.022),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: orange,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Start Symptom Assessment',
            style: TextStyle(fontSize: bodyFontSize),
          ),
        ),
      ],
    );
  }

  // Build the quiz interface that displays questions and answer options
  // This view shows the current question with multiple choice options
  Widget _buildQuizView(
    Color orange,
    bool isDark,
    double width,
    double height,
  ) {
    final currentQuestion = _currentQuestions[_currentQuestionIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator showing quiz completion
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _currentQuestions.length,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(orange),
        ),
        SizedBox(height: height * 0.01),
        
        // Question number indicator
        Text(
          'Question ${_currentQuestionIndex + 1}',
          style: TextStyle(fontSize: width * 0.035, color: orange),
        ),
        SizedBox(height: height * 0.03),

        // Current question text
        Text(
          currentQuestion['question'],
          style: TextStyle(
            fontSize: width * 0.05,
            fontWeight: FontWeight.bold,
            color: orange,
          ),
        ),
        SizedBox(height: height * 0.04),

        // Answer options as interactive buttons
        ...List.generate(
          currentQuestion['options'].length,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: height * 0.02),
            child: ElevatedButton(
              onPressed: () => _answerQuestion(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 2,
                padding: EdgeInsets.all(width * 0.04),
                alignment: Alignment.centerLeft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  // Option letter (A, B, C, D, etc.)
                  Text(
                    '${String.fromCharCode(65 + index)}.',
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  
                  // Option text
                  Expanded(
                    child: Text(
                      currentQuestion['options'][index],
                      style: TextStyle(
                        fontSize: width * 0.04,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  
                  // Arrow icon indicating clickable option
                  Icon(
                    Icons.arrow_forward_ios,
                    size: width * 0.035,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Build the results view that displays the assessment outcome
  // This view shows the calculated symptom, explanation, and next steps
  Widget _buildResultView(
    Color orange,
    bool isDark,
    double width,
    double height,
  ) {
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.deepOrange[200] : Colors.black;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results title
          Text(
            'Assessment Result',
            style: TextStyle(
              fontSize: width * 0.06,
              fontWeight: FontWeight.bold,
              color: orange,
            ),
          ),
          SizedBox(height: height * 0.02),

          // Diagnosis card with symptom and explanation
          Card(
            color: cardColor,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: orange, width: 2),
            ),
            child: Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Symptom header with icon
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(width * 0.03),
                        decoration: BoxDecoration(
                          color: orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.medical_information,
                          color: orange,
                          size: width * 0.08,
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      
                      // Symptom name
                      Text(
                        _result ?? '',
                        style: TextStyle(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.02),
                  
                  // Symptom explanation
                  Text(
                    calculateSymptomResult(_answers)['definition'] ?? '',
                    style: TextStyle(fontSize: width * 0.04, color: textColor),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: height * 0.03),

          // Medical disclaimer warning
          Container(
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Text(
                    'This assessment is not a medical diagnosis. Please consult with a healthcare provider for proper evaluation and treatment.',
                    style: TextStyle(fontSize: width * 0.035, color: textColor),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.04),

          // Action buttons for next steps
          Row(
            children: [
              // Start over button
              Expanded(
                child: OutlinedButton(
                  onPressed: _startQuiz,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: height * 0.022),
                    side: BorderSide(color: orange),
                    foregroundColor: orange,
                  ),
                  child: Text(
                    'Start Over',
                    style: TextStyle(fontSize: width * 0.04, color: orange),
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),
              
              // End quiz button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // End Quiz: go back to welcome view
                    setState(() {
                      _quizStarted = false;
                      _quizCompleted = false;
                      _showNextRound = false;
                      _currentQuestionIndex = 0;
                      _answers.clear();
                      _isSecondRound = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: height * 0.022),
                    side: BorderSide(color: orange),
                    foregroundColor: orange,
                  ),
                  child: Text(
                    'End Quiz',
                    style: TextStyle(fontSize: width * 0.04, color: orange),
                  ),
                ),
              ),
            ],
          ),
          
          // Continue option only on first round for more accurate assessment
          if (!_isSecondRound && _showNextRound) ...[
            SizedBox(height: height * 0.03),
            Center(
              child: Text(
                'Would you like to continue to get more accurate result?',
                style: TextStyle(fontSize: width * 0.04, color: textColor, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: height * 0.02),
            Center(
              child: SizedBox(
                width: width * 0.6,
                child: ElevatedButton(
                  onPressed: _continueToNextRound,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: height * 0.022),
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(fontSize: width * 0.04),
                  ),
                ),
              ),
            ),
          ],
          SizedBox(height: height * 0.02),
        ],
      ),
    );
  }
}
