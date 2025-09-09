import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String? htmlContent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final content = await rootBundle.loadString('assets/privacy_policy.html');
      setState(() {
        htmlContent = content;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading privacy policy: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (htmlContent == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy Policy'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Privacy Policy could not be loaded.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: SelectableText(
          _htmlToPlainText(htmlContent!),
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  String _htmlToPlainText(String html) {
    // Convert HTML to plain text for display
    String text = html;
    
    // Remove HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Replace HTML entities
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&lt;', '<');
    text = text.replaceAll('&gt;', '>');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    
    // Clean up extra whitespace
    text = text.replaceAll(RegExp(r'\n\s*\n'), '\n\n');
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    
    return text.trim();
  }
}