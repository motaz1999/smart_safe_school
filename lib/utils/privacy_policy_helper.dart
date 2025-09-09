import 'package:flutter/material.dart';

class PrivacyPolicyHelper {
  /// Navigate to the privacy policy screen
  /// This is a hidden route that can be accessed programmatically
  static void navigateToPrivacyPolicy(BuildContext context) {
    Navigator.pushNamed(context, '/privacy-policy');
  }

  /// Get the privacy policy route name
  static String get routeName => '/privacy-policy';

  /// Check if the privacy policy route exists
  static bool isPrivacyPolicyRoute(String routeName) {
    return routeName == '/privacy-policy';
  }

  /// For testing purposes - this method can be called to verify the route works
  /// You can remove this method in production
  static void testPrivacyPolicyAccess(BuildContext context) {
    print('🔍 Testing privacy policy access...');
    try {
      Navigator.pushNamed(context, '/privacy-policy');
      print('✅ Privacy policy route accessible');
    } catch (e) {
      print('❌ Privacy policy route failed: $e');
    }
  }
}