/// Utility functions for grade display formatting
class GradeDisplayUtils {
  /// Maps grade numbers to their display names for the UI
  static String getGradeDisplayName(int gradeNumber) {
    switch (gradeNumber) {
      case 1:
        return 'Evaluation';
      case 2:
        return 'Final';
      default:
        return 'Grade $gradeNumber';
    }
  }

  /// Maps grade number strings to their display names for the UI
  static String getGradeDisplayNameFromString(String gradeNumber) {
    switch (gradeNumber) {
      case '1':
        return 'Evaluation';
      case '2':
        return 'Final';
      default:
        return 'Grade $gradeNumber';
    }
  }
}