import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Utils/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _articles = [];
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'General Health',
    'Disease Prevention',
    'Nutrition',
    'Mental Health',
    'Latest Research'
  ];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() { _isLoading = true; });
    try {
      final query = await FirebaseFirestore.instance
          .collection('shared_medical_info')
          .where('infoReadable', isEqualTo: true)
          .orderBy('publishedDate', descending: true)
          .get();
      final articles = query.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading articles: $e')),
      );
    }
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference link copied to clipboard!')),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final themeColor = isDark ? Colors.grey[900] : Colors.white;
    return Container(
      color: themeColor,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.05 * 255).toInt()),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                            selectedColor: isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange).withAlpha((0.2 * 255).toInt()) : const Color(0xFFFF7F27).withAlpha((0.2 * 255).toInt()),
                            checkmarkColor: isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildArticlesList(),
                ),
              ],
            ),
    );
  }

  Widget _buildArticlesList() {
    final filteredArticles = _selectedCategory == 'All'
        ? _articles
        : _articles.where((article) => (article['categories'] as List).contains(_selectedCategory)).toList();
    if (filteredArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.article_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No medical info available in $_selectedCategory category',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredArticles.length,
      itemBuilder: (context, index) {
        final article = filteredArticles[index];
        return _buildArticleCard(article);
      },
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    final publishedDate = (article['publishedDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = '${publishedDate.day}/${publishedDate.month}/${publishedDate.year}';
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final accent = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    final cardBgColor = isDark ? Colors.grey[850] : Colors.white;
    final cardTextColor = accent;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent, width: 2),
      ),
      elevation: 2,
      color: cardBgColor,
      child: InkWell(
        onTap: () {
          _showArticleDetails(article);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final cat in (article['categories'] as List? ?? []))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(cat).withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: _getCategoryColor(cat),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Published: $formattedDate',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article['title'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cardTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                article['description'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.deepOrange[200] : Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    article['author'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cardTextColor,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showArticleDetails(Map<String, dynamic> article) {
    final publishedDate = (article['publishedDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final formattedDate = '${publishedDate.day}/${publishedDate.month}/${publishedDate.year}';
    final submissionDate = (article['submissionDate'] as Timestamp?)?.toDate();
    final formattedSubmissionDate = submissionDate != null
        ? '${submissionDate.day}/${submissionDate.month}/${submissionDate.year}'
        : '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final fadedOrange = const Color(0xFFFFE0B2);
        final modalTextColor = isDark ? Colors.grey[300] : Colors.grey[700];
        final modalBgColor = isDark ? Colors.grey[900] : fadedOrange;
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: modalBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  // Category chips at the top
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final cat in (article['categories'] as List? ?? []))
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(cat).withAlpha((0.1 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: _getCategoryColor(cat),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Published: $formattedDate',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article['title'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: modalTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(context).primaryColor.withAlpha((0.1 * 255).toInt()),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'By ${article['author'] ?? ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: modalTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if ((article['submittedByFirstName'] ?? '').toString().isNotEmpty || (article['submittedByLastName'] ?? '').toString().isNotEmpty)
                    Text(
                      'Submitted by: ${article['submittedByFirstName'] ?? ''} ${article['submittedByLastName'] ?? ''} on $formattedSubmissionDate',
                      style: TextStyle(fontSize: 13, color: modalTextColor),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: modalTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article['description'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: modalTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Reference:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: modalTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article['reference'] ?? '',
                    style: TextStyle(
                      color: isDark ? (Colors.deepOrange[300] ?? Colors.deepOrange) : const Color(0xFFFF7F27),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.deepOrange[700] : const Color(0xFFFF7F27),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy Reference Link'),
                    onPressed: () {
                      final ref = (article['reference'] ?? '').toString();
                      if (ref.isNotEmpty) _copyToClipboard(ref);
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0B2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Text(
                      'Disclaimer: This information is for educational purposes only and is not intended to replace professional medical advice. Always consult with a healthcare provider for medical concerns.',
                      style: TextStyle(fontSize: 12, color: modalTextColor),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'General Health':
        return Colors.blue;
      case 'Disease Prevention':
        return Colors.green;
      case 'Nutrition':
        return Colors.orange;
      case 'Mental Health':
        return Colors.purple;
      case 'Latest Research':
        return Colors.teal;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}