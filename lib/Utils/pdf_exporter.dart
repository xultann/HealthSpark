// Import statements for Flutter UI components, PDF generation, printing, and Firebase services
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Exports user's health recommendations as a PDF document
/// This function creates a professional PDF report containing personalized health recommendations
/// that can be shared with healthcare providers or saved for personal reference.
/// 
/// Parameters:
/// - context: BuildContext for accessing Flutter services and showing notifications
/// 
/// The PDF includes:
/// - HealthSpark logo and branding
/// - User's personalized health recommendations
/// - Formatted data with categories and values
/// - Professional styling and layout
Future<void> exportHealthRecommendationsAsPdf(BuildContext context) async {
  // Create a new PDF document instance
  final pdf = pw.Document();

  // Load the HealthSpark logo image from assets and convert to PDF-compatible format
  // This logo will be displayed at the top of the PDF report
  final logoBytes = await rootBundle.load('assets/png/hs_logo.png');
  final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

  // Fetch the current user's health recommendations from Firestore database
  // This data contains personalized health advice based on user's profile
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? recommendationsData;
  if (user != null) {
    // Get the user's health profile document from Firestore
    final doc = await FirebaseFirestore.instance.collection('health_profiles').doc(user.uid).get();
    if (doc.exists) {
      // Extract the recommendations data from the document
      recommendationsData = doc.data()?['recommendations'] as Map<String, dynamic>?;
    }
  }

  // Transform the raw recommendations data into a structured format for PDF display
  // This converts the Firestore data into a more readable format with proper titles and categories
  List<Map<String, String>> recommendations = [];
  if (recommendationsData != null) {
    recommendations = recommendationsData.entries.map((entry) {
      final value = entry.value as Map<String, dynamic>?;
      return {
        'title': entry.key[0].toUpperCase() + entry.key.substring(1), // Capitalize first letter
        'value': value?['value']?.toString() ?? '', // Health metric value
        'category': value?['category']?.toString() ?? '', // Health category
        'recommendation': value?['recommendation']?.toString() ?? '', // Personalized advice
      };
    }).toList();
  }

  // Add content to the PDF document with professional formatting
  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        // Header section with logo and title
        pw.Center(
          child: pw.Column(
            children: [
              // Display the HealthSpark logo at the top
              pw.Image(logoImage, width: 160),
              pw.SizedBox(height: 12),
              // PDF title
              pw.Text('HealthSpark Health Recommendations',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 24),
            ],
          ),
        ),
        // Show message if no recommendations are available
        if (recommendations.isEmpty)
          pw.Center(
            child: pw.Text('No health recommendations found.', style: pw.TextStyle(fontSize: 16)),
          ),
        // Generate recommendation sections for each health category
        ...recommendations.map((rec) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 18),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Recommendation title (e.g., "Exercise", "Nutrition")
              pw.Text(rec['title'] ?? '', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              // Display health metric value if available
              if ((rec['value'] ?? '').isNotEmpty)
                pw.Text('Value: ${rec['value']}', style: pw.TextStyle(fontSize: 14)),
              // Display health category if available
              if ((rec['category'] ?? '').isNotEmpty)
                pw.Text('Category: ${rec['category']}', style: pw.TextStyle(fontSize: 14)),
              // Display the personalized recommendation
              pw.Text('Recommendation:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(rec['recommendation'] ?? '', style: pw.TextStyle(fontSize: 13)),
            ],
          ),
        )),
        // Footer section with app branding
        pw.SizedBox(height: 24),
        pw.Center(
          child: pw.Text('Generated by HealthSpark', style: pw.TextStyle(fontSize: 12)),
        ),
      ],
    ),
  );

  // Launch the PDF viewer/printer with the generated document
  // This allows users to view, print, or share the PDF
  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name: 'health_recommendations.pdf', // Default filename for the PDF
  );

  // Show a success message to the user after PDF generation
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF generated and ready to share/print!')),
    );
  }
} 