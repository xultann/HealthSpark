// Import statements for Flutter UI components (if needed for future extensions)
// Currently this file only contains data structures and algorithms

/// A comprehensive list of possible symptom results and their related keywords.
/// This data structure defines various health conditions and the symptoms that indicate them.
/// Each condition includes a symptom name, definition/explanation, and relevant keywords for matching.
final List<Map<String, dynamic>> symptomConditions = [
  // Flu-like illness condition with common cold and flu symptoms
  {
    'symptom': 'Flu-like Illness',
    'definition':
        'Your answers suggest you may have a flu-like illness. Rest, stay hydrated, and consult a healthcare provider if symptoms worsen.',
    'keywords': ['fever', 'cough', 'sore', 'fatigue', 'chills', 'headache'],
  },
  // COVID-19 condition with specific symptoms that require immediate attention
  {
    'symptom': 'Possible COVID-19',
    'definition':
        'Fever and shortness of breath can be signs of COVID-19. Please get tested and follow local health guidelines.',
    'keywords': ['fever', 'shortness', 'loss of taste', 'loss of smell', 'fatigue'],
  },
  // Headache conditions including migraine and tension headaches
  {
    'symptom': 'Migraine or Tension Headache',
    'definition':
        'Headache and fatigue may indicate a migraine or tension headache. Consider rest and consult a doctor if severe.',
    'keywords': ['headache', 'fatigue', 'lightheaded', 'nausea'],
  },
  // Allergic reactions and seasonal allergies
  {
    'symptom': 'Allergies',
    'definition':
        'Itchy eyes, sneezing, and a runny nose may indicate seasonal or environmental allergies.',
    'keywords': ['itchy', 'runny nose', 'sneeze', 'watery', 'red eyes'],
  },
  // Gastrointestinal issues affecting the digestive system
  {
    'symptom': 'Gastrointestinal Issue',
    'definition':
        'Your symptoms may point to a stomach-related issue. Stay hydrated and monitor symptoms.',
    'keywords': ['nausea', 'vomiting', 'diarrhea', 'appetite', 'weight loss'],
  },
  // Mental health concerns including stress, anxiety, and depression
  {
    'symptom': 'Mental Health Concern',
    'definition':
        'Stress, anxiety, or depression may be affecting your health. Consider seeking support or speaking to a professional.',
    'keywords': ['stress', 'mood', 'sleep', 'anxious', 'depressed'],
  },
  // Default condition when no specific symptoms are detected
  {
    'symptom': 'No Major Symptom Detected',
    'definition':
        'Your answers do not indicate a specific illness. If you feel unwell, please consult a healthcare provider.',
    'keywords': [], // Empty keywords list for default case
  },
];

/// Calculates the most likely symptom result based on user's selected answers.
/// This algorithm uses keyword matching to determine the most probable health condition.
/// 
/// Parameters:
/// - answers: List of strings containing user's symptom responses
/// 
/// Returns:
/// - Map containing the detected symptom name and its definition
Map<String, String> calculateSymptomResult(List<String> answers) {
  // Initialize a map to store scores for each possible symptom condition
  final Map<String, int> symptomScores = {};

  // Initialize all symptom scores to 0 to ensure all conditions are considered
  for (final condition in symptomConditions) {
    symptomScores[condition['symptom']] = 0;
  }

  // Iterate through each answer provided by the user
  for (final answer in answers) {
    // Check each possible symptom condition
    for (final condition in symptomConditions) {
      // Compare the answer against each keyword for the current condition
      for (final keyword in condition['keywords']) {
        // If the answer contains the keyword (case-insensitive), increment the score
        if (answer.toLowerCase().contains(keyword)) {
          symptomScores[condition['symptom']] =
              (symptomScores[condition['symptom']] ?? 0) + 1;
        }
      }
    }
  }

  // Sort the results by score in descending order to find the highest scoring condition
  final sortedResults = symptomScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Get the condition with the highest score
  final topSymptom = sortedResults.first;

  // If no strong matches are found (score is 0), return the default condition
  if (topSymptom.value == 0) {
    final defaultCondition = symptomConditions.firstWhere(
        (c) => c['symptom'] == 'No Major Symptom Detected');
    return {
      'symptom': defaultCondition['symptom'],
      'definition': defaultCondition['definition'],
    };
  }

  // Find the complete condition data for the top-scoring symptom
  final result = symptomConditions.firstWhere(
      (c) => c['symptom'] == topSymptom.key);

  // Return the symptom name and its definition
  return {
    'symptom': result['symptom'],
    'definition': result['definition'],
  };
}
