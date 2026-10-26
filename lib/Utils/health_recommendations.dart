// Import statements for Flutter UI components (if needed for future extensions)
// Currently this file contains health assessment algorithms and recommendation logic

/// Generates personalized health recommendations based on user's health profile data.
/// This function analyzes various health metrics and lifestyle factors to provide
/// customized advice for improving overall health and wellness.
/// 
/// Parameters:
/// - age: User's age in years
/// - height: User's height in centimeters
/// - weight: User's weight in kilograms
/// - bloodSugar: User's blood sugar level in mg/dL
/// - gender: User's gender (optional)
/// - activityLevel: Current activity level (Sedentary, Light, Moderate, Very active)
/// - medicalConditions: Any existing medical conditions (optional)
/// - sleepQuality: Quality of sleep (Poor, Fair, Good, Excellent)
/// - stressLevel: Current stress level (Low, Moderate, High, Severe)
/// - diet: Diet quality (Poor, Fair, Good, Excellent)
/// - workStatus: Current work situation (Full-time sedentary, Full-time active, etc.)
/// 
/// Returns:
/// - Map containing categorized health recommendations with values, categories, and personalized advice
Map<String, dynamic> generateHealthRecommendations({
  required int age,
  required double height,
  required double weight,
  required double bloodSugar,
  String? gender,
  String? activityLevel,
  String? medicalConditions,
  String? sleepQuality,
  String? stressLevel,
  String? diet,
  String? workStatus,
}) {
  // Calculate Body Mass Index (BMI) using the formula: weight(kg) / height(m)²
  // BMI is used to categorize weight status and provide appropriate recommendations
  final bmi = weight / ((height / 100) * (height / 100));
  String bmiCategory;
  String bmiRecommendation;
  
  // Categorize BMI and provide specific recommendations based on weight status
  if (bmi < 18.5) {
    bmiCategory = 'Underweight';
    bmiRecommendation = 'Focus on nutrient-dense foods and consider consulting with a nutritionist for a personalized weight gain plan.';
  } else if (bmi >= 18.5 && bmi < 25) {
    bmiCategory = 'Normal weight';
    bmiRecommendation = 'Maintain your healthy lifestyle with balanced nutrition and regular exercise.';
  } else if (bmi >= 25 && bmi < 30) {
    bmiCategory = 'Overweight';
    bmiRecommendation = 'Consider incorporating more physical activity and adjusting your diet to include more fruits, vegetables, and whole grains.';
  } else {
    bmiCategory = 'Obese';
    bmiRecommendation = 'Please consult with a healthcare provider to develop a safe and effective weight management plan.';
  }
  
  // Blood sugar analysis and recommendations
  // Blood sugar levels are critical for diabetes management and overall health
  String bloodSugarCategory;
  String bloodSugarRecommendation;
  
  if (bloodSugar < 70) {
    bloodSugarCategory = 'Low';
    bloodSugarRecommendation = 'Your blood sugar appears to be low. Consider consuming a fast-acting carbohydrate and monitoring your levels closely.';
  } else if (bloodSugar >= 70 && bloodSugar <= 99) {
    bloodSugarCategory = 'Normal (fasting)';
    bloodSugarRecommendation = 'Your fasting blood sugar is within the normal range. Continue monitoring regularly.';
  } else if (bloodSugar >= 100 && bloodSugar <= 125) {
    bloodSugarCategory = 'Prediabetic (fasting)';
    bloodSugarRecommendation = 'Your fasting blood sugar suggests prediabetes. Consider consulting with a healthcare provider and focus on lifestyle modifications.';
  } else {
    bloodSugarCategory = 'Diabetic range (fasting)';
    bloodSugarRecommendation = 'Your fasting blood sugar is in the diabetic range. Please consult with a healthcare provider as soon as possible.';
  }
  
  // Physical activity recommendations based on current activity level
  // Exercise is essential for maintaining health and preventing chronic diseases
  String activityRecommendation;
  switch (activityLevel) {
    case 'Sedentary':
      activityRecommendation = 'Try to incorporate at least 150 minutes of moderate-intensity exercise per week. Start with short walks and gradually increase duration.';
      break;
    case 'Light activity':
      activityRecommendation = 'Aim for 150-300 minutes of moderate-intensity exercise per week. Consider adding strength training 2 days a week.';
      break;
    case 'Moderate activity':
      activityRecommendation = 'Maintain your current activity level and consider adding variety to your routine with different types of exercise.';
      break;
    case 'Very active':
      activityRecommendation = 'Ensure you\'re allowing adequate recovery time between intense workouts and focus on proper nutrition to support your activity level.';
      break;
    default:
      activityRecommendation = 'Aim for at least 150 minutes of moderate-intensity exercise per week with 2 days of strength training.';
  }
  
  // Sleep quality recommendations
  // Quality sleep is fundamental for physical and mental health
  String sleepRecommendation;
  switch (sleepQuality) {
    case 'Poor':
      sleepRecommendation = 'Create a consistent sleep schedule, avoid screens before bedtime, keep your bedroom cool and dark, and consider relaxation techniques like meditation.';
      break;
    case 'Fair':
      sleepRecommendation = 'Improve your sleep environment, limit caffeine after noon, and establish a calming bedtime routine.';
      break;
    case 'Good':
      sleepRecommendation = 'Maintain your healthy sleep habits and consider tracking your sleep patterns to identify any areas for improvement.';
      break;
    case 'Excellent':
      sleepRecommendation = 'Continue your excellent sleep habits and share your successful strategies with others.';
      break;
    default:
      sleepRecommendation = 'Adults should aim for 7-9 hours of quality sleep per night. Establish a consistent sleep schedule and create a restful environment.';
  }
  
  // Dietary recommendations based on current diet quality
  // Nutrition plays a crucial role in overall health and disease prevention
  String dietRecommendation;
  switch (diet) {
    case 'Poor':
      dietRecommendation = 'Focus on incorporating more fruits, vegetables, and whole grains. Reduce processed foods, sugary drinks, and excessive salt.';
      break;
    case 'Fair':
      dietRecommendation = 'Work on improving the balance of your meals. Aim for half your plate to be fruits and vegetables, a quarter protein, and a quarter whole grains.';
      break;
    case 'Good':
      dietRecommendation = 'Continue your healthy eating habits and consider meal planning to maintain consistency.';
      break;
    case 'Excellent':
      dietRecommendation = 'Maintain your excellent dietary habits and consider exploring new healthy recipes to keep your diet interesting and varied.';
      break;
    default:
      dietRecommendation = 'Focus on a balanced diet rich in fruits, vegetables, whole grains, lean proteins, and healthy fats. Limit processed foods, added sugars, and excessive salt.';
  }
  
  // Stress management recommendations
  // Chronic stress can negatively impact physical and mental health
  String stressRecommendation;
  switch (stressLevel) {
    case 'Low':
      stressRecommendation = 'Continue your effective stress management practices and share your strategies with others.';
      break;
    case 'Moderate':
      stressRecommendation = 'Incorporate regular relaxation techniques such as deep breathing, meditation, or gentle exercise like yoga or tai chi.';
      break;
    case 'High':
      stressRecommendation = 'Consider prioritizing stress management through regular exercise, mindfulness practices, and possibly speaking with a mental health professional.';
      break;
    case 'Severe':
      stressRecommendation = 'Please consider consulting with a healthcare provider or mental health professional for support with stress management strategies.';
      break;
    default:
      stressRecommendation = 'Practice regular stress management techniques such as deep breathing, physical activity, adequate sleep, and connecting with supportive people.';
  }
  
  // Age-specific health recommendations
  // Different age groups have different health priorities and needs
  String ageRecommendation;
  if (age < 18) {
    ageRecommendation = 'Focus on building healthy habits early, including regular physical activity, balanced nutrition, and adequate sleep.';
  } else if (age >= 18 && age < 40) {
    ageRecommendation = 'Establish healthy lifestyle habits now that will support your health long-term. Regular check-ups are important even when feeling well.';
  } else if (age >= 40 && age < 65) {
    ageRecommendation = 'Regular health screenings become increasingly important. Discuss with your doctor which screenings are appropriate for your age and risk factors.';
  } else {
    ageRecommendation = 'Stay active physically and mentally. Regular health check-ups and staying connected socially are particularly important.';
  }
  
  // Daily routine recommendations based on work status
  // Work situation significantly impacts lifestyle and health habits
  String routineRecommendation;
  switch (workStatus) {
    case 'Full-time sedentary':
      routineRecommendation = 'Take regular breaks to stand and move around. Aim for at least 2-3 minutes of movement every hour and consider using a standing desk if possible.';
      break;
    case 'Full-time active':
      routineRecommendation = 'Ensure you\'re using proper form and equipment to prevent injuries. Focus on recovery with adequate rest and nutrition.';
      break;
    case 'Part-time':
      routineRecommendation = 'Use your available time wisely to incorporate physical activity and prepare healthy meals.';
      break;
    case 'Remote/Work from home':
      routineRecommendation = 'Create a dedicated workspace and stick to a routine. Schedule regular movement breaks and outdoor time when possible.';
      break;
    case 'Student':
      routineRecommendation = 'Balance study time with regular physical activity. Take study breaks to move around and avoid excessive caffeine, especially late in the day.';
      break;
    case 'Retired':
      routineRecommendation = 'Stay physically and mentally active. Consider volunteering, social groups, or classes to maintain routine and social connections.';
      break;
    case 'Unemployed':
      routineRecommendation = 'Establish a daily routine that includes physical activity, learning opportunities, and social connections.';
      break;
    default:
      routineRecommendation = 'Regardless of your work situation, aim to incorporate regular movement throughout your day and prioritize time for health-supporting activities.';
  }
  
  // Return comprehensive health recommendations organized by category
  // Each category contains relevant values, classifications, and personalized advice
  return {
    'bmi': {
      'value': bmi.toStringAsFixed(1), // BMI value with one decimal place
      'category': bmiCategory, // Weight status category
      'recommendation': bmiRecommendation, // Personalized weight management advice
    },
    'bloodSugar': {
      'value': bloodSugar.toString(), // Blood sugar level
      'category': bloodSugarCategory, // Blood sugar status category
      'recommendation': bloodSugarRecommendation, // Blood sugar management advice
    },
    'activity': {
      'level': activityLevel, // Current activity level
      'recommendation': activityRecommendation, // Exercise and activity advice
    },
    'sleep': {
      'quality': sleepQuality, // Current sleep quality
      'recommendation': sleepRecommendation, // Sleep improvement advice
    },
    'diet': {
      'quality': diet, // Current diet quality
      'recommendation': dietRecommendation, // Nutritional advice
    },
    'stress': {
      'level': stressLevel, // Current stress level
      'recommendation': stressRecommendation, // Stress management advice
    },
    'age': {
      'value': age.toString(), // User's age
      'recommendation': ageRecommendation, // Age-appropriate health advice
    },
    'routine': {
      'workStatus': workStatus, // Current work situation
      'recommendation': routineRecommendation, // Lifestyle and routine advice
    }
  };
}