import 'dart:math';
import 'package:flutter/material.dart';
import '../data/trash_report.dart';
import '../utils/helpers.dart';

class TrashProvider extends ChangeNotifier {
  final List<TrashReport> _reports = [];
  final List<String> _myReportIds = [];

  TrashProvider() {
    _generateDummyData();
  }

  List<TrashReport> get reports => _reports;
  List<TrashReport> get myReports =>
      _reports.where((r) => _myReportIds.contains(r.id)).toList();

  List<String> get availableAreas {
    final areas = _reports.map((r) => r.area).toSet().toList();
    areas.sort();
    return areas;
  }

  void addReport(TrashReport report) {
    _reports.add(report);
    _myReportIds.add(report.id);
    notifyListeners();
  }

  void deleteReport(String id) {
    _reports.removeWhere((r) => r.id == id);
    _myReportIds.remove(id);
    notifyListeners();
  }

  void upvoteReport(String id) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].upvotes++;
      notifyListeners();
    }
  }

  void downvoteReport(String id) {
    final index = _reports.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reports[index].downvotes++;
      notifyListeners();
    }
  }

  DateTime _getCutoff(String timeFilter) {
    DateTime now = DateTime.now();
    if (timeFilter == 'Past Week') return now.subtract(const Duration(days: 7));
    if (timeFilter == 'Past Month') {
      return now.subtract(const Duration(days: 30));
    }
    return now.subtract(const Duration(days: 365));
  }

  Map<String, int> getAreaStats(String timeFilter) {
    DateTime cutoff = _getCutoff(timeFilter);
    Map<String, int> areaCounts = {};
    for (var r in _reports) {
      if (r.timestamp.isAfter(cutoff)) {
        areaCounts[r.area] = (areaCounts[r.area] ?? 0) + 1;
      }
    }
    return areaCounts;
  }

  Map<String, int> getSeverityStatsForArea(String area, String timeFilter) {
    DateTime cutoff = _getCutoff(timeFilter);
    int low = 0, med = 0, high = 0;

    for (var r in _reports) {
      if (r.area == area && r.timestamp.isAfter(cutoff)) {
        if (r.severity == 'Low') low++;
        if (r.severity == 'Medium') med++;
        if (r.severity == 'High') high++;
      }
    }
    return {'Low': low, 'Medium': med, 'High': high};
  }

  // Dummy data generated to simulate more users (for the purpose of demonstration)
  void _generateDummyData() {
    final random = Random();
    final severities = ['Low', 'Medium', 'High'];
    final names = [
      'Rahul',
      'Priya',
      'Amit',
      'Sneha',
      'Vikram',
      'Arjun',
      'Kavya',
    ];

    for (int i = 0; i < 40; i++) {
      final lat = 12.75 + random.nextDouble() * 0.35;
      final lng = 77.45 + random.nextDouble() * 0.35;
      final accurateAreaName = calculateNearestArea(lat, lng);

      _reports.add(
        TrashReport(
          id: 'dummy_$i',
          latitude: lat,
          longitude: lng,
          severity: severities[random.nextInt(severities.length)],
          userName: names[random.nextInt(names.length)],
          timestamp: DateTime.now().subtract(
            Duration(days: random.nextInt(360)),
          ),
          area: accurateAreaName,
          upvotes: random.nextInt(15),
          downvotes: random.nextInt(5),
        ),
      );
    }
  }
}
