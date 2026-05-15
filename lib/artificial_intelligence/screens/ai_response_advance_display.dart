import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIHealthResultScreen extends StatelessWidget {
  final String aiResponse;

  const AIHealthResultScreen({
    super.key,
    required this.aiResponse,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _splitSections(aiResponse);

    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Flock Analysis"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];

          return _AnalysisCard(
            title: section.title,
            body: section.body,
            icon: _getIcon(index),
            color: _getColor(index),
          );
        },
      ),
    );
  }

  List<AISection> _splitSections(String text) {
    final regex = RegExp(
      r'###\s*\d+\.\s*(.*?)(?=###\s*\d+\.|$)',
      dotAll: true,
    );

    final matches = regex.allMatches(text).toList();

    return matches.map((match) {
      final fullSection = match.group(0) ?? '';
      final title = match.group(1)?.trim() ?? '';

      final body = fullSection
          .replaceFirst(RegExp(r'###\s*\d+\.\s*.*'), '')
          .trim();

      return AISection(title: title, body: body);
    }).toList();
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.health_and_safety;
      case 1:
        return Icons.warning_amber_rounded;
      case 2:
        return Icons.medication;
      case 3:
        return Icons.home_repair_service;
      case 4:
        return Icons.monitor_heart;
      default:
        return Icons.analytics;
    }
  }

  Color _getColor(int index) {
    switch (index) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.red;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const _AnalysisCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(color: color, width: 5),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            MarkdownBody(
              data: body,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.black87,
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                listBullet: TextStyle(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AISection {
  final String title;
  final String body;

  AISection({
    required this.title,
    required this.body,
  });
}