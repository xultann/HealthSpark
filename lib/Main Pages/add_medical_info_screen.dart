import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Utils/theme_provider.dart';

class AddMedicalInfoScreen extends StatefulWidget {
  const AddMedicalInfoScreen({super.key});

  @override
  State<AddMedicalInfoScreen> createState() => _AddMedicalInfoScreenState();
}

class _AddMedicalInfoScreenState extends State<AddMedicalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final List<String> _selectedCategories = [];
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General Health',
    'Disease Prevention',
    'Nutrition',
    'Mental Health',
    'Latest Research',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorController.dispose();
    _linkController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final orange = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    final bgColor = isDark ? (Colors.grey[900] ?? Colors.black) : Colors.white;
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            colorScheme: (isDark
              ? ColorScheme.dark(
                  primary: orange,
                  surface: bgColor,
                )
              : ColorScheme.light(
                  primary: orange,
                  surface: bgColor,
                )),
            dialogTheme: DialogThemeData(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: orange, width: 2),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<Map<String, String>> _getUserNames() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {'firstName': '', 'lastName': ''};
    final doc = await FirebaseFirestore.instance.collection('hsUsers').doc(user.uid).get();
    final data = doc.data();
    return {
      'firstName': data?['firstName'] ?? '',
      'lastName': data?['lastName'] ?? '',
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategories.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select at least one category and a date.')),
      );
      return;
    }
    setState(() { _isSubmitting = true; });
    try {
      final userNames = await _getUserNames();
      await FirebaseFirestore.instance.collection('shared_medical_info').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'author': _authorController.text.trim(),
        'categories': _selectedCategories,
        'publishedDate': _selectedDate,
        'reference': _linkController.text.trim(),
        'infoReadable': false,
        'submittedByFirstName': userNames['firstName'],
        'submittedByLastName': userNames['lastName'],
        'submissionDate': DateTime.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical info submitted for review!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final themeColor = isDark ? Colors.grey[900] : Colors.white;
    final orange = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    final greyText = isDark ? Colors.grey[300] : Colors.black;

    return Scaffold(
      backgroundColor: themeColor,
      appBar: AppBar(
        title: Text(
          'Add Medical Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: orange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
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
                  Text(
                    'Share Medical Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: orange,
                      fontSize: headingFontSize,
                    ),
                  ),
                  SizedBox(height: height * 0.01),
                  Text(
                    'Fill out this form to share medical information with the community. Your submission will be reviewed before being published.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: greyText,
                      fontSize: labelFontSize,
                    ),
                  ),
                  SizedBox(height: height * 0.03),
                  // Title
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(color: greyText),
                    decoration: InputDecoration(
                      labelText: 'Title',
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
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: height * 0.02),
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    style: TextStyle(color: greyText),
                    decoration: InputDecoration(
                      labelText: 'Description',
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
                    maxLines: 2,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: height * 0.02),
                  // Author Name
                  TextFormField(
                    controller: _authorController,
                    style: TextStyle(color: greyText),
                    decoration: InputDecoration(
                      labelText: 'Author Name',
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
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: height * 0.02),
                  // Date of Release
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dateController,
                        style: TextStyle(color: greyText),
                        decoration: InputDecoration(
                          labelText: 'Date of Release',
                          labelStyle: TextStyle(color: orange),
                          hintText: 'Select date',
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
                        validator: (v) => _selectedDate == null ? 'Required' : null,
                      ),
                    ),
                  ),
                  SizedBox(height: height * 0.02),
                  // Categories
                  Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, color: orange, fontSize: labelFontSize)),
                  SizedBox(height: height * 0.01),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((cat) {
                      final selected = _selectedCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat, style: TextStyle(color: selected ? Colors.white : orange)),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                        },
                        selectedColor: orange,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: height * 0.02),
                  // Link Source
                  TextFormField(
                    controller: _linkController,
                    style: TextStyle(color: greyText),
                    decoration: InputDecoration(
                      labelText: 'Link Source',
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || !uri.isAbsolute) return 'Enter a valid URL';
                      return null;
                    },
                  ),
                  SizedBox(height: height * 0.04),
                  // Submit button
                  Center(
                    child: SizedBox(
                      width: width > 400 ? 320 : double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 