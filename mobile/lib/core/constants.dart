class AppConstants {
  static const String appName = 'PulseSync';
  
  // Base API configuration (Android emulator: 10.0.2.2, iOS / desktop: localhost)
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const String localhostBaseUrl = 'http://localhost:8000/api/v1';

  // Incident Priority Constants
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityCritical = 'critical';

  // Incident Categories
  static const String categoryFire = 'Fire';
  static const String categoryMedical = 'Medical';
  static const String categoryFlood = 'Flood';
  static const String categoryRoadAccident = 'Road Accident';
  static const String categoryGeneral = 'General';

  // Incident Status Constants
  static const String statusReported = 'reported';
  static const String statusDispatched = 'dispatched';
  static const String statusInProgress = 'in_progress';
  static const String statusResolved = 'resolved';
  static const String statusCancelled = 'cancelled';
}
