import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Utils/theme_provider.dart';

class HealthResultCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String category;
  final String recommendation;
  final IconData icon;
  final Color color;

  const HealthResultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.category,
    required this.recommendation,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme provider to handle dark/light mode properly
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final accent = isDark ? (Colors.deepOrange[700] ?? Colors.deepOrange) : const Color(0xFFFF7F27);
    final cardBg = isDark ? Colors.grey[850] : Colors.white;
    final cardText = isDark ? Colors.deepOrange[200] : Colors.grey[700];
    final mainText = accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 3,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: cardText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                // Add a small right padding to prevent overflow
                // (sometimes Flutter overflows by a fraction of a pixel)
                // This is a workaround for that
                // You can adjust the value if needed
                // Padding is added outside the Row
                // Alternatively, wrap the Row in a Padding widget
              ),
              const SizedBox(height: 16),
              if (value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Value: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: mainText),
                        ),
                        TextSpan(text: value, style: TextStyle(color: cardText)),
                      ],
                    ),
                  ),
                ),
              if (category.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Category: ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: mainText),
                        ),
                        TextSpan(text: category, style: TextStyle(color: cardText)),
                      ],
                    ),
                  ),
                ),
              const Divider(),
              Text(
                'Recommendation:',
                style: TextStyle(fontWeight: FontWeight.bold, color: mainText),
              ),
              const SizedBox(height: 4),
              Text(
                recommendation,
                style: TextStyle(color: cardText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
