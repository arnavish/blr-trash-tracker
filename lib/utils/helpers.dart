import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

// location popups
void showLocationErrorDialog(
  BuildContext context,
  String title,
  String content, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Dismiss'),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onAction();
            },
            child: Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    ),
  );
}

// Area Calculation

final Map<String, LatLng> blrAreas = {
  'Central (CBD)': const LatLng(12.9716, 77.5946),
  'Koramangala': const LatLng(12.9279, 77.6271),
  'Indiranagar': const LatLng(12.9784, 77.6408),
  'Jayanagar': const LatLng(12.9299, 77.5824),
  'Whitefield': const LatLng(12.9698, 77.7499),
  'Malleshwaram': const LatLng(13.0031, 77.5643),
  'Hebbal': const LatLng(13.0354, 77.5988),
  'Yelahanka': const LatLng(13.1007, 77.5963), 
  'Electronic City': const LatLng(12.8452, 77.6602), 
  'Attibele': const LatLng(12.7783, 77.7714), 
  'Kengeri': const LatLng(12.9177, 77.4838), 
  'KR Puram': const LatLng(13.0083, 77.6955),
};

String calculateNearestArea(double lat, double lng) {
  String closest = 'Unknown Area';
  double minDistance = double.infinity;

  blrAreas.forEach((areaName, coords) {
    double distance = Geolocator.distanceBetween(
      lat,
      lng,
      coords.latitude,
      coords.longitude,
    );
    if (distance < minDistance) {
      minDistance = distance;
      closest = areaName;
    }
  });
  return closest;
}
