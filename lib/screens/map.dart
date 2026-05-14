import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../data/trash_report.dart';
import '../providers/trash_provider.dart';
import '../utils/helpers.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _startTrackingLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startTrackingLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever)
      return;

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
            });
          }
        });
  }

  Future<void> _centerOnUser() async {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      showLocationErrorDialog(
        context,
        'Location Services Disabled',
        'Please turn on GPS.',
        actionLabel: 'Settings',
        onAction: () => Geolocator.openLocationSettings(),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        showLocationErrorDialog(
          context,
          'Permission Denied',
          'Please grant permission.',
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showLocationErrorDialog(
        context,
        'Permission Denied',
        'Enable permissions in App Settings.',
        actionLabel: 'Settings',
        onAction: () => Geolocator.openAppSettings(),
      );
      return;
    }

    _startTrackingLocation();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Acquiring location...')));
  }

  void _showReportDetails(BuildContext context, TrashReport report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reported in ${report.area}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text(
                          report.severity,
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: report.severity == 'High'
                            ? Colors.red
                            : (report.severity == 'Medium'
                                  ? Colors.orange
                                  : Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By: ${report.userName} • ${_timeAgo(report.timestamp)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),

                  if (report.imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(report.imagePath!),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                  const Text(
                    'Is this report still accurate?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.thumb_up_outlined,
                          color: Colors.green,
                        ),
                        onPressed: () {
                          context.read<TrashProvider>().upvoteReport(report.id);
                          setModalState(() {});
                        },
                      ),
                      Text('${report.upvotes}'),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(
                          Icons.thumb_down_outlined,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          context.read<TrashProvider>().downvoteReport(
                            report.id,
                          );
                          setModalState(() {});
                        },
                      ),
                      Text('${report.downvotes}'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _timeAgo(DateTime date) {
    Duration diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} years ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} months ago';
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<TrashProvider>().reports;
    final center = const LatLng(12.9716, 77.5946);

    List<Marker> allMarkers = reports.map((r) {
      Color markerColor = r.severity == 'High'
          ? Colors.red
          : (r.severity == 'Medium' ? Colors.orange : Colors.green);

      return Marker(
        point: LatLng(r.latitude, r.longitude),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => _showReportDetails(context, r),
          child: Icon(Icons.location_on, color: markerColor, size: 40),
        ),
      );
    }).toList();

    if (_userLocation != null) {
      allMarkers.add(
        Marker(
          point: _userLocation!,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(blurRadius: 4, color: Colors.black45),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          color: Colors.grey[200],
          child: const Center(
            child: Text(
              'Map is loading...\nPlease ensure your internet is enabled.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.trash_spotter',
            ),
            MarkerLayer(markers: allMarkers),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'location_btn',
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
