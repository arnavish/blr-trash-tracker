class TrashReport {
  final String id;
  final double latitude;
  final double longitude;
  final String severity;
  final String? imagePath;
  final String userName;
  final DateTime timestamp;
  final String area;
  int upvotes;
  int downvotes;

  TrashReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.severity,
    this.imagePath,
    required this.userName,
    required this.timestamp,
    required this.area,
    this.upvotes = 0,
    this.downvotes = 0,
  });
}
