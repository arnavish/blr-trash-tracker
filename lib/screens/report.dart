import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../data/trash_report.dart';
import '../providers/trash_provider.dart';
import '../utils/helpers.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _severity = 'Low';
  File? _imageFile;
  Position? _currentPosition;
  bool _isLoadingLoc = false;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLoc = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoadingLoc = false);
      if (!mounted) return;
      showLocationErrorDialog(
        context,
        'Location Disabled',
        'Please turn on GPS.',
        actionLabel: 'Settings',
        onAction: () => Geolocator.openLocationSettings(),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoadingLoc = false);
        if (!mounted) return;
        showLocationErrorDialog(
          context,
          'Permission Denied',
          'Please grant permission.',
          actionLabel: 'Settings',
          onAction: () => Geolocator.openAppSettings(),
        );
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoadingLoc = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precise location acquired!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLoc = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to get location.')));
    }
  }

  void _submitReport() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name.')));
      return;
    }
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please get your location first.')),
      );
      return;
    }

    String nearestArea = calculateNearestArea(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    final newReport = TrashReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      severity: _severity,
      imagePath: _imageFile?.path,
      userName: _nameController.text.trim(),
      timestamp: DateTime.now(),
      area: nearestArea,
    );

    context.read<TrashProvider>().addReport(newReport);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report submitted in $nearestArea!')),
    );

    setState(() {
      _nameController.clear();
      _imageFile = null;
      _currentPosition = null;
      _severity = 'Low';
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(icon: Icon(Icons.add_location_alt), text: 'New Report'),
              Tab(icon: Icon(Icons.history), text: 'My Reports'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_buildSubmitFormTab(), _buildMyReportsTab()],
            ),
          ),
        ],
      ),
    );
  }

  // submission form
  Widget _buildSubmitFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1. Your Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              hintText: 'Enter your name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            '2. Take a Photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _imageFile != null
              ? Image.file(_imageFile!, height: 150, fit: BoxFit.cover)
              : Container(
                  height: 100,
                  color: Colors.grey[300],
                  child: const Center(child: Text('No image')),
                ),
          ElevatedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Open Camera'),
          ),
          const SizedBox(height: 24),

          const Text(
            '3. Tag Location',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          _isLoadingLoc
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.location_searching),
                  label: Text(
                    _currentPosition == null
                        ? 'Get GPS Location'
                        : 'Location Captured!',
                  ),
                ),
          const SizedBox(height: 24),

          const Text(
            '4. Severity Level',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: _severity,
            isExpanded: true,
            items: ['Low', 'Medium', 'High']
                .map(
                  (String value) =>
                      DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (val) => setState(() => _severity = val!),
          ),
          const SizedBox(height: 32),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.green,
            ),
            onPressed: _submitReport,
            child: const Text(
              'SUBMIT REPORT',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // my reports
  Widget _buildMyReportsTab() {
    final myReports = context.watch<TrashProvider>().myReports;

    if (myReports.isEmpty) {
      return const Center(
        child: Text(
          "You haven't submitted any reports yet.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: myReports.length,
      itemBuilder: (ctx, index) {
        final report = myReports[index];
        final formattedDate =
            "${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year} at ${report.timestamp.hour}:${report.timestamp.minute.toString().padLeft(2, '0')}";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              Icons.location_on,
              color: report.severity == 'High'
                  ? Colors.red
                  : (report.severity == 'Medium'
                        ? Colors.orange
                        : Colors.green),
              size: 32,
            ),
            title: Text(
              report.area,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Reported on: $formattedDate\nSeverity: ${report.severity}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                context.read<TrashProvider>().deleteReport(report.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Report deleted. Issue marked as resolved!'),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
