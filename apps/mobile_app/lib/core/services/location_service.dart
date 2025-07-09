import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static Future<LatLng?> pickGymLocation(BuildContext context) async {
    LatLng? selected;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MapPickerScreen(onSelected: (latlng) => selected = latlng),
    ));
    if (selected != null) {
      // Save selection in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('gym_lat', selected!.latitude);
      await prefs.setDouble('gym_lng', selected!.longitude);
    }
    return selected;
  }

  static Future<LatLng?> getSavedGymLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('gym_lat');
    final lng = prefs.getDouble('gym_lng');
    if (lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    return null;
  }
}

class _MapPickerScreen extends StatefulWidget {
  final Function(LatLng) onSelected;
  const _MapPickerScreen({required this.onSelected});

  @override
  State<_MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<_MapPickerScreen> {
  LatLng? picked;
  LatLng? _deviceLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _loading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _loading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _loading = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _deviceLocation = LatLng(position.latitude, position.longitude);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select your gym location')),
        body: const Center(
          child: Text("Map not supported in web. Use the mobile app."),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_deviceLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select your gym location')),
        body: const Center(
          child: Text("Could not get device location."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select your gym location')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _deviceLocation!,
          initialZoom: 15,
          onTap: (tapPosition, latlng) {
            setState(() => picked = latlng);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            tileProvider: NetworkTileProvider(),
            userAgentPackageName: 'com.example.mobile_app',
          ),
          TileLayer(
            urlTemplate: 'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
            tileProvider: NetworkTileProvider(),
            userAgentPackageName: 'com.example.mobile_app',
          ),
          if (picked != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: picked!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: picked != null
          ? FloatingActionButton.extended(
              label: const Text('Confirm'),
              icon: const Icon(Icons.check),
              onPressed: () {
                widget.onSelected(picked!);
                Navigator.of(context).pop();
              },
            )
          : null,
    );
  }
}
